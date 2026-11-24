from std.io.file import open
from types import Graph, BasicBlock, is_control_passing
from bril import Code, parse_bril

def buildx(instructions: List[Code]) raises -> Graph:
  var label = "main"
  var block_count = 1
  var g = Graph()
  var group: List[Code] = []

  g.add_node(label)

  # build graph nodes.
  for code in instructions:
    if code.is_label():
      g.add_node(code.label().name())

  # map instructions to nodes.
  for code in instructions:
    if code.is_instr():
      var instruction = code.instr().copy()
      group.append(instruction.copy())

      if is_control_passing(instruction.op):
        g.add(
          label,
          BasicBlock(
            name = "blk-{}".format(block_count),
            instructions = group^,
            dest = instruction.labels.copy(),
          )
        )
        block_count += 1
        group = []
    else:
      # handles fallthrough scenarios where a block does not
      # terminate with a control flow, so execution just moves
      # to next label
      if len(group) != 0:
        var last_instr = group[len(group) - 1].instr().copy()
        g.add(
          label,
          BasicBlock(
            name = "blk-{}".format(block_count),
            instructions = group^,
            dest = last_instr.labels.copy(),
          )
        )
        block_count += 1
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
