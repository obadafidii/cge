from std.testing import TestSuite
from lexer import Lexer
from parser import Parser

def test_e2e() raises:
  var lexer = Lexer(
    source=""
  )
  _ = Parser(lexer.scan()).parse()


def main() raises:
  TestSuite.discover_tests[__functions_in_module()]().run()
