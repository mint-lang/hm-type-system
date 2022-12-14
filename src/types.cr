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
  end

  # Represents a type which has a name and can have many fields.
  class Type
    getter fields : Array(Field) = [] of Field
    getter name : String

    def initialize(@name, @fields)
    end

    # A type is a record if it only have named fields, in which case
    # we can assume any other type with only the same named fields
    # are the same.
    def record?
      fields.any? && fields.none?(&.name.nil?)
    end

    # A type is considered empty if it has no fields.
    def empty?
      fields.empty?
    end
  end

  # Represents a definition of a type.
  class Definition
    getter fields : Array(Variant) | Array(Field) = [] of Variant
    getter parameters : Array(Variable) = [] of Variable
    getter name : String

    def initialize(@name, @parameters, @fields)
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
