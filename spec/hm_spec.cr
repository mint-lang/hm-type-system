require "./spec_helper"

macro expect_not_unify(a, b)
  it "{{a.id}} vs {{b.id}}" do
    type1 = HM.parse({{a}})
    type2 = HM.parse({{b}})

    if type1 && type2
      result = HM.unify(type1, type2)

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
    type1 = HM.parse({{a}})
    type2 = HM.parse({{b}})

    if type1 && type2
      result = HM.unify(type1, type2)

      unless result
        fail "Expected \"{{a.id}}\" and \"{{b.id}}\" to be unifiable but they are not."
      end

      HM.to_s(result).should eq({{expected}})
    else
      fail "Could not parse {{a.id}} or {{b.id}}."
    end
  end
end

describe HM do
  expect_not_unify("Function(String,Number)", "Function(Number,Number)")
  expect_not_unify("Array(x)", "Array(x,y)")
  expect_not_unify("Array(x,y)", "Array(x)")
  expect_not_unify("Array(String)", "Bool")
  expect_not_unify("String", "Number")

  expect_unify("Array(Result(String, String), a)", "Array(x, x)", "Array(Result(String, String), Result(String, String))")
  expect_unify("Array(Result(String, String), a)", "Array(x, y)", "Array(Result(String, String), a)")
  expect_unify("Function(a, a, a)", "Function(a, a, String)", "Function(String, String, String)")
  expect_unify("Function(a, a, String)", "Function(a, a, a)", "Function(String, String, String)")
  expect_unify("Test(key: String, a)", "Test(key: a, a)", "Test(key: String, String)")
  expect_unify("Test(key: String, a)", "Test(a, key: a)", "Test(key: String, String)")
  expect_unify("Maybe(a)", "Maybe(Array(a))", "Maybe(Array(a))")
  expect_unify("a", "String", "String")
  expect_unify("String", "a", "String")
end
