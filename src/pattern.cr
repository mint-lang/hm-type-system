module HM
  # Defines the interface for a pattern which is used in pattern matching.
  abstract class Pattern
    # This method should return true / false / nil depending the pattern
    # matches the given type.
    abstract def matches?(type : Checkable) : Bool | Nil

    # This method returns the formatted version of the pattern (not neccerily
    # the actual syntax), it's used in the playground.
    abstract def format : String
  end
end
