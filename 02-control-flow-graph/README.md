# 02 — Build a Control Flow Graph from Three-Address IR

**Difficulty:** Beginner–Intermediate | **Language:** Go | **Main concept:** Directed graphs

## Why this matters

An optimizer reasons about basic blocks and possible transfers of control rather than only about source lines.

## Problem

Take a small, already-parsed three-address instruction sequence and divide it into basic blocks. Connect blocks with directed edges to form a control flow graph (CFG). You do **not** need to write a text parser: an in-memory instruction representation is enough.

Supported instruction forms:

- `label X` — a label marking an instruction position
- `v = op a b` — a computation, where `op` is an arbitrary arithmetic operation
- `br X` — unconditional branch
- `cbr cond X Y` — conditional branch to either label
- `ret v` — return

Assume branches only target existing labels in valid programs. Define what happens on invalid input.

## Example input

```text
label entry
cond = gt x 10
cbr cond yes no
label yes
y = mul x 2
br end
label no
y = add x 1
br end
label end
ret y
```

Your graph should have the directed connections `entry -> yes`, `entry -> no`, `yes -> end`, and `no -> end`.

## Questions to answer before coding

1. What is a basic block? Where must blocks start and end?
2. Can a block end without an explicit branch? What edge would it have?
3. Why can a conditional branch have two successors?
4. How should `ret` affect outgoing edges?
5. How can your representation distinguish block identity from block ordering?
6. What errors should a malformed branch target produce?

## Required behavior

- Find block boundaries for labels, branches, and returns.
- Preserve the original instruction order within each block.
- Produce predecessor and successor relationships.
- Handle fallthrough to the next block when no terminating branch appears.
- Reject unknown branch targets and duplicate label definitions.
- Display the graph as an adjacency list or DOT text.

## Tests to design

- Straight-line code, if/else, and a loop with a back edge.
- Adjacent labels; an unconditional branch; an early return.
- An unreachable labeled block; invalid or duplicate labels.

## Done when

Every instruction belongs to exactly one block, branch edges are accurate, and you can explain every edge in the output graph.

**Stretch:** Emit a Graphviz DOT file and visualize the CFG.
