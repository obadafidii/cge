# 03 — Reachability Analysis with DFS

**Difficulty:** Beginner | **Language:** Go | **Main concept:** Graph traversal

## Why this matters

Compilers often need to identify blocks that cannot execute from the function entry. Reachability is also a foundation for other CFG analyses.

## Problem

Given a directed CFG with a designated entry node, identify all reachable and unreachable blocks using depth-first search (DFS). Work directly from a graph representation; you do not need to parse IR or reuse exercise 02.

## Example input

```text
Entry: A
A -> B, C
B -> D
C -> D
D -> B
E -> F
F -> (none)
```

Expected reachable set: `{A, B, C, D}`.
Expected unreachable set: `{E, F}`.

The *set* matters, not the particular traversal order; ordering may vary with adjacency-list order.

## Questions to answer before coding

1. Why does DFS require a visited set when a graph has cycles?
2. What is the difference between a DFS tree and the original CFG?
3. Is a node reachable if it has no incoming edges?
4. Can a directed edge exist from a reachable node to an unreachable node?
5. What are the time and memory complexities of DFS in terms of `V` and `E`?

## Required behavior

- Mark exactly the blocks reachable from the designated entry.
- Identify every unreachable block, including disconnected cycles.
- Handle self-loops and repeated edges without infinite recursion.
- Return a deterministic sorted representation of sets for tests or printing.
- Define how unknown entry nodes are handled.

## Tests to design

- Single-node graph; empty graph; linear chain; diamond CFG.
- Cycle; self-loop; disconnected graph; multiple disconnected components.
- Entry node with no outgoing edges.

## Done when

You can trace DFS manually and prove that no unreachable block is falsely marked reachable.

**Stretch:** Implement iterative DFS and compare its behavior to recursive DFS on very deep graphs.
