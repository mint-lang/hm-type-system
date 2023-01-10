module HM
  module Patterns
    # This pattern matches a type and recursively it's fields.
    class Type < Pattern
      getter patterns : ::Array(Pattern)
      getter name : String

      def initialize(@name, @patterns, @type)
      end

      def format : String
        if patterns.empty?
          name
        else
          formatted =
            patterns
              .map(&.format)
              .join(", ")

          "#{name}(#{formatted})"
        end
      end
    end
  end
end
