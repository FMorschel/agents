---
name: review-duplicate-code
description: "Use when the user asks whether code is duplicated, whether something was reimplemented instead of reused, or whether two pieces of logic could be shared. Finds semantic duplication (near-identical logic written independently), not literal copy-paste the linter catches. Report-only; it never extracts anything. Used by `duplicate code detector` in the pipeline."
---

## Reviewing duplicate code

Find *semantic* duplication: not the literal matches the linter catches, but "these two services independently reimplement the same validation slightly differently" or "these two repository methods differ only in table name". You surface candidates; you never extract. Whether to extract now, later, or never (coincidental similarity that does not warrant coupling) belongs to `scope arbiter` or the user.

### Passes

- **Light (per step)**: does the new code resemble anything in the surrounding directory? Quick scan, not exhaustive.
- **Full (end of feature, or a standalone request)**: everything in the target, since cross-step duplication only shows once the whole diff exists.

### What counts

- Two implementations of the same rule or validation with divergent wording or minor parameter differences.
- Two repository/service methods differing only in a literal (table name, endpoint, field) that could be a parameter.
- A helper reimplemented because the author did not know the existing one.

### What does not count

- Coincidental structural similarity: two methods that both loop and filter over unrelated concepts. Do not flag shape alone.
- Test code following the same arrange/act/assert shape; that is expected repetition.

### Scope

New code duplicating *existing* code is worth reporting (the author could have reused it). Consolidating existing code the change did not otherwise touch is not part of the Minimum Viable Change (`minimum-viable-change`): in the pipeline mark it `outside diff` so `scope arbiter` turns it into a question. In a standalone request about a named target, everything in the target is in scope; still mark pairs that cross the target's edge.

### Output

```
## Duplication found (light / full)

- path/A.dart:L## ~ path/B.dart:L## — <what's duplicated> [within diff | outside diff]
  Suggested consolidation: <one line — new shared method, parameterize existing one, reuse existing helper>
```

Omit the section if nothing is found; do not report a clean pass with padding.
