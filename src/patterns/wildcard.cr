module HM
  module Patterns
    # This pattern matches everyting to be discarded.
    class Wildcard < Pattern
      def matches?(pattern : Pattern) : Bool | Nil
        true
      end

      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def format : String
        "_"
      end
    end
  end
end
