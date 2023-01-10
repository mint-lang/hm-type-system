module HM
  module Patterns
    # This pattern matches a tuple.
    class Tuple < Pattern
      getter patterns : ::Array(Pattern)

      def initialize(@patterns : ::Array(Pattern), @type)
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
