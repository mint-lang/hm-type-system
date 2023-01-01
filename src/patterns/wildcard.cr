module HM
  module Patterns
    # This pattern matches everyting to be discarded.
    class Wildcard < Pattern
      def initialize(@type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        true
      end

      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping
      end

      def copy_type_from(pattern : Pattern)
        @type = pattern.type
      end

      def format : String
        "_"
      end
    end
  end
end
