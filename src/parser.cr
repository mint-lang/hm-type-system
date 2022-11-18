module HM
  # This parser was originally taken from the main mint-lang/mint repository.
  class Parser
    # The position of the cursor, which is at the character we are currently
    # parsing.
    getter position : Int32 = 0

    # The input which is an array of characters because this way it's faster in
    # cases where the original code contains multi-byte characters.
    getter input : Array(Char)

    # The original code in case we need something from it, not really used
    # by the parser.
    getter original : String

    # These methods parses an entity from the string, returns nil if it cannot
    # parse. The full string needs to be parsed for it to be successful.
    #
    #   HM.type("Test")  -> type
    #   HM.type("Test(") -> nil
    #   HM.variable("a") -> variable

    def self.definitions(input : String) : Array(Definition) | Nil
      Parser.new(input).parse { many { definition } }
    end

    def self.patterns(input : String) : Array(Pattern) | Nil
      Parser.new(input).parse { many { pattern } }
    end

    def self.definition(input : String) : Definition | Nil
      Parser.new(input).parse { definition }
    end

    def self.variable(input : String) : Variable | Nil
      Parser.new(input).parse { variable }
    end

    def self.pattern(input : String) : Pattern | Nil
      Parser.new(input).parse { pattern }
    end

    def self.type(input : String) : Checkable | Nil
      Parser.new(input).parse { type }
    end

    def initialize(@original : String)
      @input = @original.chars
    end

    # Moves the cursor forward.
    def step
      @position += 1
    end

    # Returns whether we are at the end of the string.
    def eos? : Bool
      @position == input.size
    end

    # Returns the current character.
    def char : Char
      input[position]? || '\0'
    end

    # If the given character is the current character, moves the cursor forward.
    def char!(expected : Char)
      step if char == expected
    end

    # Returns the next character.
    def next_char : Char
      input[position + 1]? || '\0'
    end

    # Returns the previous character.
    def previous_char : Char
      input[position - 1]? || '\0'
    end

    # Parses any number of ascii latters or numbers.
    def ascii_letters_or_numbers
      chars { |char| char.ascii_letter? || char.ascii_number? }
    end

    # Returns whether the current character is a whitespace.
    def whitespace?
      char.ascii_whitespace?
    end

    # Consumes all available whitespace.
    def whitespace : String?
      while whitespace?
        step
      end
    end

    # Consumes characters until the yielded value is true.
    def chars(& : Char -> Bool)
      while char != '\0' && (yield char)
        step
      end
    end

    # Consumes a keyword and returns it if successful.
    def keyword!(expected : String) : String | Nil
      start do |start_position|
        word =
          gather do
            chars do |char|
              !char.ascii_whitespace? &&
                @position < start_position + expected.size
            end
          end

        next unless word
        next unless word == expected

        word
      end
    end

    # Returns whether or not the word is at the current position.
    def keyword?(word : String) : Bool
      word.each_char_with_index.all? do |char, i|
        input[position + i]? == char
      end
    end

    # Starts to parse something, if the yielded value is nil then reset the
    # cursor where we started the parsing.
    def start
      start_position =
        position

      node =
        yield position

      @position =
        start_position unless node

      node
    end

    # Starts to parse something, if the cursor moved during return the parsed
    # string.
    def gather : String?
      start_position = position

      yield

      if position > start_position
        result =
          original[start_position, position - start_position]

        result unless result.empty?
      end
    end

    # Try to parse something and return it if was successfull and we are
    # at the end of the input.
    def parse
      result = with self yield
      result if eos?
    end

    # Parse many things separated by whitespace.
    def many(parse_whitespace : Bool = true, &block : -> T?) : Array(T) forall T
      result = [] of T

      loop do
        # Consume whitespace
        whitespace if parse_whitespace

        # Break if the block didn't yield anything
        break unless item = yield

        # Add item to results
        result << item
      end

      result
    end

    # Parses a list of things, which ends in the terminator character and are
    # separated by the separator character.
    def list(terminator : Char?, separator : Char, &block : -> T?) : Array(T) forall T
      result = [] of T

      loop do
        # Break if we reached the end
        break if char == terminator

        # Break if the block didn't yield anything
        break unless item = yield

        # Add item to results
        result << item

        # Consume whitespace before the separator
        whitespace

        # Break if there is no separator, consume it otherwise
        break unless char! separator

        # Consume whitespace
        whitespace
      end

      result
    end

    # Parses something which is surrounded by start char and end char.
    def surrounded(start_char : Char, end_char : Char)
      return unless char! start_char
      result = yield
      result if char! end_char
    end

    # Parses a list of things which are surrounded by start char and end char.
    def list(start_char : Char, end_char : Char, separator : Char, &block : -> T?) : Array(T) | Nil forall T
      start do
        surrounded(start_char, end_char) do
          list(separator: separator, terminator: end_char) { yield }
        end
      end
    end

    # Parses a type.
    def type : Checkable | Nil
      start do
        next unless name = identifier
        Type.new(name, fields || [] of Field).as(Checkable)
      end
    end

    # Parses a definition.
    def definition
      start do
        next unless keyword! "type"

        whitespace
        next unless name = identifier
        whitespace

        parameters =
          list(start_char: '(', end_char: ')', separator: ',') { variable }

        whitespace

        fields =
          surrounded(start_char: '{', end_char: '}') do
            variants =
              many { variant.as(Variant | Nil) }

            if variants.empty?
              list(separator: ',', terminator: '}') { field || type || variable }
                .map do |item|
                  case item
                  when Field
                    item
                  else
                    Field.new(name: nil, item: item)
                  end
                end
            else
              variants
            end
          end

        Definition.new(name, parameters || [] of Variable, fields || [] of Field)
      end
    end

    # Parses a variable.
    def variable : Variable | Nil
      start do
        value = gather do
          next unless char.ascii_lowercase?
          ascii_letters_or_numbers
        end

        next unless value

        Variable.new(value)
      end
    end

    # Parses a pattern.
    def pattern
      wildcard_pattern ||
        spread_pattern ||
        array_pattern ||
        tuple_pattern ||
        field_pattern ||
        variable_pattern ||
        type_pattern
    end

    # The methods are parsing specific patterns.

    def wildcard_pattern : Patterns::Wildcard | Nil
      start { Patterns::Wildcard.new if char! '_' }
    end

    def variable_pattern : Patterns::Variable | Nil
      variable = self.variable
      Patterns::Variable.new(variable.name) if variable
    end

    def spread_pattern : Patterns::Spread | Nil
      start do
        next unless keyword! "..."

        variable = self.variable
        Patterns::Spread.new(variable.name) if variable
      end
    end

    def array_pattern : Patterns::Array | Nil
      patterns =
        list(start_char: '[', end_char: ']', separator: ',') do
          pattern.as(Pattern | Nil)
        end

      Patterns::Array.new(patterns) if patterns
    end

    def tuple_pattern : Patterns::Tuple | Nil
      patterns =
        list(start_char: '{', end_char: '}', separator: ',') do
          pattern.as(Pattern | Nil)
        end

      Patterns::Tuple.new(patterns) if patterns
    end

    def field_pattern : Patterns::Field | Nil
      start do
        next unless variable = self.variable

        whitespace
        next unless char! ':'
        whitespace

        next unless pattern = self.pattern

        Patterns::Field.new(variable.name, pattern)
      end
    end

    def type_pattern : Patterns::Type | Nil
      start do
        next unless name = identifier

        patterns =
          list(start_char: '(', end_char: ')', separator: ',') do
            pattern.as(Pattern | Nil)
          end || [] of Pattern

        Patterns::Type.new(name, patterns)
      end
    end

    # The methods below are used by the main parses.

    def fields : Array(Field) | Nil
      list(start_char: '(', end_char: ')', separator: ',') do
        field || type || variable
      end.try(&.map do |item|
        case item
        when Field
          item
        else
          Field.new(name: nil, item: item)
        end
      end)
    end

    def variant : Variant | Nil
      start do
        next unless key = identifier
        whitespace

        Variant.new(key, fields || [] of Field)
      end
    end

    def field
      start do
        key = gather do
          next unless char.ascii_lowercase?
          ascii_letters_or_numbers
        end

        next unless key

        whitespace
        next unless char! ':'
        whitespace

        next unless node = type || variable

        Field.new(name: key, item: node)
      end
    end

    def identifier : String?
      start do
        name = gather do
          return unless char.ascii_uppercase?
          ascii_letters_or_numbers
        end

        next unless name

        start do
          if char == '.'
            other = start do
              step
              next_part = identifier
              next unless next_part
              next_part
            end

            next unless other

            name += ".#{other}"
          end
        end

        name
      end
    end
  end
end
