# CGE — Compiler Graph Exercises

A collection of self-contained, implementation-first exercises exploring the trees and graphs behind compilers.

## Ground rules

- **Start in Go.** C++ is an optional second implementation once an algorithm is understood.
- Each numbered directory is an independent exercise with its own README, inputs, goals, and acceptance criteria.
- **No solutions are provided.** Choose your own data structures, APIs, and code organization.
- You can use Go's standard library; avoid external graph libraries for the core algorithms.
- Make tests part of each solution. Explain your choices and complexity in a short `NOTES.md` when complete.
- A later exercise may build on ideas from an earlier one, but should not import its implementation.

## Exercises

| # | Exercise | Main ideas | Suggested language |
|---|---|---|---|
| 01 | [Arithmetic AST](01-arithmetic-ast/README.md) | Trees, recursion, expression precedence | Go |
| 02 | [Build a CFG](02-control-flow-graph/README.md) | Basic blocks, directed edges | Go |
| 03 | [CFG Reachability](03-reachability-dfs/README.md) | DFS, visited sets, unreachable code | Go |
| 04 | [Dominators](04-dominators/README.md) | Paths, dominance, dominator trees | Go |
| 05 | [SSA Construction](05-ssa-construction/README.md) | Def-use, phi placement, renaming | Go, then C++ optional |
| 06 | [Liveness Analysis](06-liveness-analysis/README.md) | Backward data flow, fixed points | Go |
| 07 | [Interference Graph](07-register-allocation/README.md) | Register conflicts, graph coloring | Go, then C++ optional |

## Suggested workflow

1. Open a numbered exercise README and study its input examples.
2. Design the representation on paper before coding.
3. Write tests for the listed edge cases.
4. Implement and document your complexity and assumptions.
5. Only move on when the acceptance criteria are satisfied.

The READMEs describe problems, **not implementation steps or completed code**.

## Starting locally

```bash
cd 01-arithmetic-ast
# Read README.md, then create your own Go package and tests.
```

You can create a separate `go.mod` inside each exercise if you want true build isolation, or a root `go.work` after you begin writing modules. Neither is generated in advance.
