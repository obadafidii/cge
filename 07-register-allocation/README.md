# 07 — Interference Graph and Register Allocation

**Difficulty:** Advanced | **Language:** Go first; C++ optional later | **Main concept:** Graph coloring

## Why this matters

A CPU has a limited number of physical registers. A compiler must decide which values can share them and which values cannot be stored in the same register simultaneously.

## Problem

Given a sequence of non-SSA instructions and instruction-level liveness information, build an undirected **interference graph**. Every variable is a vertex. Add an edge between variables that must have different registers because their live ranges overlap. Then attempt to assign each vertex one of `K` registers.

Start with arithmetic instructions and basic blocks, no precolored machine registers, no calls, and no special register constraints. You may extend to spills after the first implementation is correct.

## Example interference graph

```text
Vertices: a, b, c, d
Edges: (a,b), (a,c), (b,c), (c,d)
```

With `K = 2`, this graph cannot be colored without a spill or another strategy because `a`, `b`, and `c` form a triangle. With `K = 3`, a valid coloring exists.

## Questions to answer before coding

1. What does an interference edge mean operationally?
2. Why is the interference graph undirected?
3. How do definitions and live-out values reveal interference?
4. Why is assigning registers related to graph coloring?
5. How would you detect that a proposed coloring is invalid?
6. What tradeoffs arise when choosing a variable to spill?

## Required behavior

- Build an interference graph from your chosen instruction representation and liveness information.
- Treat graph edges as undirected; avoid self-edges and duplicate edges.
- Attempt register coloring for configurable `K`.
- Validate that no adjacent vertices receive the same register.
- Clearly report when your coloring strategy cannot allocate within `K` registers.
- Explain whether a reported failure means the graph is truly uncolorable or only that your heuristic failed.

## Tests to design

- No edges; one edge; chain; clique; a graph with disconnected components.
- A graph colorable with `K = 2`; triangle requiring `K = 3`.
- Realistic instruction sequence with overlapping live ranges.

## Done when

Your allocator produces valid assignments for tested colorable cases, identifies conflicts correctly, and can explain why some variables cannot share registers.

**Stretch:** Add spill candidates and re-run allocation after explicitly modeling spill code and recomputing liveness.
