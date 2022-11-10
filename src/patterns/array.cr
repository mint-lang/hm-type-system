module HM
  module Patterns
    class Array < Pattern
      getter patterns : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern))
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
            case pattern
            in Spread
              true
            in Pattern
              pattern.matches?(type.fields.first.item)
            end
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
