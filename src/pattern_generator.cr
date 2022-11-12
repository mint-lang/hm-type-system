module HM
  module PatternGenerator
    extend self

    include Composable

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
            [Patterns::Type.new(type.name, [] of Pattern)] of Pattern
          else
            composed =
              compose(type.fields.map { |field| generate(field.item) })

            composed.map_with_index do |fields|
              items =
                if type.record?
                  fields.map_with_index do |field, index|
                    name =
                      type.fields[index].name.not_nil!

                    Patterns::Field.new(name, field)
                  end
                else
                  fields
                end

              Patterns::Type.new(type.name, fields).as(Pattern)
            end
          end
        end
      end
    end
  end
end
