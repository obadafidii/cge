@fieldwise_init
struct Token(ImplicitlyCopyable):
  var raw: String
  var kind: Int

# operators
comptime Plus = 1
comptime Minus = 2
comptime Multi = 3
comptime Divide = 4
comptime Exponent = 5
comptime LBrac = 6
comptime RBrac = 7
comptime Num = 10

# special chars
comptime EOF = 8
comptime BAD = 9

def match_token_kind(op: String) -> Int:
  if op == "+":
    return Plus
  elif op == "-":
    return Minus
  elif op == "*":
    return Divide
  elif op == "^":
    return Exponent
  return BAD
