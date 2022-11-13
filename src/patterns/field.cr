module HM
  module Patterns
    # This pattern matches a types field to the pattern.
    class Field < Pattern
      getter pattern : Pattern
      getter name : String

      def initialize(@name, @pattern)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Field
          pattern.name == name && self.pattern.matches?(pattern)
        end
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          field =
            type.fields.find(&.name.==(name))

          field && pattern.matches?(field.item)
        end
      end

      def format : String
        "#{name}: #{pattern.format}"
      end
    end
  end
end
