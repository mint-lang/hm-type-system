// This is a simple example implementation of the JavaScript version of the type
// system and pattern matching.

// A type is a special class with a name and indexable fields, variants are
// just types.
class Type {
  constructor(name, items) {
    this.name = name;

    for (index of items) {
      this[index] = items[index];
    }
  }
}

// We have a specific class for matching errors.
class MatchingError extends Error {
  constructor() {
    this.super()
  }
}

// This is the main recursive pattern matching function. It takes a pattern,
// a value and an optional memo which contains the matched values.
const match = (pattern, value, memo = []) => {
  switch (pattern.type) {
    case 'array':
      if (Array.isArray(value)) {
        // We need to check if there is a spread in the patterns if there is
        // it means we need to match it somewhere.
        spread =
          pattern.patterns.find((subPattern) => subPattern.type === "spread")

        if (spread && value.length >= (pattern.patterns.length - 1)) {
          // Keep arrays for the matchable single items.
          const head = []
          const tail = []

          // Gather all items and patterns before the spread.
          for (index in pattern.patterns) {
            if (pattern.patterns[index] === spread) {
              break
            } else {
              head.push([value[index], pattern.patterns[index]])
            }
          }

          // Gather all items and patterns after the spread.
          const reversedPatterns = Array.from(pattern.patterns).reverse();
          const reversed = Array.from(value).reverse();

          for (index in reversedPatterns) {
            const subPattern = reversedPatterns[index];

            if (subPattern === spread) {
              break
            } else {
              tail.unshift([reversed[index], reversedPatterns[index]])
            }
          }

          // Match the head patterns.
          head.forEach(([item, subPattern]) => {
            match(subPattern, item, memo)
          })

          // Add the spread.
          memo.push(value.slice(head.length, -tail.length))

          // Match the tail patterns.
          tail.forEach(([item, subPattern]) => {
            match(subPattern, item, memo)
          })

          // Otherwise try to match match the patterns with the items. This
          // works for empty arrays as well.
        } else if (value.length === pattern.patterns.length) {
          pattern.patterns.forEach((subPattern, index) => {
            match(subPattern, value[index], memo)
          })
        } else {
          throw MatchingError.new
        }
      } else {
        throw MatchingError.new
      }

      break;

    case 'type':
      // There are some types that are matched to native values.
      switch (pattern.name) {
        case 'Number':
          if (typeof value === "number") {
            memo.push(value)
          } else {
            throw MatchingError.new
          }

          break;

        case 'String':
          if (typeof value === "string") {
            memo.push(value)
          } else {
            throw MatchingError.new
          }

          break;

        default:
          if (value instanceof Type && value.name === pattern.name) {
            pattern.patterns.forEach((subPattern, index) => {
              switch (subPattern.type) {
              case 'field':
                match(subPattern.pattern, value[subPattern.name], memo)
              default:
                match(subPattern, value[index], memo)
              }
            })
          } else {
            throw MatchingError.new
          }
      }

      break;

    case 'tuple':
      // Tuples are like arrays but with fixed set of items.
      if (Array.isArray(value) && value.length == pattern.patterns.length) {
        value.forEach((item, index) => {
          match(pattern.patterns[index], item, memo)
        })
      } else {
        throw MatchingError.new
      }

      break;

    case 'variable':
      // We can't match variables to undefined or null.
      if (value !== undefined && value !== null) {
        memo.push(value)
      } else {
        throw MatchingError.new
      }

      break;

    case 'value':
      // This is the most basic pattern to match to an exact value.
      if (value !== pattern.value) {
        throw MatchingError.new
      }

      break;
  }

  return memo;
}
