require "./parser"

module HM
  extend self

  # Represents a field of a type, basically a key, value pair.
  alias Field = Tuple(String | Nil, Checkable)

  # A checkable value is a type or a variable.
  alias Checkable = Type | Variable

  # Represents a type variable which is a hole in a type.
  class Variable
    getter name : String

    def initialize(@name)
    end
  end

  # Represents a type which has a nema and can have many fields.
  class Type
    getter fields : Array(Field)
    getter name : String

    def initialize(@name, @fields = [] of Field)
    end
  end

  # This method parses a type or a variable from the string, returns nil if it
  # cannot parse. The full string needs to be parsed for it to be successful.
  #
  #   HM.parse("Test") -> true
  #   HM.parse("Test(") -> false
  #   HM.parse("Test(a)") -> true
  def parse(input : String) : Checkable | Nil
    parser =
      Parser.new(input)

    result =
      parser.type || parser.variable

    result if parser.eos?
  end

  # This method returns a normalized version of the type which means that
  # type variables with the same name points to the same instance of a
  # new variable (# denotes the id of the type for explanation purposes).
  #
  #   Type(a#1, a#2, a#3) -> Type(a#1, a#1, a#1)
  #
  # This is neccessary for the unification because these variables can point
  # to other types and we want all instances of a type variable (a) to point
  # to the same type.
  #
  # It returns a new type (and not modifies the current one) because an
  # instance of a type can potentially be used multiple times.
  #
  # Variables are not normalized because they are basically just pointers.
  #
  # We sort the fields because when unification happens as they need to be in a
  # definite order.
  def normalize(type : Checkable, mapping = {} of String => Variable)
    case type
    in Variable
      type
    in Type
      fields =
        type.fields.map do |(key, value)|
          normalized =
            case value
            in Variable
              mapping[value.name]? ||
                (mapping[value.name] = Variable.new(value.name))
            in Type
              normalize(value, mapping)
            end

          {key, normalized.as(Checkable)}
        end.sort do |(key1, value1), (key2, value2)|
          case {key1, key2}
          when {String, String}
            key1 <=> key2
          when {Nil, String}
            1
          when {String, Nil}
            -1
          when {Nil, Nil}
            0
          end
        end

      Type.new(type.name, fields)
    end
  end

  # We normalize the types so we can start from a clean slate, then unify and
  # substitue in the end.
  def unify(a : Checkable, b : Checkable) : Checkable | Nil
    mapping =
      {} of Variable => Checkable

    result =
      unify(normalize(a), normalize(b), mapping)

    substitue(result, mapping) if result
  end

  # This method tries to unify the given types by traversing it's parameters
  # and producing a mapping of variables to types (Variable => Checkable) which
  # later on we can use to substitue to one of the types and create a unified
  # type.
  #
  # It is important that this method assumes that both of the types were
  # normalized before, since normalization orders the fields.
  #
  # As an optimization we don't normalize the types here.
  private def unify(a : Checkable, b : Checkable, mapping : Hash(Variable, Checkable))
    case {a, b}
    in {Variable, Variable}
      # If there are two variables we need to check if they already have
      # assigned types if they do we need to test if they are equal, if not
      # we cannot unify.
      #
      # Otherwise we can just point them to each other (depending if they
      # have instances or not).
      instanceA = mapping[a]?
      instanceB = mapping[b]?

      if instanceA && instanceB
        nil unless instanceA == instanceB
      elsif instanceA
        mapping[b] = a
      else
        mapping[a] = b
      end
    in {Variable, Type}
      # If we have a variable and a type we need to check if the variable
      # already points to the same type, if not, we cannot unify.
      #
      # Otherwise we can just point the variable to the type.
      instance = mapping[a]?

      # This is important since the variables can point to each other.
      if instance && instance.is_a?(Type)
        nil unless instance == b
      else
        mapping[a] = b
      end
    in {Type, Variable}
      # In this branch we just call unify for the case above.
      unify(b, a, mapping)
    in {Type, Type}
      # If we have two types we need to check their name and their fields
      # for equality (with recursive unification calls).
      if a.name == b.name && a.fields.size == b.fields.size
        failed =
          a.fields.zip(b.fields).any? do |(key1, type1), (key2, type2)|
            key1 != key2 || begin
              # We create a submapping because the sub unification can fail
              # and if it doese it would taint the original mapping.
              sub_mapping =
                {} of Variable => Checkable

              sub_unification =
                unify(type1, type2, sub_mapping)

              next true if sub_unification.nil?

              mapping.merge!(sub_mapping)
              false
            end
          end

        a unless failed
      end
    end
  end

  # This method creates a new type by substituting the variables with the
  # types they are pointing to, thus resulting in the final unified type.
  private def substitue(type : Checkable, mapping = {} of Variable => Checkable) : Checkable
    case type
    in Variable
      mapping[type]?.try { |item| substitue(item, mapping) } || type
    in Type
      fields =
        type.fields.map do |(key, value)|
          {key, substitue(value, mapping)}
        end

      Type.new(type.name, fields)
    end
  end

  # Returns the formatted version of the type.
  def to_s(type : Checkable)
    format(type)[1]
  end

  # This method formats a type and replaces free variables with a incremental
  # characters (a, b, c, etc...).
  def format(type : Checkable, memo = { {} of Variable => String, "a" }) : Tuple(Tuple(Hash(Variable, String), String), String)
    case type
    in Variable
      memo[0][type]?.try do |value|
        {memo, value}
      end || begin
        memo[0][type] =
          memo[1]

        { {memo[0], memo[1].succ}, memo[1] }
      end
    in Type
      if type.fields.empty?
        {memo, "#{type.name}"}
      else
        next_memo, fields =
          type.fields.reduce({memo, [] of String}) do |(item, values), (key, type)|
            next_memo, formatted =
              format(type, item)

            values << if key
              "key: #{formatted}"
            else
              formatted
            end

            {next_memo, values}
          end

        {next_memo, "#{type.name}(#{fields.join(", ")})"}
      end
    end
  end
end
