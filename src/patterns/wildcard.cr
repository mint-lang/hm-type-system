module HM
  module Patterns
    # This pattern matches everyting to be discarded.
    class Wildcard < Pattern
      def initialize(@type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        @type = pattern.type
        true
      end

      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping
      end

      def format : String
        "_"
      end
    end
  end
end
