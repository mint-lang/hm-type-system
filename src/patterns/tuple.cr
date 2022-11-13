module HM
  module Patterns
    # This pattern matches a tuple.
    class Tuple < Pattern
      getter patterns : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern))
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Tuple
          pattern.patterns.size == patterns.size &&
            pattern.patterns.zip(patterns).all? do |pattern1, pattern2|
              pattern1.matches?(pattern2)
            end
        end
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          type.name == "Tuple" &&
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

        "{#{formatted}}"
      end
    end
  end
end
