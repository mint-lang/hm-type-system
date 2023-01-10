module HM
  module Patterns
    # This pattern matches anythig to a variable.
    class Variable < Pattern
      getter name : String

      def initialize(@name, @type)
      end

      def format : String
        name
      end
    end
  end
end
