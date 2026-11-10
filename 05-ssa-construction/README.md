# 05 — Construct Static Single Assignment (SSA) Form

**Difficulty:** Advanced | **Language:** Go first; C++ optional later | **Main concept:** Dominance and phi nodes

## Why this matters

SSA gives each variable definition a unique version. At control-flow merges, phi nodes represent the value coming from a particular predecessor.

## Problem

Transform a small, non-SSA three-address CFG into SSA. Each assignment creates a new version of its destination. At appropriate join blocks, insert phi nodes and associate their incoming values with the correct predecessor edges.

Start with functions that have one entry, scalar local variables, arithmetic instructions, and `br`/`cbr`/`ret`. Variables used before a local definition are function parameters; represent those as predefined entry values. Assume no pointers, memory writes, exceptions, or aliasing.

## Example input

```text
entry:
  cbr cond left right
left:
  x = add a 1
  br join
right:
  x = add b 2
  br join
join:
  y = mul x 2
  ret y
```

The two assignments to `x` must become different SSA definitions. At `join`, the use of `x` must resolve to a phi node selecting the corresponding definition from `left` or `right`.

## Questions to answer before coding

1. Why is merely numbering assignments insufficient at control-flow joins?
2. What is a phi node, and why are its arguments associated with predecessor edges?
3. How is a dominance frontier different from a dominator tree?
4. How can dominators guide systematic variable renaming?
5. Why must loop back edges be considered during phi placement?
6. How will you validate the single-definition property?

## Required behavior

- Give every assignment a unique SSA name.
- Handle phi nodes at joins, including loops when your core implementation is working.
- Use CFG predecessor relationships consistently for phi operands.
- Ensure every SSA use refers to a well-defined SSA value that dominates its use (with the standard incoming-edge interpretation for phi operands).
- Preserve equivalent program behavior for well-defined inputs.
- Print the resulting SSA CFG in an understandable notation.

## Tests to design

- Straight-line repeated assignment; if/else join; nested branches.
- Join where only one predecessor redefines a variable.
- Loop with an updated variable; unused variable; multiple variables at one join.

## Done when

Every definition has a unique name, join points get correct phi operands, and you can explain how dominance matters to SSA renaming.

**Stretch:** Explore pruned SSA using liveness information after completing exercise 06.
