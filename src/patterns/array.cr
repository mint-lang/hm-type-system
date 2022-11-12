module HM
  module Patterns
    # A pattern that matches arrays.
    class Array < Pattern
      getter patterns : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern))
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Array
          # TODO: Match empties singleones and spreads..
          pattern.patterns.size == patterns.size &&
            pattern.patterns.zip(patterns) do |pattern1, pattern2|
              pattern1.matches?(pattern2)
            end
        end
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          # We need only care about Array types with one arity.
          return false if type.name != "Array" &&
                          type.fields.size != 1

          # We return true since it matches an empty array, which is
          # technically correct but not exhaustive (obviously).
          return true if patterns.size == 0

          spreads =
            patterns.select { |item| item.is_a?(Spread) }

          # If we have multiple spread patterns then we can't match since
          # we don't know how to distribute the items between spreads.
          return false if spreads.size > 1

          patterns.all? do |pattern|
            pattern.matches?(type.fields.first.item)
          end
        end
      end

      def format : String
        formatted =
          patterns
            .map(&.format)
            .join(", ")

        "[#{formatted}]"
      end
    end
  end
end
