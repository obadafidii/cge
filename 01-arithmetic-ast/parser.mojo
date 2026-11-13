from token import Token

@fieldwise_init
struct Parser:
  var tokens: List[Token]

  def parse(self):
    pass
