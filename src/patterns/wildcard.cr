module HM
  module Patterns
    # This pattern matches anything but does not assign it to any variable.
    class Wildcard < Pattern
      def matches?(type : Checkable) : Bool | Nil
        true
      end

      def format : String
        "_"
      end
    end
  end
end
