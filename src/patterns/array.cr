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
        when Variable
          true
        when Wildcard
          true
        when Array
          pattern.patterns.size == patterns.size &&
            spreads.size == pattern.spreads.size &&
            patterns.zip(pattern.patterns).all? do |pattern1, pattern2|
              pattern1.matches?(pattern2)
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

        "[#{formatted}]"
      end
    end
  end
end
