from std.io.file import open
from types import Graph, BasicBlock, is_control_passing
from bril import Code, parse_bril


# There is still bug in this implementation!
#
# All blocks must have a control passing instruction for
# the graph to be built well, but a basic block does not
# need to end with control passing instruction for example
# a block that ends with "print" instruction won't build well
def buildx(instructions: List[Code]) raises -> Graph:
  var label = "main"
  var block_count = 0
  var g = Graph()
  var group: List[Code] = []

  g.add_node(label)

  for code in instructions:
    if code.is_label():
      g.add_node(code.label().name())

  for code in instructions:
    if code.is_instr():
      var instruction = code.instr().copy()
      group.append(instruction.copy())

      if is_control_passing(instruction.op):
        var bb = BasicBlock(
          name = "blk-{}".format(block_count),
          instructions = group^,
          dest = instruction.labels.copy(),
        )
        g.add(label, bb^)
        block_count += 1
        group = []
    else:
      group = []
      label = code.label().name()

  # isnert last block
  var bb = BasicBlock(
    name = "blk-{}".format(block_count),
    instructions = group^,
  )
  g.add(label, bb^)

  return g^

def main() raises:
  var file = open("/dev/stdin", "r")
  var raw_content = file.read()
  var program = parse_bril(raw_content)
  var cfg = buildx(program.functions[0].instrs)
  print(cfg)
