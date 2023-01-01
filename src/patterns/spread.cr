module HM
  module Patterns
    # This is a spread pattern (...rest) matching multiple values, mostly used
    # with the array pattern.
    #
    # [a, ...rest]
    class Spread < Pattern
      getter name : String

      def initialize(@name, @type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        pattern.is_a?(Spread)
      end

      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping.tap { |memo| type.try { |item| memo[name] = item } }
      end

      def copy_type_from(pattern : Pattern)
        if pattern.is_a?(Spread)
          @type = pattern.type
        end
      end

      def format : String
        "...#{name}"
      end
    end
  end
end
