module HM
  # Defines the interface for a pattern which is used in pattern matching.
  abstract class Pattern
    # This methods allows patterns to match other patterns.
    abstract def matches?(pattern : Pattern) : Bool | Nil

    # This method should return true / false / nil depending the pattern
    # matches the given type.
    abstract def matches?(type : Checkable) : Bool | Nil

    # This method returns the formatted version of the pattern (not neccerily
    # the actual syntax), it's used in the playground.
    abstract def format : String

    # This method gethers all the Variable -> Type mappings recursively.
    abstract def gather(mapping : Hash(String, Checkable)) : Hash(String, Checkable)

    # All patterns must have a type (which gets filled during initialization
    # or during matching)
    property type : Checkable?
  end
end
