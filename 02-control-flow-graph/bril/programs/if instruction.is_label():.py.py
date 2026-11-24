    # group.append(instruction.copy())


if instruction.is_label():
      g.add_node(instruction.label().name())
      var name =
      var bb = BasicBlock(
        name,
        instructions = group^
      )
      g.add(name, bb^)
      group = []
    else:
      var code = instruction.instr().copy()
      if is_control_passing(code.op):
        var name = ""
        if g.is_empty():
          name = "main"

        var bb = BasicBlock(
          name,
          instructions = group^,
        )
        g.add(bb.name(), bb^)
        group = []
      var bb = BasicBlock(
        name = "",
        instructions = group^
      )
      g.add(bb.name(), bb^)
      group = []

#
