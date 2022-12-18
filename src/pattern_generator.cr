module HM
  module PatternGenerator
    extend self

    include Composable

    # This method is used to build matching patterns for a type.
    #
    # There are two special types: Array and Tuple. Arrays generate three
    # patterns for each combination of it's type:
    #
    # - [item, ...rest] matches arrays with infinite number of items
    # - [item]          matches arrays with only one item (not really required)
    # - []              matches empty arrays
    #
    # Tuples are special because they have their own pattern.
    def generate(type : Checkable) : Array(Pattern)
      case type
      in Variable
        [Patterns::Variable.new(type.name)] of Pattern
      in Type
        case type.name
        when "Array"
          generate(type.fields.first.item).flat_map do |item|
            [
              Patterns::Array.new([item, Patterns::Spread.new("rest")]),
              Patterns::Array.new([item]),
            ] of Pattern
          end + [Patterns::Array.new([] of Pattern)] of Pattern
        when "Tuple"
          compose(type.fields.map { |field| generate(field.item) })
            .map { |items| Patterns::Tuple.new(items).as(Pattern) }
        else
          if type.empty?
            [
              Patterns::Type.new(type.name, [] of Pattern),
              Patterns::Wildcard.new,
            ] of Pattern
          else
            composed =
              compose(type.fields.map { |field| generate(field.item) })

            composed.map_with_index do |fields|
              mapped =
                fields.map_with_index do |field, index|
                  if name = type.fields[index].name
                    Patterns::Field.new(name, field)
                  else
                    field
                  end
                end

              Patterns::Type.new(type.name, mapped).as(Pattern)
            end
          end.uniq(&.format)
        end
      end
    end
  end
end
