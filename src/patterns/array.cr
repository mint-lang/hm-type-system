module HM
  module Patterns
    # A pattern that matches arrays.
    class Array < Pattern
      getter patterns : ::Array(Pattern)
      getter spreads : ::Array(Spread)
      getter others : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern), @type)
        @spreads = patterns.select(Spread)
        @others = patterns.reject(Spread)
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
