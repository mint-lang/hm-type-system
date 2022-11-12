module HM
  module Patterns
    # This is a spread pattern (...rest) matching multiple values, mostly used
    # with the array pattern.
    #
    # [a, ...rest]
    class Spread < Pattern
      getter name : String

      def initialize(@name)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        pattern.is_a?(Spread)
      end

      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def format : String
        "...#{name}"
      end
    end
  end
end
