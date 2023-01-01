module HM
  module Patterns
    # A pattern that matches arrays.
    class Array < Pattern
      getter patterns : ::Array(Pattern)
      getter spreads : ::Array(Spread)
      getter others : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern), @type = nil)
        @spreads = patterns.select(Spread)
        @others = patterns.reject(Spread)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Array
          pattern.patterns.size == patterns.size &&
            spreads.size == pattern.spreads.size &&
            patterns.zip(pattern.patterns).all? do |pattern1, pattern2|
              pattern1.matches?(pattern2)
            end
        end.tap { |matched| @type = pattern.type if matched }
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

          # If we have multiple spread patterns then we can't match since
          # we don't know how to distribute the items between spreads.
          return false if spreads.size > 1

          patterns.all? do |pattern|
            pattern.matches?(type.fields.first.item)
          end
        end
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping.tap { |memo| patterns.each(&.gather(memo)) }
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
