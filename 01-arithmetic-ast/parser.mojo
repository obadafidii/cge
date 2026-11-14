from token import Token

@fieldwise_init
struct Parser:
  var _tokens: List[Token]

  def parse(self):
    pass
