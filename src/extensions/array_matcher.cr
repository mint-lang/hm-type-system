module HM
  class Spread < Pattern
    getter name : String

    def initialize(@name)
    end

    def matches?(type : Checkable) : Bool | Nil
      true
    end

    def format : String
      "...#{name}"
    end
  end

  class ArrayMatcher < Pattern
    getter patterns : Array(Pattern)

    def initialize(@patterns : Array(Pattern))
    end

    def matches?(type : Checkable) : Bool | Nil
      case type
      in Variable
        false
      in Type
        return false if patterns.size == 0
        return false if type.name != "Array"
        return false if type.fields.size != 1

        spreads =
          patterns.select { |item| item.is_a?(Spread) }

        return false if spreads.size > 1

        patterns.all? do |pattern|
          case pattern
          in Spread
            true
          in Pattern
            pattern.matches?(type.fields.first.item)
          end
        end
      end
    end

    def format : String
      formatted =
        patterns
          .map(&.format)
          .join(", ")

      "[#{formatted}]"
    end
  end
end
