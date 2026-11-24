from bril import Code, DebugWritable

def _indent(mut w: Some[Writer], level: Int):
  for _ in range(level):
    w.write("  ")

struct BasicBlock(Copyable, DebugWritable, Movable, Writable):
  var _name: String
  var instructions: List[Code]
  var dest_block_label: Optional[List[String]]

  def __init__(out self,
      name: String,
      instructions: List[Code],
      dest: Optional[List[String]] = None
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
      w.write('dest_block_label: ', self.dest_block_label.value(), ',\n')
    else:
      w.write("dest_block_label: None,\n")
    _indent(w, level)
    w.write("}")



struct Graph(Movable, Writable):
  var graph: Dict[String, Optional[BasicBlock]]

  def __init__(out self):
    self.graph = Dict[String, Optional[BasicBlock]]()

  def is_empty(self) -> Bool:
    return len(self.graph) == 0

  def add_node(mut self, node_name: String):
    _ = self.graph.insert(node_name, None)

  # adds basic block
  def add(mut self, name: String, blk: BasicBlock):
    _ = self.graph.insert(name, blk.copy())

  def write_to(self, mut w: Some[Writer]):
    if not self.graph:
      w.write("Graph {}")
      return
    w.write("Graph {\n")
    for entry in self.graph.items():
      w.write('  "', entry.key, '": [\n')
      if entry.value:
        for blk in entry.value:
          _indent(w, 2)
          blk.write_debug(w, 2)
          w.write(",\n")
        w.write("  ],\n")
      else:
        w.write("  ],\n")
    w.write("}")

def is_control_passing(val: String) -> Bool:
  return val == "jmp" or val == "call" or val == "ret" or val == "br"
