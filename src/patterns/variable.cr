module HM
  module Patterns
    # This pattern matches anythig to a variable.
    class Variable < Pattern
      getter name : String

      def initialize(@name, @type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        @type = pattern.type
        true
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          true
        in HM::Type
          type.fields.any?(&.name.==(name))
        end
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping.tap { |memo| type.try { |item| memo[name] = item } }
      end

      def format : String
        name
      end
    end
  end
end
