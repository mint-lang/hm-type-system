module HM
  abstract class Pattern
    abstract def matches?(type : Checkable) : Bool | Nil
    abstract def format : String
  end

  class WildcardPattern < Pattern
    def matches?(type : Checkable) : Bool | Nil
      true
    end

    def format : String
      "_"
    end
  end

  class VariablePattern < Pattern
    getter name : String

    def initialize(@name)
    end

    def matches?(type : Checkable) : Bool | Nil
      case type
      in Variable
        true
      in Type
        type.fields.any?(&.name.==(name))
      end
    end

    def format : String
      name
    end
  end

  class FieldPattern < Pattern
    getter patterns : Array(Pattern)
    getter name : String

    def initialize(@name, @patterns)
    end

    def matches?(type : Checkable) : Bool | Nil
      case type
      in Variable
        false
      in Type
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

  class TypePattern < Pattern
    getter patterns : Array(Pattern)
    getter name : String

    def initialize(@name, @patterns)
    end

    def matches?(type : Checkable) : Bool | Nil
      case type
      in Variable
        false
      in Type
        type.name == name &&
          type.fields.size == patterns.size &&
          type.fields.zip(patterns).all? do |field, subpattern|
            subpattern.matches?(field.item)
          end
      end
    end

    def format : String
      formatted =
        patterns
          .map(&.format)
          .join(", ")

      "#{name}(#{formatted})"
    end
  end

  class PatternMatcher
    getter environment : Environment

    def initialize(@environment)
    end

    def calculate(patterns, type)
      # return nil unless environment.sound?(type)

      branches =
        HM::BranchEnumerator
          .new(environment.definitions)
          .possibilities(type)

      covered = [] of Checkable
      matched = [] of Pattern

      branches.each do |branch|
        patterns.each do |pattern|
          next if covered.includes?(pattern)

          if pattern.matches?(branch)
            matched << pattern
            covered << branch
            break
          end
        end
      end

      {
        not_covered: branches - covered,
        not_matched: patterns - matched,
        matched:     matched,
        covered:     covered,
      }
    end
  end
end
