module HM
  # This parser was originally migrated from the main mint-lang/mint repository.
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

    # Starts to parse something, if the yielded value is nil then reset the
    # cursor where we started the parsing.
    def start
      start_position = position

      node = yield position
      @position = start_position unless node
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

    # Parses a type.
    def type : Checkable | Nil
      start do
        next unless name = type_identifier

        fields =
          if char! '('
            items =
              list(separator: ',', terminator: ')') { type_field || type || variable }
                .map do |item|
                  case item
                  when Field
                    item
                  else
                    {nil.as(String | Nil), item}
                  end
                end

            if char! ')'
              items
            else
              next
            end
          else
            [] of Field
          end

        Type.new(name, fields).as(Checkable)
      end
    end

    # Parses a type field.
    def type_field
      start do
        key =
          value = gather do
            next unless char.ascii_lowercase?
            ascii_letters_or_numbers
          end

        next unless value

        whitespace
        next unless char! ':'
        whitespace

        next unless node = type || variable

        {key, node}
      end
    end

    # Parses a variable.
    def variable : Checkable | Nil
      start do
        value = gather do
          next unless char.ascii_lowercase?
          ascii_letters_or_numbers
        end

        next unless value

        Variable.new(value).as(Checkable)
      end
    end

    # Parses a type identifier.
    def type_identifier : String?
      name = gather do
        return unless char.ascii_uppercase?
        ascii_letters_or_numbers
      end

      return unless name

      start do
        if char == '.'
          other = start do
            step
            next_part = type_identifier
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
