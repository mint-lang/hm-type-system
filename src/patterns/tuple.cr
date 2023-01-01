module HM
  module Patterns
    # This pattern matches a tuple.
    class Tuple < Pattern
      getter patterns : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern), @type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Tuple
          pattern.patterns.size == patterns.size &&
            patterns.zip(pattern.patterns).all? do |pattern1, pattern2|
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

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping.tap { |memo| patterns.each(&.gather(memo)) }
      end

      def copy_type_from(pattern : Pattern)
        case pattern
        when Array
          @type = pattern.type

          patterns.zip(pattern.patterns).each do |pattern1, pattern2|
            pattern1.copy_type_from(pattern2)
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
