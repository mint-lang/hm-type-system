module HM
  module Composable
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
