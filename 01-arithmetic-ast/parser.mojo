from std.utils import Variant
from std.testing import TestSuite, assert_equal
from token import (
  Token,
  Plus,
  Minus,
  Multi,
  Divide,
  Exponent,
  LBrac,
  RBrac,
  Num,
  BAD,
  EOF,
)

# The 3 supported expressions are
# 1. LiteralExpression
# 2. Unary Expression
# 3. Binary Expression

comptime Expr = Variant[NumExpr, UnaryExpr, BinaryExpr]
comptime UnaryFn = def(mut self: Parser) thin raises -> Int
comptime BinaryFn = def(mut self: Parser, lhs: Expr) thin raises -> Int

# NOTE:
# Currently my Mojo's skills are not the best and I have tried all possible
# ways establish recursive-pointer structure I am used to. So now Expression
# values are going to be tracking their position in the tree (_ast: List[Token])
# instead of tracking the value itself. Once I get better at this I will come back
# to refactor this code. Going online and check this link 👇
#
# I found the name of this stuff is Arena or Flattned based parsing. 🫠 It is
# quite different in thought process from what I normally know link👇
#

@fieldwise_init
struct NumExpr(ImplicitlyCopyable, Copyable):
    var value: Int

@fieldwise_init
struct UnaryExpr(ImplicitlyCopyable, Copyable):
    var op: String
    var operand: Int

@fieldwise_init
struct BinaryExpr(Copyable):
    var op: String
    var lhs: Int
    var rhs: Int


# Transforms tokens into Trees (Expr)
struct Parser:
  var _cursor: Int
  var _tokens: List[Token]
  # so the ast is actually flat as compared to it being pointer based
  var _ast: List[Expr]
  # register all method on token to parse prefix expressions
  var _unary_fns: Dict[Int, UnaryFn]
  # the binary parser take the left hand side of the expression
  # and continues to parse the token, then right expression
  var _binary_fns: Dict[Int, BinaryFn]

  def __init__(out self, mut tokens: List[Token]):
    self._tokens = tokens.copy()
    self._ast = List[Expr]()
    self._cursor = 0
    self._unary_fns = Dict[Int, UnaryFn]()
    self._binary_fns = Dict[Int, BinaryFn]()

    self._registerFns()

  def _registerFns(mut self):
    # register unary function
    self._unary_fns[Plus] = Self._parse_unary_expr
    self._unary_fns[Minus] = Self._parse_unary_expr
    self._unary_fns[Num] = Self._parse_unary_expr

    # register binary function
    self._binary_fns[Plus] = Self._parse_be
    self._binary_fns[Minus] = Self._parse_be
    self._binary_fns[Divide] = Self._parse_be
    self._binary_fns[Multi] = Self._parse_be
    self._binary_fns[Exponent] = Self._parse_be

  def parse(mut self) raises -> Int:
    return self._parse_expr()

  # This the main method converting token stream to trees
  #
  # Example:
  # _tokens = [Num(2), Plus(+), Num(3), Multi(*), Num(4)]
  # transforms into:
  #
  #           Plus(+)
  #        /           \
  #      Num(2)        Multi(*)
  #                    /      \
  #                Num(3)     Num(4)
  #
  # Now since this parsing is arena based as opposed to recursive-pointer format
  # the tokens are
  def _parse_expr(mut self) raises -> Int:
    # check if the current token is numeric
    var token = self._consume()

    if token.kind == Num:
      return self._track_expr(
        Expr(NumExpr(value=Int(token.raw)))
      )

    var unary_fn = self._unary_fns.get(token.kind)
    if unary_fn:
      var _fn = unary_fn.value()
      var rhs = _fn(self)
      return self._track_expr(
        Expr(
          UnaryExpr(
            op=token.raw,
            operand=rhs
          )
        )
      )
    else:
      raise Error(t"token kind {token.raw} not supported")

  # parse binary expression using recursive descent parsing
  def _parse_be(mut self, left: Expr) raises -> Int:
    return -1

  # this utilizes the _unary_fns to parse unary function
  # any type of unary expression is parsed with this method
  def _parse_unary_expr(mut self) raises -> Int:
    print("here = ", self._cursor)
    var idx = self._parse_expr()
    return idx

  def _track_expr(mut self, var expr: Expr) -> Int:
    var node_idx = len(self._ast)
    self._ast.append(expr^)
    return node_idx

  def _consume(mut self) -> Token:
    var token = self._tokens[self._cursor]
    self._move_cursor()
    return token

  def _expect(self, token: Int) -> Bool:
    return self._peek().kind == token

  def _peek(self) -> Token:
    return self._tokens[self._cursor+1]

  def _move_cursor(mut self):
    if self._cursor >= len(self._ast):
      self._cursor = 0
    else:
      self._cursor += 1

  # parse binary expression using flattened trees
  # todo: last exercise
  def _parse_be_flat(mut self):
    pass



def test_parse_literals() raises:
  var tokens: List[Token] = [Token("+", Plus), Token("1", Num)]
  var parser = Parser(tokens)
  var _ = parser._parse_expr()

# def test_parsing_unary_expr_works() raises:
#   var tokens: List[Token] = [Token("+", Plus), Token("+", Plus), Token("-", Minus), Token("1", Num)]
#   var parser = Parser(tokens)
#   var _ = parser._parse_expr()
#   parser.pprint()

def main() raises:
  TestSuite.discover_tests[__functions_in_module()]().run()
