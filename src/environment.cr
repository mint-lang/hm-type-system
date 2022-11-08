module HM
  # This class is useful for checking a type environment for soundess
  # (all types are valid and complete).
  class Environment
    class Stack(T) < Array(T)
      def with(item : T)
        push(item)
        result = yield
        pop
        result
      end
    end

    getter definitions : Array(Definition)

    def initialize(@definitions)
      # We have a stack to deal with recursion.
      @stack = Stack(Definition).new
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
      if @stack.includes?(definition)
        true
      else
        @stack.with(definition) do
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
    def sound?(type : Type)
      definition =
        definitions.find(&.name.==(type.name))

      return unless definition

      sound?(definition) &&
        sound?(type.fields) &&
        HM::Unifier.matches?(type, definition.type)
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
