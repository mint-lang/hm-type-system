module HM
  module Patterns
    # This pattern matches a types field to the pattern.
    class Field < Pattern
      getter pattern : Pattern
      getter name : String

      def initialize(@name, @pattern, @type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Field
          pattern.name == name && self.pattern.matches?(pattern)
        end
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          field =
            type.fields.find(&.name.==(name))

          field && pattern.matches?(field.item)
        end
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        pattern.gather(mapping)
      end

      def copy_type_from(pattern : Pattern)
        case pattern
        when Field
          @type = pattern.type
          self.pattern.copy_type_from(pattern)
        end
      end

      def format : String
        "#{name}: #{pattern.format}"
      end
    end
  end
end
