from std.io.file import open
from bril import Code, Function, DebugWritable, parse_bril

def _indent(mut w: Some[Writer], level: Int):
  for _ in range(level):
    w.write("  ")

struct BasicBlock(Copyable, DebugWritable, Movable, Writable):
  var _name: String
  var instructions: List[Code]
  var dest_block_label: Optional[String]

  def __init__(out self,
      name: String,
      instructions: List[Code],
      dest: Optional[String] = None
  ):
    self._name = name
    self.instructions = instructions.copy()
    self.dest_block_label = dest.copy()

  def name(self) -> String:
    return self._name

  def write_to(self, mut w: Some[Writer]):
    self.write_debug(w, 0)

  def write_debug(self, mut w: Some[Writer], level: Int):
    w.write("BasicBlock {\n")
    _indent(w, level + 1)
    w.write('name: "', self._name, '",\n')
    _indent(w, level + 1)
    if self.instructions:
      w.write("instructions: [\n")
      for code in self.instructions:
        _indent(w, level + 2)
        code.write_debug(w, level + 2)
        w.write(",\n")
      _indent(w, level + 1)
      w.write("],\n")
    else:
      w.write("instructions: [],\n")
    _indent(w, level + 1)
    if self.dest_block_label:
      w.write('dest_block_label: Some("', self.dest_block_label.value(), '"),\n')
    else:
      w.write("dest_block_label: None,\n")
    _indent(w, level)
    w.write("}")


struct Graph(Movable, Writable):
  var graph: Dict[String, List[BasicBlock]]

  def __init__(out self):
    self.graph = Dict[String, List[BasicBlock]]()

  def is_empty(self) -> Bool:
    return len(self.graph) == 0

  def add_node(mut self, node_name: String):
    _ = self.graph.insert(node_name, List[BasicBlock]())

  # adds basic block
  def add(mut self, name: String, blk: BasicBlock):
    var list = self.graph.find(name)
    if list:
      list.value().append(blk.copy())
      self.graph[name] = list.value().copy()
    else:
      var node: List[BasicBlock] = [blk.copy()]
      _ = self.graph.insert(name, node^)

  def write_to(self, mut w: Some[Writer]):
    if not self.graph:
      w.write("Graph {}")
      return
    w.write("Graph {\n")
    for entry in self.graph.items():
      w.write('  "', entry.key, '": [\n')
      for blk in entry.value:
        _indent(w, 2)
        blk.write_debug(w, 2)
        w.write(",\n")
      w.write("  ],\n")
    w.write("}")

def is_control_passing(val: String) -> Bool:
  return val == "jmp" or val == "call" or val == "ret"

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
          dest = instruction.labels[0],
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

def build(program: Function) raises -> Graph:
  var g: Graph = Graph()

  var group_instructions: List[Code] = []

  for instr in program.instrs:
    var instruction = instr.copy()

    if instruction.is_label():
      group_instructions = []
      var _ = BasicBlock(
        name = instruction.label().name(),
        instructions = group_instructions.copy()
      )
      # g.add(bb)
    else:
      group_instructions.append(instruction.copy())
      var operation = instruction.instr().op
      if operation == "jmp" or operation == "ret" or operation == "call":
        var dest = ""
        # create basic block
        var bb = BasicBlock(
          instructions = group_instructions^,
          dest = dest,
          name = "",
        )
        g.add(bb.name(), bb)
        group_instructions = []
  return g^


def main() raises:
  var file = open("/dev/stdin", "r")
  var raw_content = file.read()
  var program = parse_bril(raw_content)
  var instructions = program.functions[0].instrs.copy()
  var cfg = buildx(instructions)
  print(cfg)
