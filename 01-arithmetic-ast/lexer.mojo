from std.format._utils import write_to
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

@fieldwise_init
struct Span(ImplicitlyCopyable):
  var col: Int
  var row: Int

@fieldwise_init
struct LexerError(ImplicitlyCopyable, Writable):
  var error: String
  var span: Span

  def write_to(self, mut writer: Some[Writer]):
    t"error '{self.error}' at col={self.span.col} row={self.span.row}".write_to(writer)

@fieldwise_init
struct Lexer:
  var _text: String
  var _cursor: Int
  var _errors: List[LexerError]

  def __init__(out self, source: String):
    self._text = source
    self._cursor = 0
    self._errors = List[LexerError]()

  def errors(self) -> ref [self._errors] List[LexerError]:
    return self._errors

  def _track_error(mut self, msg: String, col: Int, row: Int):
    var error = LexerError(
      error=msg,
      span=Span(
        col=col,
        row=row
      )
    )
    self._errors.append(error)

  def _is_digit(self, char: StringSpan) -> Bool:
    return char >= "0" and char <= "9"

  def _advance(mut self):
    if self._cursor >= self._text.byte_length():
      self._cursor = 0
    else:
      self._cursor += 1

  # Example:
  # 2 + 3 * 4 -> [Num(2), Plus(+), Num(3), Multi(*), Num(4)]
  # (2 + 3) * 4 -> [LBrac((), Num(2), Plus(+), Num(3), RBrac()), Multi(*), Num(4)]
  def scan(mut self) -> List[Token]:
    # scanned tokens
    var _tokens: List[Token] = List[Token]()

    while self._cursor < self._text.byte_length():
      var char = self._text[byte=self._cursor]
      if char == " " or char == "\t" or char == "\n":
        self._advance()
        continue
      elif char == "+":
        _tokens.append(Token("+", Plus))
      elif char == "-":
        _tokens.append(Token("-", Minus))
      elif char == "*":
        _tokens.append(Token("*", Multi))
      elif char == "/":
        _tokens.append(Token("/", Divide))
      elif char == "^":
        _tokens.append(Token("^", Exponent))
      elif char == "(":
        _tokens.append(Token("(", LBrac))
      elif char == ")":
        _tokens.append(Token(")", RBrac))
      elif self._is_digit(char):
        var current = self._cursor
         # loop while checking if we've reached end of file and its a digit
        while self._cursor < self._text.byte_length() and self._is_digit(self._text[byte=self._cursor]):
          self._advance()

        var num = String(self._text[byte=current:self._cursor])
        try:
          _ = Int(num)
          _tokens.append(Token(num, Num))
          continue
        except:
          self._track_error("error scanning numbers", 0, self._cursor)
      else:
        self._track_error("unexpected character: {}".format(char), 0, self._cursor)

      self._advance()

    # mark end of file
    _tokens.append(Token("EOF", EOF))

    return _tokens^


##### TESTS #######

def test_operators() raises:
  var lexer = Lexer(
    source="+/-*^()"
  )
  var result = lexer.scan()

  assert_equal(len(result), 8)
  assert_equal(result[0].raw, "+")
  assert_equal(result[0].kind, Plus)

  assert_equal(result[1].raw, "/")
  assert_equal(result[1].kind, Divide)

  assert_equal(result[2].raw, "-")
  assert_equal(result[2].kind, Minus)

  assert_equal(result[3].raw, "*")
  assert_equal(result[3].kind, Multi)

  assert_equal(result[4].raw, "^")
  assert_equal(result[4].kind, Exponent)

  assert_equal(result[5].raw, "(")
  assert_equal(result[5].kind, LBrac)

  assert_equal(result[6].raw, ")")
  assert_equal(result[6].kind, RBrac)

  # EOF token
  assert_equal(result[7].raw, "EOF")
  assert_equal(result[7].kind, EOF)

def test_whitespace() raises:
  var lexer = Lexer(
    source=" "
  )
  var tokens = lexer.scan()
  assert_equal(len(tokens), 1)
  assert_equal(tokens[0].raw, "EOF")
  assert_equal(tokens[0].kind, EOF)

def test_whitespace_in_between_chars() raises:
  var lexer = Lexer(
    source=" + /      ^  "
  )
  var tokens = lexer.scan()
  assert_equal(len(tokens), 4)
  assert_equal(tokens[0].kind, Plus)
  assert_equal(tokens[1].kind, Divide)
  assert_equal(tokens[2].kind, Exponent)
  assert_equal(tokens[3].kind, EOF)

def test_bad_token() raises:
  var lexer = Lexer(
    source="@"
  )
  var tokens = lexer.scan()
  assert_equal(len(lexer.errors()), 1)
  assert_equal(lexer.errors()[0].error, "unexpected character: @")
  assert_equal(len(tokens), 1)
  assert_equal(tokens[0].kind, EOF)

def test_number_scanning() raises:
  var lexer = Lexer(
    source="1232"
  )
  var tokens = lexer.scan()
  assert_equal(len(tokens), 2)
  assert_equal(tokens[0].raw, "1232")
  assert_equal(tokens[0].kind, Num)

def test_lexer_tracks_unexpected_char() raises:
  # there is 5 invalid character here
  var lexer = Lexer(
    source=" + / 123#@ >2 [* >> !!"
  )
  var tokens = lexer.scan()
  assert_equal(len(tokens), 6)
  assert_equal(len(lexer.errors()), 8)
  for error in lexer.errors():
    print(error)

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
