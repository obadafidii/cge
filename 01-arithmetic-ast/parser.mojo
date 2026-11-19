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
    while self._cursor < len(self._tokens):
      var _ = self._parse_expr()
    return 1

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
      return self._parse_lit_expr(token)

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

  def _parse_lit_expr(mut self, token: Token) raises -> Int:
    return self._track_expr(
      Expr(NumExpr(value=Int(token.raw)))
    )

  # this utilizes the _unary_fns to parse unary function
  # any type of unary expression is parsed with this method
  def _parse_unary_expr(mut self) raises -> Int:
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
    self._cursor += 1

  def pprint(self):
    print("AST")
    for i in range(len(self._ast)):
        self._print_expr(
            self._ast[i],
            "",
            i == len(self._ast) - 1
        )

  def _print_expr(
      self,
      expr: Expr,
      prefix: String,
      is_last: Bool
  ):
    var connector = "├── "
    var child_prefix = prefix + "│   "

    if is_last:
        connector = "└── "
        child_prefix = prefix + "    "

    if expr.isa[NumExpr]():
        ref literal = expr[NumExpr]
        print(prefix + connector + "NumExpr")
        print(child_prefix + "└── value: " + String(literal.value))

    elif expr.isa[UnaryExpr]():
        ref unary = expr[UnaryExpr]
        print(prefix + connector + "UnaryExpr (" + unary.op + ")")
        self._print_expr(
            self._ast[unary.operand],
            child_prefix,
            True
        )

    elif expr.isa[BinaryExpr]():
        ref binary = expr[BinaryExpr]
        print(prefix + connector + "BinaryExpr")
        print(child_prefix + "├── op: " + binary.op)
        print(child_prefix + "├── lhs: " + String(binary.lhs))
        print(child_prefix + "└── rhs: " + String(binary.rhs))


def test_parse_literals() raises:
  var tokens: List[Token] = [Token("1", Num), Token("+", Plus), Token("1", Num)]
  var parser = Parser(tokens)
  var _ = parser.parse()
  parser.pprint()

# def test_parsing_unary_expr_works() raises:
#   var tokens: List[Token] = [Token("+", Plus), Token("+", Plus), Token("-", Minus), Token("1", Num)]
#   var parser = Parser(tokens)
#   var _ = parser._parse_expr()
#   parser.pprint()

def main() raises:
  TestSuite.discover_tests[__functions_in_module()]().run()
