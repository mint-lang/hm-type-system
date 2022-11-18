require "./spec_helper"

describe HM::Parser do
  describe "type" do
    it "parses a type" do
      HM::Parser.type("Test").should be_a(HM::Type)
    end

    it "parses a type with parentheses but without parameters" do
      HM::Parser.type("Test()").should be_a(HM::Type)
    end

    it "parses a type with parameters" do
      HM::Parser.type("Test(a, b, c)").should be_a(HM::Type)
    end

    it "parses a complex type" do
      HM::Parser
        .type("Test(Test(A, B, c, X(d, e, f: String)))")
        .should be_a(HM::Type)
    end

    it "fails if type not starts with uppercase" do
      HM::Parser.type("a").should be_nil
    end

    it "fails if there is no closing parentheses" do
      HM::Parser.type("Test(").should be_nil
    end
  end

  describe "identifier" do
    it "parses an identifier" do
      HM::Parser.new("A").identifier.should be_a(String)
    end

    it "parses an identifier with a dot in it" do
      HM::Parser.new("A.B").identifier.should be_a(String)
    end

    it "fails if identifier not starts with uppercase" do
      HM::Parser.new("a").identifier.should be_nil
    end
  end

  describe "pattern" do
    it "parses a type pattern" do
      HM::Parser.pattern("Test").should be_a(HM::Pattern)
    end

    it "parses an array pattern" do
      HM::Parser.pattern("[]").should be_a(HM::Pattern)
    end

    it "parses a spread pattern" do
      HM::Parser.pattern("...rest").should be_a(HM::Pattern)
    end

    it "parses a variable pattern" do
      HM::Parser.pattern("a").should be_a(HM::Pattern)
    end

    it "parses a field pattern" do
      HM::Parser.pattern("a : b").should be_a(HM::Pattern)
    end

    it "parses a tuple pattern" do
      HM::Parser.pattern("{a, b}").should be_a(HM::Pattern)
    end

    it "parses a wildcard pattern" do
      HM::Parser.pattern("_").should be_a(HM::Pattern)
    end

    it "parses a complex pattern" do
      HM::Parser
        .pattern("Type([{a, b, c}, a : b, Type2(_, _), ...rest])")
        .should be_a(HM::Pattern)
    end
  end
end
