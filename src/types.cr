module HM
  extend self

  # A checkable value is a type or a variable.
  alias Checkable = Type | Variable

  # Represents a field of a type, basically a key, value pair.
  class Field
    getter name : String | Nil
    getter item : Checkable

    def initialize(@name, @item)
    end
  end

  # Represents a variant of a type.
  class Variant
    getter items : Array(Field)
    getter name : String

    def initialize(@name, @items)
    end
  end

  # Represents a type variable which is a hole in a type.
  class Variable
    getter name : String

    def initialize(@name)
    end
  end

  # Represents a type which has a name and can have many fields.
  class Type
    getter fields : Array(Field) = [] of Field
    getter name : String

    def initialize(@name, @fields)
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

      [Type.new(name, fields)] of Checkable
    end
  end
end
