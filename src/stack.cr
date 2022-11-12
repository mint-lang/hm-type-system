module HM
  # A helper class to keep track of the stack.
  class Stack(T) < Array(T)
    getter level : Int32 = 0

    def with(item : T)
      @level += 1
      push(item)
      result = yield
      pop
      @level -= 1
      result
    end
  end
end
