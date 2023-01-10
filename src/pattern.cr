module HM
  # Defines the interface for a pattern which is used in pattern matching.
  abstract class Pattern
    # This method returns the formatted version of the pattern (not neccerily
    # the actual syntax), it's used in the playground.
    abstract def format : String

    # All patterns must have a type (which gets filled during initialization
    # or during matching)
    property type : Checkable

    def initialize(@type)
    end
  end
end
