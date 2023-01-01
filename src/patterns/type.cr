module HM
  module Patterns
    # This pattern matches a type and recursively it's fields.
    class Type < Pattern
      getter patterns : ::Array(Pattern)
      getter name : String

      def initialize(@name, @patterns = [] of Pattern, @type = nil)
      end

      def matches?(pattern : Pattern) : Bool | Nil
        case pattern
        when Type
          pattern.name == name &&
            pattern.patterns.size == patterns.size &&
            patterns.zip(pattern.patterns).all? do |pattern1, pattern2|
              pattern1.matches?(pattern2)
            end
        end.tap { |matched| @type = pattern.type if matched }
      end

      def matches?(type : Checkable) : Bool | Nil
        case type
        in HM::Variable
          false
        in HM::Type
          type.name == name &&
            type.fields.size == patterns.size &&
            type.fields.zip(patterns).all? do |field, subpattern|
              subpattern.matches?(field.item)
            end
        end
      end

      def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)
        mapping.tap { |memo| patterns.each(&.gather(memo)) }
      end

      def format : String
        if patterns.empty?
          name
        else
          formatted =
            patterns
              .map(&.format)
              .join(", ")

          "#{name}(#{formatted})"
        end
      end
    end
  end
end
