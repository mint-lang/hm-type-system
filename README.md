# hm-type-system

This repository contains a modified version of the Hindley-Milner type system which is used by the Mint programming language and can also be used by itself in an other programming language or in other use cases.

Most implementations of a Hindley-Milner type system is done in a functional programming language (Haskell mainly) and can be hard to understand. This implementation focuses on being readable, easily understandable and documented (in this readme and with comments) in an object oriented language.

This repository contains:

* [ ] [Formal grammar (PEG.js) for types, definitions and patterns](grammar/gammar.pegjs)
* [x] [Parser for the types, definitions, patterns](../src/parser.cr)
* [x] [Data structures for the types](../src/types.cr)
* [x] [Type unification algorithm](../src/unifier.cr)
* [x] [Branch enumeration algorithm](../src/branch_enumerator.cr)
* [x] [Pattern generator](../src/pattern_generator.cr)
* [x] [Pattern matching](../src/pattern_matcher.cr)
* [ ] [Web based playground](..src/playground.cr)
* [ ] JavaScript values for specific types
* [ ] JavaScript pattern matching function

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hm-type-system:
       github: mint-lang/hm-type-system
   ```

2. Run `shards install`

## Type System

This section explains the type system in detail.

### Types

#### Abstract Type

Abstract types don't have any definition body, no fields or variants, only the type definition itself.

These types are not used by runtime, only by the type system itself. They are to represent types that are not composite types or types that have a native analog (for example in JavaScript).

```
type Map(key, value)
type String
type Number
```

#### Composite Types

Composite types are ones that compose other types and don't have any type variables (we learn about them later on).

These types usually have key-value pairs (fields) which identifies the field and it's type.

```
type User {
  active : Bool
  name : String
  age : Number
}
```

#### Variant Types

Variant types are types which describe the data as choice between different options.

```
type Status {
  Loaded(String)
  Loading
  Idle
}
```

#### Type Variables

Type variables are holes in the type which can be filled with any other type, they make a type polymorphic.

```
type Result(error, value) {
  Error(error)
  Ok(value)
}
```

## Usage

To use the type system you can require it:

```crystal
require "hm-type-system"
```

All parts are available under the `HM` module.

### Parsers

To parse a type, variable, definition or pattern you can use the `HM::Parser` class:

```crystal
parser = HM::Parser.new(input)
parser.type       # parses a type
parser.variable   # parses a variable
parser.definition # parses a type definition
parser.pattern    # parses a pattern
```

If something cannot be parsed the method will return `nil`.

### Unification

The core part of the type system is type unification. It allows you to tell if two types are equal or not (can be unified or not). Basically there are holes (variables) in a type (`a` in `Type(a)`) which can be filled with other types.

The unification is a recursive algorithm which takes two types and matches types to these variables from one type to the other (in a mapping) and returns a unified type where the variables are substitued to the matching types.

Here is an example (`~` denotes unification):

```
Type(a) ~ Type(String) -> Type(String)
```

To unify two types you can just do this:

```crystal
# returns the unified type or nil if cannot be unified.
HM::Unifier.unify(type1, type2)
```

## Development

For developing all you need is Crystal and there is only one dependency [kemal](https://github.com/kemalcr/kemal) which is for the playground itself.

## Contributing

1. Fork it (<https://github.com/mint-lang/hm-type-system/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Gusztáv Szikszai](https://github.com/gdotdesign) - creator and maintainer
