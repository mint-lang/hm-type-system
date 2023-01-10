module HM
  module Patterns
    # This pattern matches a types field to the pattern.
    class Field < Pattern
      getter pattern : Pattern
      getter name : String

      def initialize(@name, @pattern, @type)
      end

      def format : String
        "#{name}: #{pattern.format}"
      end
    end
  end
end
