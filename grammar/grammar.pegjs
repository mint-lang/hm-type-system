// The start rule.
start =
  type / ("type" _ definition)

// A type.
type =
  typeidentifier _ ("(" (_ (identifier / type) ",")* (_ (identifier / type) ","?)? _ ")")*

// A definition of a type.
definition =
  typeidentifier _ ("(" (_  expression ",")* (_  expression ","?)? _ ")")? _ body?

// The body of a type basically fields or expressions.
body =
  "{" (_ (field / expression))* _ "}"

// A filed of a type consisting of an identifier and an expression.
field =
  identifier _ ":" _ expression

// An expression.
expression =
  definition / identifier

// A type indentifier starting with an uppercase letter.
typeidentifier =
  [A-Z] [A-Za-z0-9]*

// An identifier starting with a lowercase letter.
identifier =
  [a-z] [A-Za-z0-9]*

// Whitespace
_  =
  [ \t\r\n]*
