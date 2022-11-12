module HM
  module Patterns
    # This pattern matches everything and points it to a variable.
    class Variable < Pattern
      getter name : String

      def initialize(@name)
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          true
        in HM::Type
          type.fields.any?(&.name.==(name))
        end
      end

      def format : String
        name
      end
    end
  end
end