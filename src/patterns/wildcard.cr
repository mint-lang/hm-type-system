module HM
  module Patterns
    # This pattern matches everyting to be discarded.
    class Wildcard < Pattern
      def initialize(@type)
      end

      def format : String
        "_"
      end
    end
  end
end
