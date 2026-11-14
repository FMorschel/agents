---
name: show-concrete-change-examples
description: Use whenever you explain a suggested change to a codebase. Add a concrete example of how the visual output, timing, or values would change, scaled to the change.
---

# Concrete change examples

When you suggest what to do on a codebase, show the practical effect, not just the code change.

## What to include

- **Visual changes (UI, layout, text, output):** describe or sketch the screen before and after. Name the specific element that changes and how it looks: position, size, color, text.
- **Timing changes (performance, build, tests, network):** give an estimated before and after duration. Example: "cold start drops from about 4.2 s to about 1.8 s", or "the test suite grows from about 40 s to about 55 s".
- **Value changes (config, data, defaults, limits):** show one example input with its old and new output. Example: "a 30-minute session timeout becomes 60 minutes, so a session idle at 45 minutes now stays logged in".
- **Behavior changes (errors, edge cases):** show one input and the old and new result.

## How to scale it

- Match the example to the size of the change. A one-line tweak needs one short example. A large refactor needs a few representative cases.
- Say when a number is an estimate and how you got it. Do not present guesses as measurements.
- If the effect cannot be measured or shown without running the code, say so and suggest how to check it.

## Format

Put the example right after the suggestion, under a short label such as "Example:". Use a code block for literal output, text, or values. Use a Mermaid diagram only when the change is about flow or structure.
