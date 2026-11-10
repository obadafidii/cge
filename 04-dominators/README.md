# 04 — Compute Dominators for a CFG

**Difficulty:** Intermediate | **Language:** Go | **Main concept:** CFG paths and fixed-point analysis

## Why this matters

Dominance is central to SSA construction, loop analysis, and many LLVM optimizations. A node `D` dominates node `N` if every path from the function entry to `N` passes through `D`.

## Problem

Given a directed CFG and its entry, compute the set of dominators for each **reachable** block. Also identify each non-entry block's immediate dominator, and derive a dominator tree.

## Example CFG

```text
       entry
       /   \
      A     B
       \   /
        merge
          |
         exit
```

Expected dominator sets:

```text
Dom(entry) = {entry}
Dom(A)     = {entry, A}
Dom(B)     = {entry, B}
Dom(merge) = {entry, merge}
Dom(exit)  = {entry, merge, exit}
```

## Questions to answer before coding

1. Why does every reachable block dominate itself?
2. What distinguishes a dominator from an immediate dominator?
3. Why doesn't either `A` or `B` dominate `merge`?
4. How can predecessor information help compute dominance?
5. Why might dominance analysis require repeated passes?
6. How should unreachable blocks be treated?

## Required behavior

- Compute dominator sets for all reachable blocks.
- Derive immediate dominators for all reachable non-entry blocks.
- Construct the dominator tree using immediate-dominator edges.
- Handle loops, diamonds, and a single entry node.
- Keep unreachable nodes out of the dominance computation, and document that choice.

## Tests to design

- Straight line; diamond; nested diamond; loop with a back edge.
- Single block; unreachable block; a join with multiple predecessors.
- Verify each non-entry reachable node has exactly one immediate dominator.

## Done when

The resulting dominator tree is rooted at the entry, and you can explain the difference between graph reachability and dominance.

**Stretch:** Compare a simple iterative method with a more advanced dominance algorithm; do not optimize prematurely.
