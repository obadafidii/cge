# 06 — Backward Liveness Analysis

**Difficulty:** Intermediate–Advanced | **Language:** Go | **Main concept:** Backward data-flow analysis

## Why this matters

A value is live when the program may still need it before it is overwritten. Register allocation and several optimization passes depend on this information.

## Problem

Given a CFG of basic blocks containing assignments and variable uses, compute each block's `USE`, `DEF`, `LIVE_IN`, and `LIVE_OUT` sets. Work from a supplied or hand-built CFG; do not reuse exercise 02 code.

Treat `USE(B)` as variables used before any definition within block `B`, and `DEF(B)` as variables defined in the block. Treat function parameters as already-defined inputs. For the core challenge, use non-SSA variables and do not include phi nodes.

## Example CFG

```text
entry:
  x = 1
  cbr cond left right
left:
  y = add x 2
  br end
right:
  y = add x 3
  br end
end:
  z = mul y 4
  ret z
```

For block `end`, `USE(end)` contains `y` and `DEF(end)` contains `z`. The definition of `x` in `entry` must stay live along both paths into blocks that use it.

## Questions to answer before coding

1. What does it mean for a variable to be live *at a program point*?
2. Why is liveness a backward, rather than forward, analysis?
3. What's the distinction between `USE` and `DEF` when a variable is read and then overwritten?
4. Why can cycles in a CFG require multiple passes?
5. When can a variable be live on one outgoing edge but not another?
6. How can a worklist avoid unnecessary reprocessing?

## Required behavior

- Compute `USE` and `DEF` per block based on instruction order.
- Compute `LIVE_IN` and `LIVE_OUT` until results stop changing.
- Handle joins, loops, early returns, and empty blocks.
- Document how return values and branch-condition uses are modeled.
- Present sets in a deterministic format for testing.

## Tests to design

- Straight-line code; diamond; loop; unused assignment.
- Read-before-write in the same block; variable redefinition.
- Multiple successors; a variable live in only one branch.

## Done when

The data-flow result has converged and you can justify why each value is live or dead on every block boundary.

**Stretch:** Compute instruction-level liveness and contrast it with block-level liveness.
