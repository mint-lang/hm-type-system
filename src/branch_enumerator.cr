module HM
  # This class helps with enumerating all possible combinations of a type or
  # definition which is useful during pattern matching since you need to
  # have possible branches for comparison.
  #
  # The resulting type list can be used to match against branches of the pattern
  # matching, using the unifier module.
  #
  # For example with the following environment:
  #
  #   type String
  #   type Number
  #
  #   type Maybe(a) {
  #     Nothing
  #     Just(a)
  #   }
  #
  #   type Status {
  #     Loaded(content: String, Number, name: Maybe(String))
  #     Loading
  #     Idle
  #   }
  #
  # For the Status type it will generate:
  #
  #  Loaded(content: String, Number, name: Nothing)
  #  Loaded(content: String, Number, name: Just(String))
  #  Loading
  #  Idle
  class BranchEnumerator
    include Composable

    getter stack : Stack(Definition) = Stack(Definition).new
    getter environment : Environment

    def initialize(@environment)
    end

    def possibilities(definition : Definition, type_fields = [] of Field) : Array(Checkable)
      # We keep a stack to detect and limit recursion to (50 levels).
      #
      # TODO: Find a way to have cyclic dependencies instead of a stack.
      if stack.includes?(definition) && stack.level > 50
        [] of Checkable
      else
        stack.with(definition) do
          # If the definition has no fields we can just return it's type since
          # we don't need to calculate any possibilities.
          if definition.fields.empty?
            [definition.type] of Checkable
          else
            case fields = definition.fields
            in Array(Variant)
              fields.flat_map do |variant|
                if variant.items.size == 0
                  Type.new(variant.name, [] of Field)
                else
                  possibilities(variant.name, variant.items)
                end
              end
            in Array(Field)
              possibilities(definition.name, fields)
            end
          end
        end.flat_map do |possibility|
          # After we have the possibilities we merge every possibility with
          # every possible combination of the paramteres.

          # If either possibility is empty (no fields) or the parameters then
          # it makes no sense to substitue so we can just short circut.
          if type_fields.empty? || possibility.empty?
            possibility
          else
            # We need to get the variables of the possibility to filter
            # the parameters for only those variables.
            variables =
              environment.variables(possibility)

            parameters =
              begin
                # We iterate the parameters first because we need the index
                # to filter out the not used variables by this possibility.
                items =
                  type_fields.map_with_index do |field, index|
                    if variables.includes?(definition.parameters[index].name)
                      possibilities(field.item).map do |item|
                        {definition.parameters[index].name, item}
                      end
                    end
                  end.compact

                compose(items)
              end

            substitute(possibility, parameters)
          end
        end
      end
    end

    def possibilities(type : Type) : Array(Checkable)
      if definition = environment.definitions.find(&.name.==(type.name))
        possibilities(definition, type.fields)
      else
        [type] of Checkable
      end
    end

    def possibilities(prefix : String, fields : Array(Field)) : Array(Checkable)
      parameters =
        compose(fields.map { |field| possibilities(field.item) })

      parameters.map do |item|
        named_fields =
          item.map do |field|
            # We need to keep the name of the field but since compose doesn't
            # keep it we need to get it with the index of the field.
            name =
              fields[item.index(field) || -1]?.try(&.name)

            Field.new(name, field)
          end

        Type.new(prefix, named_fields).as(Checkable)
      end
    end

    def possibilities(variable : Variable) : Array(Checkable)
      [variable] of Checkable
    end

    # Substitues the all combination of parameters in the slots (variables) of
    # the type, or returns the list of possible parameters of a variable.
    #
    #   a, [[{"a", "Type1"}], [{"a", "Type2"}]]
    #     ["Type1", "Type2"]
    #
    #   Type(a), [[{"a", "Type1"}], [{"a", "Type2"}]]
    #     ["Type(Type1)", "Type(Type2)"]
    def substitute(type, parameters = [] of Array({String, Checkable})) : Array(Checkable)
      parameters.flat_map do |items|
        case type
        in Type
          compose(type.fields.map { |field| substitute(field.item, [items]) })
            .map { |fields| fields.map { |item| Field.new(nil, item) } }
            .map { |fields| Type.new(type.name, fields) }
        in Variable
          items.find { |x| x[0] == type.name }.try(&.last) || [] of Checkable
        end
      end
    end
  end
end
