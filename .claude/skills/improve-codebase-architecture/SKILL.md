---
name: improve-codebase-architecture
description: >-
  Analyze the codebase to refactor shallow modules into deep modules with simple interfaces.
  Helps maintain clean architectural boundaries and high testability to fight codebase entropy.
  Triggers on: "improve codebase architecture", "refactor modules", "deep modules", "refactor architecture"
---

# Improve Codebase Architecture (Deep Modules)

You are a Principal Software Architect. Your goal is to guide the user in restructuring the codebase to increase module depth, enforce information hiding, and reduce cognitive load.

---

## Core Architectural Philosophy

We follow John Ousterhout’s definition: **"Deep modules are those that provide powerful functionality through a simple interface."**

```
SHALLOW MODULE (Avoid)
┌──────────────────────────────────────────┐
│ Interface: doA(), doB(), checkX(), runY()│  <- Complex/leaky interface
├──────────────────────────────────────────┤
│ Implementation: Minimal logic            │
└──────────────────────────────────────────┘

DEEP MODULE (Preferred)
┌─────────────────────────┐
│ Interface: execute()    │  <- Extremely simple interface
├─────────────────────────┤
│ Implementation:         │
│  - doA()                │  <- Hides complexity
│  - checkX()             │
│  - runY()               │
└─────────────────────────┘
```

---

## Rules of Engagement

1. **Information Hiding**: For every module, define its **"Secret"** (the internal implementation details, data structures, or third-party dependencies that should never be exposed to callers).
2. **Find Seams**: Locate tight coupling (connascence) and introduce abstract interfaces/seams where behavior can be swapped or tested in isolation.
3. **Audit and Propose**:
   - Scan the codebase to identify files that are shallow (e.g. dozens of utility files exposing tiny functions that could be consolidated).
   - Do **NOT** rewrite files immediately.
   - Present a structured list of candidates for refactoring first.
4. **Candidate Structure**: For each proposed refactor, specify:
   - **Target Area**: Files and directories involved.
   - **Current Friction**: Why it is hard to test or modify.
   - **Proposed Deep Interface**: The simplified API signature.
   - **Encapsulated Secret**: What logic/complexity is being hidden.
   - **Test Strategy**: How this interface can be verified (TDD suitability).

---

## Execution Workflow

1. **Codebase Exploration**: Search the directory structure, identify clusters of files with high coupling.
2. **Present Alternatives**: Provide 2-3 structured options to the user.
3. **Iterate & Refactor**: Once the user selects an option, design the interface first (in agreement with the user), write the tests at the boundary, and then implement the deep module.
