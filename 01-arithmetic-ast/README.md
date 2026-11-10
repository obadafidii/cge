# 01 — Arithmetic AST and Recursive Traversal

**Difficulty:** Beginner | **Language:** Go | **Main concept:** Trees

## Why this matters

Compilers represent source expressions as trees so operator precedence and nested subexpressions become explicit. In this exercise, you'll build and inspect that representation.

## Problem

Build a small arithmetic-expression front end that accepts a string, constructs an abstract syntax tree (AST), and evaluates it by recursively walking the tree. Support integer literals, `+`, `-`, `*`, `/`, and parentheses. Whitespace may appear anywhere between tokens. Use integer division; specify how your implementation handles division by zero and malformed input.

## Example inputs and expected behavior

| Expression | Expected evaluation |
|---|---:|
| `2 + 3 * 4` | `14` |
| `(2 + 3) * 4` | `20` |
| `8 - 3 - 2` | `3` |
| `18 / (2 + 1)` | `6` |
| `1 + (2 * (3 + 4))` | `15` |

## Questions to answer before coding

1. What makes an AST different from a concrete parse tree?
2. Which node variants are essential for this subset of arithmetic?
3. How will your parser preserve precedence and left associativity?
4. Which traversal order naturally evaluates an arithmetic expression?
5. How would you represent and report invalid input without crashing?
6. What is the complexity of parsing and visiting a tree with `n` nodes?

## Required behavior

- Parse integer literals and binary arithmetic operators into an AST.
- Respect precedence, parentheses, and left associativity for `-` and `/`.
- Recursively evaluate the resulting AST.
- Provide an intelligible way to inspect the tree structure (a text printer is sufficient).
- Return errors for invalid syntax and division by zero.

## Tests to design

- Empty input; extra whitespace; one integer.
- Nested parentheses; mixed precedence; chained subtraction and division.
- Invalid tokens; missing closing parenthesis; incomplete expression.
- Division by zero; large expressions.

## Done when

Your parser constructs a tree that reflects grouping, your evaluator passes your tests, and you can explain how each recursive call corresponds to a subtree.

**Stretch:** Add unary negation and identifiers without breaking precedence.
