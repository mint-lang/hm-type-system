module HM
  # This class helps with enumerating all possible variations of a type
  # definition which is useful during pattern matching since you need to
  # have possible branches for comparison.
  #
  # Some important information:
  # - an instance of branch enumerator should be only used once
  # - it needs all definitions for the types to be useful
  # - it doesn't check the defintions for soundness or even their exsistence
  #
  # The resulting type list can be used to match against branches of the pattern
  # matching, using the unifier module.
  class BranchEnumerator
    getter definitions : Array(Definition)

    def initialize(@definitions)
      @variable = 'a'.pred.to_s
    end

    def possibilities(definition : Definition, parameters = [] of Array(Checkable)) : Array(Checkable)
      case fields = definition.fields
      in Array(Variant)
        possibilities(fields, parameters)
      in Array(Field)
        possibilities(definition.name, fields)
      end
    end

    def possibilities(type : Type) : Array(Checkable)
      # Generate every possible combination of parameters of the fields, which
      # we will use to backfill the other possibilities.
      parameters =
        compose(type.fields.map { |field| possibilities(field.item) })

      # We try to look up the definition of the type by name. If the definition
      # doesn't have any fields we can just return a type with it's name.
      #
      # If a definition doesn't have any fields it means that it's an abstract
      # type which we can just fill with the parameters.
      if definition = definitions.find(&.name.==(type.name))
        if definition.fields.empty?
          fill(definition.type, parameters)
        else
          possibilities(definition, compose(parameters))
        end
      else
        fill(type, parameters)
      end
    end

    # If a variant doesn't have any parameters we can just return a
    # type with it's name, otherwise we generate all possibilities of
    # variants and fill any variables with their actual types.
    def possibilities(variants : Array(Variant), parameters = [] of Array(Checkable)) : Array(Checkable)
      variants.flat_map do |variant|
        if variant.items.size == 0
          Type.new(variant.name, [] of Field)
        else
          possibilities(variant.name, variant.items).flat_map do |possibility|
            fill(possibility, parameters)
          end
        end
      end
    end

    def possibilities(prefix : String, fields : Array(Field)) : Array(Checkable)
      parameters =
        fields.map { |field| possibilities(field.item) }

      compose(parameters).map do |item|
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

    # Variables are replaced with an incrementing variable name.
    def possibilities(variable : Variable) : Array(Checkable)
      @variable =
        @variable.succ

      [Variable.new(@variable)] of Checkable
    end

    # Generates possibilities of the type by filling variables with their
    # possible variations.
    def fill(type : Checkable, replacements = [] of Array(Checkable)) : Array(Checkable)
      case type
      in Type
        if replacements.empty?
          [type.as(Checkable)]
        else
          replacements.map do |parameters|
            fields =
              type.fields.zip(parameters).map do |(field, parameter)|
                if field.variable?
                  Field.new(field.name, parameter)
                else
                  field
                end
              end

            Type.new(type.name, fields).as(Checkable)
          end
        end
      in Variable
        [type.as(Checkable)]
      end
    end

    # This method composes the parts possibitilites into a flat list which
    # covers all posibilities.
    #
    #   compose([["a"], ["b"], ["c"]])
    #     ["a", "b", "c"]
    #
    #   compose([["a"], ["b", "c"], ["d"]])
    #     [
    #       ["a", "b", "d"],
    #       ["a", "c", "d"]
    #     ]
    #
    # Takes a value from first the first column and adds to it all the possibile
    # combination of values from the rest of the columns, recursively.
    private def compose(items : Array(Array(T))) : Array(Array(T)) forall T
      case items.size
      when 0
        [] of Array(T)
      when 1
        items[0].map { |item| [item] }
      else
        result =
          [] of Array(T)

        rest =
          compose(items[1...])

        items[0].each do |item|
          rest.each do |sub|
            result << [item] + sub
          end
        end

        result
      end
    end
  end
end
