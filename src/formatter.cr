module HM
  class Formatter
    # This hash is to store the new name of variable.
    getter mapping : Hash(Variable, String) = {} of Variable => String

    # This keeps track of the current variable name.
    getter variable : String = 'a'.pred.to_s

    def self.format(type : Checkable)
      new.format(type)
    end

    # Returns the string representation of the type or variable in the format
    # the parser can parse.
    # - The type should be normalized before formatting.
    # - Variables are replaced with a sequential names (a, b, c)
    def format(type : Checkable) : String
      case type
      in Variable
        mapping[type]? || (mapping[type] = @variable = @variable.succ)
      in Type
        if type.fields.empty?
          type.name
        else
          fields =
            type.fields.map do |field|
              formatted =
                format(field.item)

              if field.name
                "#{field.name}: #{formatted}"
              else
                formatted
              end
            end

          "#{type.name}(#{fields.join(", ")})"
        end
      end
    end
  end
end
