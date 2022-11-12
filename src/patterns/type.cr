module HM
  module Patterns
    # This pattern matches a type and recursively it's fields.
    class Type < Pattern
      getter patterns : ::Array(Pattern)
      getter name : String

      def initialize(@name, @patterns)
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          type.name == name &&
            type.fields.size == patterns.size &&
            type.fields.zip(patterns).all? do |field, subpattern|
              subpattern.matches?(field.item)
            end
        end
      end

      def format : String
        formatted =
          patterns
            .map(&.format)
            .join(", ")

        "#{name}(#{formatted})"
      end
    end
  end
end