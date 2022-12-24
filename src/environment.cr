module HM
  # This class is useful for checking a type environment for soundess
  # (all types are valid and complete and there are no missing types).
  class Environment
    getter definitions : Array(Definition)
    getter stack : Stack(Definition)

    def initialize(@definitions)
      # We have a stack to deal with recursion.
      @stack = Stack(Definition).new
    end

    # Delegated to HM::Unifier.matches? but with resolved types.
    def matches?(a : Checkable, b : Checkable) : Bool
      HM::Unifier.matches?(resolve(a), resolve(b))
    end

    # Delegated to HM::Unifier.matches? but with resolved types.
    def matches?(a : Checkable, b : Array(Checkable)) : Bool
      HM::Unifier.matches?(resolve(a), b.map { |item| resolve(item) })
    end

    # Delegated to HM::Unifier.unify but with resolved types.
    def unify(a : Checkable, b : Checkable) : Checkable | Nil
      HM::Unifier.unify(resolve(a), resolve(b))
    end

    # Resolves a type definition that matches the given fields.
    def resolve(fields : Array(Field)) : {Checkable, Definition}?
      definitions.compact_map do |item|
        definition_fields =
          case items = item.fields
          when Array(Field)
            items
          else
            [] of Field
          end

        definition_type =
          resolve(Type.new(item.name, definition_fields))

        record_type =
          resolve(Type.new("", fields))

        unified =
          HM::Unifier.unify(definition_type, record_type)

        {unified, item} if unified
      end.first?
    end

    # Resolves a type by trying to match it to definitions (recursively).
    #
    # In the case of record types, we need to expand the type definition into a
    # record type so the original type definition is basically a shorthand:
    #
    #   type Record(a, b) {
    #     value: b,
    #     key: a
    #   }
    #
    #   Record(String, String) => Record(key: String, value: String)
    #
    # In the case of a variant, we substitute the parameters of the type
    # definition:
    #
    #   type Result(error, value) {
    #     Error(error)
    #     Ok(value)
    #   }
    #
    #   Error(String) => Result(String, a)
    #   Ok(String) => Result(a, String)
    #
    def resolve(type : Type) : Checkable
      # Try to find the definition.
      definition =
        definitions.find(&.name.==(type.name))

      # Try to find the variant (there can be many).
      variant =
        definitions.compact_map do |definition|
          case items = definition.fields
          when Array(Variant)
            if item = items.find(&.name.==(type.name))
              {definition, item}
            end
          end
        end unless definition

      # If we found a definition and it's a record and the type is not a record
      # and they have parameter size matches the fields size.
      if definition &&
         definition.record? &&
         !type.record? &&
         definition.parameters.size == type.fields.size
        # Build up a mapping of parameters and it's types:
        #
        #   type Record(a, b) {
        #     value: b,
        #     key: a
        #   }
        #
        #   Record(String, String) => { a => String, b => String }
        #
        mapping =
          definition
            .parameters
            .zip(type.fields)
            .each_with_object({} of String => Checkable) do |(parameter, field), memo|
              memo[parameter.name] = resolve(field.item)
            end

        # Substitute the parameters in definitions fields with the actual
        # values if there is none then resolve the field.
        fields =
          case items = definition.fields
          when Array(Field)
            items.map_with_index do |field|
              resolved =
                mapping[field.item.name]? || resolve(field.item)

              Field.new(field.name, resolved)
            end
          end || [] of Field

        Type.new(definition.name, fields)
      elsif variant # If we found variant(s)
        variant.compact_map do |(definition, item)|
          # Resolve the variant type.
          variant_type =
            Type.new(item.name, item.items.map { |field| Field.new(field.name, resolve(field.item)) })

          # Unify the type and the variant type.
          if resolved = HM::Unifier.unify(type, variant_type)
            # Build up a mapping of parameters and it's types:
            #
            #   type Result(error, value) {
            #     Error(error)
            #     Ok(value)
            #   }
            #
            #   Ok(String) => { value => String }
            #
            mapping =
              item
                .items
                .zip(resolved.fields)
                .each_with_object({} of String => Checkable) do |(parameter, field), memo|
                  case parameter
                  when Field
                    case parameter.item
                    when Variable
                      memo[parameter.item.name] = resolve(field.item)
                    end
                  when Variable
                    memo[parameter.name] = resolve(field.item)
                  end
                end

            # Substitute the parameters in definitions parameters with the
            # actual types.
            fields =
              definition.parameters.map do |parameter|
                mapping[parameter.name]? || parameter
              end

            Type.new(definition.name, fields)
          end
        end.first?
      end || begin
        # Alternatively we can just resolve, the type recursively.
        fields =
          type.fields.map_with_index do |field|
            Field.new(field.name, resolve(field.item))
          end

        Type.new(type.name, fields)
      end
    end

    # Variables are resolve as themselves.
    def resolve(variable : Variable) : Checkable
      variable
    end

    # Checks if the evironment is sound (or complete):
    # - can't be multiple types with the same name
    # - can't be any undefined or unsound types
    def sound?
      definitions.map(&.name).uniq.size == definitions.size &&
        definitions.all? { |definition| sound?(definition) }
    end

    # Checks if the definition is sound (or complete):
    # - can't be any unused parameters
    # - can't be any non declared unsed parameters
    # - can't be any unsound fields
    #
    def sound?(definition : Definition)
      # We treat things in the stack as sound when checking recursively
      # becuase the original call will be the last returned.
      if stack.includes?(definition)
        true
      else
        stack.with(definition) do
          (definition.fields.empty? ||
            variables(definition) == definition.parameters.map(&.name).to_set) &&
            sound?(definition.fields)
        end
      end
    end

    # Checks if the type is sound (or complete):
    # - must have a definition
    # - must match the type definition
    # - can't be any unsound fields
    # - tuples are unique in the way that they don't need definitions
    def sound?(type : Type)
      case type.name
      when "Tuple"
        sound?(type.fields)
      else
        definition =
          definitions.find(&.name.==(type.name))

        return unless definition

        sound?(definition) &&
          sound?(type.fields) &&
          HM::Unifier.matches?(type, definition.type)
      end
    end

    def sound?(variants : Array(Variant))
      variants.all? { |variant| sound?(variant.items) }
    end

    def sound?(fields : Array(Field))
      fields.all? { |field| sound?(field.item) }
    end

    # We treat variables as sound, since they are the smallest unit.
    def sound?(variable : Variable)
      true
    end

    # The following methods gather all variables in an entity (type,
    # definition, etc...). It's used for checking soundness.

    def variables(type : Type, set = Set(String).new) : Set(String)
      variables(type.fields, set)
    end

    def variables(field : Field, set = Set(String).new) : Set(String)
      variables(field.item, set)
    end

    def variables(variable : Variable, set = Set(String).new) : Set(String)
      set.add(variable.name)
    end

    def variables(field : Variant, set = Set(String).new) : Set(String)
      variables(field.items, set)
    end

    def variables(fields : Array(Field), set = Set(String).new) : Set(String)
      set.tap { fields.each { |item| variables(item, set) } }
    end

    def variables(definition : Definition, set = Set(String).new) : Set(String)
      set.tap { definition.fields.each { |item| variables(item, set) } }
    end
  end
end
