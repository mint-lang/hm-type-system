module HM
  module Patterns
    # This is a spread pattern (...rest) matching multiple values, mostly used
    # with the array pattern.
    #
    # [a, ...rest]
    class Spread < Pattern
      getter name : String

      def initialize(@name, @type)
      end

      def format : String
        "...#{name}"
      end
    end
  end
end
