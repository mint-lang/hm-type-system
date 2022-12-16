require "./spec_helper"

macro expect_not_unify(a, b)
  it "{{a.id}} vs {{b.id}}" do
    type1 = HM::Parser.type({{a}}) || HM::Parser.variable({{a}})
    type2 = HM::Parser.type({{b}}) || HM::Parser.variable({{b}})

    if type1 && type2
      result = HM::Unifier.unify(type1, type2)

      if result
        fail "Expected \"{{a.id}}\" and \"{{b.id}}\" not to be unifiable but they are."
      end
    else
      fail "Could not parse {{a.id}} or {{b.id}}."
    end
  end
end

macro expect_unify(a, b, expected)
  it "{{a.id}} vs {{b.id}}" do
    type1 = HM::Parser.type({{a}}) || HM::Parser.variable({{a}})
    type2 = HM::Parser.type({{b}}) || HM::Parser.variable({{b}})

    if type1 && type2
      result = HM::Unifier.unify(type1, type2)

      unless result
        fail "Expected \"{{a.id}}\" and \"{{b.id}}\" to be unifiable but they are not."
      end

      HM::Formatter.format(result).should eq({{expected}})
    else
      fail "Could not parse {{a.id}} or {{b.id}}."
    end
  end
end

macro expect_define_type(source)
  it "Defines type: {{source.id}}" do
    definitions =
      HM::Parser.definitions({{source}})

    fail "Could not parse {{source.id}}" unless definitions

    environment =
      HM::Environment.new(definitions)

    fail "Environment not sound!" unless environment.sound?
  end
end

macro expect_branches(expected, source)
  it "Expands type: {{source.id}}" do
    definitions =
      HM::Parser.definitions({{source}})

    fail "Could not parse {{source.id}}" unless definitions

    environment =
      HM::Environment.new(definitions)

    fail "Environment not sound!" unless environment.sound?

    enumerator =
      HM::BranchEnumerator.new(environment)

    enumerator
      .possibilities(definitions.last)
      .map { |branch| HM::Formatter.format(branch) }
      .should eq({{expected}})
  end
end

macro expect_patterns(expected, source)
  it "Expands type: {{source.id}}" do
    definitions =
      HM::Parser.definitions({{source}})

    fail "Could not parse {{source.id}}" unless definitions

    environment =
      HM::Environment.new(definitions)

    fail "Environment not sound!" unless environment.sound?

    enumerator =
      HM::BranchEnumerator.new(environment)

    enumerator
      .possibilities(definitions.last)
      .flat_map { |branch| HM::PatternGenerator.generate(branch) }
      .map(&.format)
      .should eq({{expected}})
  end
end

macro expect_matches(patterns, type, source)
  it "Expands type: {{source.id}}" do
    definitions =
      HM::Parser.definitions({{source}})

    fail "Could not parse {{source.id}}" unless definitions

    environment =
      HM::Environment.new(definitions)

    fail "Environment not sound!" unless environment.sound?

    enumerator =
      HM::BranchEnumerator.new(environment)

    branches =
      enumerator
        .possibilities(definitions.last)
        .flat_map { |branch| HM::PatternGenerator.generate(branch) }

    patterns =
      HM::Parser.patterns({{patterns}})

    fail "Cannot parse patterns!" unless patterns

    type =
      HM::Parser.type({{type}})

    fail "Cannot parse type!" unless type

    matcher =
      HM::PatternMatcher.new(environment)

    result =
      matcher.match_patterns(patterns, type)

    fail "Could not match patterns" unless result

    result[:not_covered].map(&.format).should be_empty
    result[:not_matched].map(&.format).should be_empty
  end
end

describe HM do
  expect_not_unify("Function(String,Number)", "Function(Number,Number)")
  expect_not_unify("Array(x)", "Array(x,y)")
  expect_not_unify("Array(x,y)", "Array(x)")
  expect_not_unify("Array(String)", "Bool")
  expect_not_unify("String", "Number")

  expect_unify("Array(Result(String, String), a)", "Array(x, x)", "Array(Result(String, String), Result(String, String))")
  expect_unify("Function(a: String, String)", "Function(String, String)", "Function(a: String, String)")
  expect_unify("Array(Result(String, String), a)", "Array(x, y)", "Array(Result(String, String), a)")
  expect_unify("Function(a, a, a)", "Function(a, a, String)", "Function(String, String, String)")
  expect_unify("Function(a, a, String)", "Function(a, a, a)", "Function(String, String, String)")
  expect_unify("Test(key: String, a)", "Test(key: a, a)", "Test(key: String, String)")
  expect_unify("Test(key: String, a)", "Test(a, key: a)", "Test(key: String, String)")
  expect_unify("Test(key: String)", "User(key: String)", "Test(key: String)")
  expect_unify("Maybe(a)", "Maybe(Array(a))", "Maybe(Array(a))")
  expect_unify("a", "String", "String")
  expect_unify("String", "a", "String")

  expect_define_type "type Test"
  expect_define_type "type Test(a, b)"
  expect_define_type "type Test(a, b) {}"

  expect_define_type <<-TYPE
  type Bool
  type String
  type Number

  type User {
    active : Bool,
    name : String,
    age : Number,
  }
  TYPE

  expect_define_type <<-TYPE
  type String

  type Status {
    Loaded(String)
    Loading
    Idle
  }
  TYPE

  expect_define_type <<-TYPE
  type Result(error, value) {
    Error(error)
    Ok(value)
  }
  TYPE

  expect_define_type <<-TYPE
  type Map(a, b)
  type Array(a)
  type Boolean
  type String
  type Number

  type JSON {
    Map(Map(String, JSON))
    Array(Array(JSON))
    Boolean(Boolean)
    String(String)
    Number(Number)
    Null
  }
  TYPE

  expect_define_type <<-TYPE
  type List(a, b) {
    name : a,
    age : b,
  }
  TYPE

  expect_define_type <<-TYPE
  type String
  type Html

  type TextareaAction {
    Download(filename : String, mimeType : String)
    ReadFile(accept : String)
    Html(content : Html)
    OpenAsLink
    Expand
    Clear
    Copy
  }
  TYPE

  expect_define_type <<-TYPE
  type Array(a)
  type String
  type Field

  type RequestTester.Body {
    FormData(Array(Field))
    String(String)
  }
  TYPE

  expect_branches(["Nothing", "Just(a)"], <<-TYPE
    type Maybe(a) {
      Nothing
      Just(a)
    }
    TYPE
  )

  expect_branches([
    "Loaded(content: String, Number, name: Nothing)",
    "Loaded(content: String, Number, name: Just(String))",
    "Loading",
    "Idle",
  ], <<-TYPE
    type String
    type Number

    type Maybe(a) {
      Nothing
      Just(a)
    }

    type Status {
      Loaded(content: String, Number, name: Maybe(String))
      Loading
      Idle
    }
    TYPE
  )

  expect_branches([
    "User(name: Just(String), active: Bool, age: Number)",
    "User(name: Nothing, active: Bool, age: Number)",
  ], <<-TYPE
    type String
    type Number
    type Bool

    type Maybe(a) {
      Just(a)
      Nothing
    }

    type User {
      name : Maybe(String),
      active : Bool,
      age : Number
    }
    TYPE
  )

  expect_patterns([
    "User(name: Just(String), active: Bool, age: Number)",
    "User(name: Nothing, active: Bool, age: Number)",
  ], <<-TYPE
    type String
    type Number
    type Bool

    type Maybe(a) {
      Just(a)
      Nothing
    }

    type User {
      name : Maybe(String),
      active : Bool,
      age : Number
    }
    TYPE
  )

  expect_matches(
    (<<-TYPE
    E(X, O)
    E(X, P)
    E(Y, O)
    E(Y, P)
    F(X)
    F(Y)
    G
    TYPE

      ), "D(C,E)",
    <<-TYPE2
    type A
    type B

    type C {
      X
      Y
    }

    type E {
      O
      P
    }

    type D(a, b) {
      E(a, b)
      F(a)
      G
    }
    TYPE2
  )

  expect_matches(
    (<<-TYPE
    [{a, b}, ...rest]
    [{a, _}]
    []
    TYPE

      ), "Array(Tuple(String, String))",
    <<-TYPE
    type String
    type Array(a)
    type Maybe(a) {
      Just(a)
      Nothing
    }
    TYPE
  )
end
