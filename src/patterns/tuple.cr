module HM
  module Patterns
    # This pattern matches a tuple.
    class Tuple < Type
      def format
        formatted =
          patterns
            .map(&.format)
            .join(", ")

        "{#{formatted}}"
      end
    end
  end
end
