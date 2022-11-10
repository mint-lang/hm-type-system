module HM
  module Patterns
    # This pattern matches a type and it's field to the given patterns.
    class Field < Pattern
      getter patterns : ::Array(Pattern)
      getter name : String

      def initialize(@name, @patterns)
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          field =
            type.fields.find(&.name.==(name))

          field && patterns.all? do |pattern|
            pattern.matches?(field.item)
          end
        end
      end

      def format : String
        formatted =
          patterns
            .map(&.format)
            .join(", ")

        "#{name}: #{formatted}"
      end
    end
  end
end
