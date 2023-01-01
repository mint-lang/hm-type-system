module HM
  module Unifier
    extend self

    # Returns whether a matches (can be unified with) b.
    def matches?(a : Checkable, b : Checkable) : Bool
      !unify(normalize(a), normalize(b), {} of Variable => Checkable).nil?
    end

    # Returns whether a matches (can be unified with) any in b.
    def matches?(a : Checkable, b : Array(Checkable)) : Bool
      b.any? { |item| unify(normalize(a), normalize(item), {} of Variable => Checkable) }
    end

    # We normalize the types so we can start from a clean slate, then unify and
    # substitue in the end.
    def unify(a : Checkable, b : Checkable) : Checkable | Nil
      mapping =
        {} of Variable => Checkable

      result =
        unify(normalize(a), normalize(b), mapping)

      substitue(result, mapping) if result
    end

    # This method tries to unify the given types by traversing it's parameters
    # and producing a mapping of variables to types (Variable => Checkable) which
    # later on we can use to substitue to one of the types and create a unified
    # type.
    #
    # It is important that this method assumes that both of the types were
    # normalized before, since normalization orders the fields, so as an
    # optimization we don't normalize the types here.
    private def unify(a : Checkable, b : Checkable, mapping : Hash(Variable, Checkable))
      case {a, b}
      in {Variable, Variable}
        # If there are two variables we need to check if they already have
        # assigned types, if they do we need to test if they are equal, if not
        # we cannot unify, otherwise we can just point them to each other
        # (depending if they have instances or not).
        instanceA = mapping[a]?
        instanceB = mapping[b]?

        if instanceA && instanceB
          unify(instanceA, instanceB)
        elsif instanceA
          mapping[b] = a
        else
          mapping[a] = b
        end
      in {Variable, Type}
        # If we have a variable and a type we need to check if the variable
        # already points to the same type, if not, we cannot unify, otherwise
        # we can just point the variable to the type.
        instance = mapping[a]?

        # This check is important since the variables can point to each other.
        if instance && instance.is_a?(Type)
          unify(instance, b)
        else
          mapping[a] = b
        end
      in {Type, Variable}
        # In this branch we just call unify for the case above.
        unify(b, a, mapping)
      in {Type, Type}
        # If we have two types we need to check their name and their fields
        # for equality (with recursive unification calls).
        #
        # If they are both records (only have named fields) we can assume that
        # they represent the same data.
        both_records =
          a.record? && b.record?

        same_type =
          both_records || a.name == b.name

        if same_type && a.fields.size == b.fields.size
          failed =
            a.fields.zip(b.fields).any? do |item1, item2|
              # Return if both have names and they are different.
              next true if item1.name && item2.name && item1.name != item2.name

              # We duplicate the mapping as a submapping because the sub
              # unification can fail and if it doese it would taint the
              # original mapping.
              sub_mapping =
                mapping.dup

              sub_unification =
                unify(item1.item, item2.item, sub_mapping)

              next true if sub_unification.nil?

              mapping.merge!(sub_mapping)
              false
            end

          a unless failed
        end
      end
    end

    # This method returns a normalized version of the type which means that
    # type variables with the same name, points to the same instance of a
    # new variable (# denotes the id of the type for explanation purposes).
    #
    #   Type(a#1, a#2, a#3) -> Type(a#1, a#1, a#1)
    #
    # This is neccessary for the unification because these variables can point
    # to other types and we want all instances of a type variable (a) to point
    # to the same type.
    #
    # It returns a new type (and not modifies the current one) because an
    # instance of a type can potentially be used multiple times.
    #
    # Variables are not normalized because they are basically just pointers.
    #
    # We sort the fields because when unification happens as they need to be in a
    # definite order, but only if all fields have a name.
    def normalize(type : Checkable, mapping = {} of String => Variable)
      case type
      in Variable
        type
      in Type
        # Optimization so we don't create so many types.
        if type.fields.size == 0
          type
        else
          fields =
            type.fields.map do |field|
              normalized =
                case value = field.item
                in Variable
                  mapping[value.name]? ||
                    (mapping[value.name] = Variable.new(value.name))
                in Type
                  normalize(value, mapping)
                end

              Field.new(field.name, normalized)
            end

          fields.sort! do |item1, item2|
            case {key1 = item1.name, key2 = item2.name}
            when {String, String}
              key1 <=> key2
            when {Nil, String}
              1
            when {String, Nil}
              -1
            when {Nil, Nil}
              0
            end
          end if fields.all?(&.name)

          Type.new(type.name, fields)
        end
      end
    end

    # This method creates a new type by substituting the variables with the
    # types they are pointing to, thus resulting in the final unified type.
    private def substitue(type : Checkable, mapping = {} of Variable => Checkable) : Checkable
      case type
      in Variable
        mapping[type]?.try { |item| substitue(item, mapping) } || type
      in Type
        fields =
          type.fields.map do |item|
            Field.new(item.name, substitue(item.item, mapping))
          end

        Type.new(type.name, fields)
      end
    end
  end
end
