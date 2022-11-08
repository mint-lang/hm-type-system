module HM
  module Formatter
    extend self

    # Returns the formatted version of the type.
    def format(type : Checkable)
      format(type, { {} of Variable => String, "a" })[1]
    end

    # This method formats a type and replaces free variables with a incremental
    # characters (a, b, c, etc...).
    def format(type : Checkable, memo) : Tuple(Tuple(Hash(Variable, String), String), String)
      case type
      in Variable
        memo[0][type]?.try do |value|
          {memo, value}
        end || begin
          memo[0][type] =
            memo[1]

          { {memo[0], memo[1].succ}, memo[1] }
        end
      in Type
        if type.fields.empty?
          {memo, "#{type.name}"}
        else
          next_memo, fields =
            type.fields.reduce({memo, [] of String}) do |(item, values), field|
              next_memo, formatted =
                format(field.item, item)

              values << if field.name
                "#{field.name}: #{formatted}"
              else
                formatted
              end

              {next_memo, values}
            end

          {next_memo, "#{type.name}(#{fields.join(", ")})"}
        end
      end
    end
  end
end
