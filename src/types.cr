module HM
  extend self

  # A checkable value is a type or a variable.
  alias Checkable = Type | Variable

  # Represents a type variable which is a hole in a type.
  class Variable
    EMPTY_FIELDS = [] of Field

    getter name : String

    def initialize(@name)
    end

    # This is so we don't have to check between a type and a type variable,
    # like this:
    #
    #   case type
    #   in Type
    #     type.fields.first.item
    #   in Variable
    #     nil
    #   end
    #
    def fields
      EMPTY_FIELDS
    end

    # This method is needed so we can call empty? on Checkable objects.
    # A variable is considered empty.
    def empty?
      true
    end

    # Returns whether this type includes (equals) the other type or variable.
    def includes?(other : Checkable)
      self == other
    end
  end

  # Represents a type which has a name and can have many fields.
  class Type
    getter fields : Array(Field) = [] of Field
    getter name : String

    def self.parse!(source : String) : Type
      Parser.type(source).not_nil!.as(Type)
    end

    def initialize(@name, fields : Array(Checkable))
      @fields = fields.map { |item| Field.new(nil, item) }
    end

    def initialize(@name, @fields = [] of Field)
    end

    def initialize(@name, fields = [] of Field | Checkable | String)
      @fields =
        fields.map do |item|
          case item
          in Field
            item
          in Checkable
            Field.new(nil, item)
          in String
            Field.new(nil,
              if item.starts_with?(/[A-Z]/)
                Type.new(item)
              else
                Variable.new(item)
              end)
          end
        end
    end

    # A type is a record if it only have named fields, in which case
    # we can assume any other type with only the same named fields
    # are the same.
    def record?
      fields.size > 0 && fields.none?(&.name.nil?)
    end

    # A type is considered empty if it has no fields.
    def empty?
      fields.empty?
    end

    # Returns whether this type includes the other type or variable.
    def includes?(other : Checkable)
      self == other || fields.any? { |field| field.item.includes?(other) }
    end
  end

  # Represents a definition of a type.
  class Definition
    getter fields : Array(Variant) | Array(Field) = [] of Variant
    getter parameters : Array(Variable) = [] of Variable
    getter name : String

    def initialize(@name, @parameters, @fields)
    end

    # A definition is a record if it has fields instead of variants.
    def record?
      fields.size > 0 && fields.is_a?(Array(Field))
    end

    # Returns the type representation of the definition.
    def type
      fields =
        parameters.map { |parameter| Field.new(nil, parameter) }

      Type.new(name, fields)
    end
  end

  # Represents a field of a type, basically a key, value pair.
  class Field
    getter name : String | Nil
    getter item : Checkable

    def initialize(@name, @item)
    end

    def variable?
      item.is_a?(Variable)
    end
  end

  # Represents a variant of a type.
  class Variant
    getter items : Array(Field)
    getter name : String

    def initialize(@name, @items)
    end
  end
end
