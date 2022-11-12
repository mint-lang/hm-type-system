### Type System

The type system described in this repository (and document) is a modified version of the Hindley-Milner type system for to be used in the Mint programming language.

The type system can describe many data structures, even recursive ones.

This repository contains:

* [ ] [Formal grammar (PEG.js)](../grammar/gammar.pegjs)
* [ ] [Parser for the types, definitions, patterns](../src/parser.cr)
* [x] [Data structures for the types](../src/types.cr)
* [x] [Type unification algorithm](../src/unifier.cr)
* [x] [Branch enumeration algorithm](../src/branch_enumerator.cr)
* [x] [Pattern matching algorithm](../src/pattern_matcher.cr)
* [ ] [Web based playground](..src/playground.cr)
* [ ] JavaScript values for specific types
* [ ] JavaScript pattern matching function

## Types

This section briefly shows the various types.

### Abstract Type

Abstract types don't have any definition body, no fields or variants, only the type definition itself.

These types are not used by runtime, only by the type system itself. They are to represent types that are not composite types or types that have a native analog (for example in JavaScript).

```
type Map(key, value)
type String
type Number
```

### Composite Types

Composite types are ones that compose other types and don't have any type variables (we learn about them later on).

These types usually have key-value pairs (fields) which identifies the field and it's type.

```
type User {
  active : Bool
  name : String
  age : Number
}
```

### Variant Types

Variant types are types which describe the data as choice between different options.

```
type Status {
  Loaded(String)
  Loading
  Idle
}
```

### Type Variables

Type variables are holes in the type which can be filled with any other type, they make a type polymorphic.

```
type Result(error, value) {
  Error(error)
  Ok(value)
}
```
