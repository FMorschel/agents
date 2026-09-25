# Test case matrix

A method for enumerating *which* cases to test, before writing any of them. Referenced by
`tester`, `test-writer`, `gap-finder`, and `test-adequacy-reviewer`.

The failure this exists to prevent: writing three good tests of one axis, zero of the other
axes that actually matter, and reporting the unit as covered. Line coverage does not catch this
— a single axis can execute every line in the file.

The opposite failure is just as real: turning every axis into tests for a unit where most of
them don't apply, and burying a small change under a test suite nobody asked for. The list below
is a **menu to check against, not a quota to fill**. An axis earns tests only when the unit
actually branches on it or the contract promises something about it.

## Sweep the axes before writing

Walk the list once per unit under test and decide, for each axis, whether it *applies* — i.e.
the contract says something about it, or the unit plausibly behaves differently along it. Only
applicable axes get cases. Inapplicable ones are dismissed in a single line (see the write-up
format in the `write-dart-tests` skill), not argued one by one.

### Core axes (any unit)

1. **Input-state ladder** — how much of the input is already present and valid: absent → empty →
   partial → complete → over-complete. Cover the rungs that lead to different behavior; rungs
   that resolve to the same path need one representative, not one test each.
2. **Origin variation** — the same logical input arriving via different callers or constructors
   that resolve differently. Only when there genuinely are several origins.
3. **Shape matrix of the types involved** — required / optional / named / nullable / empty
   collection / single element / many. Cover the shapes the contract distinguishes between.
4. **Position and ordering** — first, last, middle, interleaved. Only when order or position
   affects the result.
5. **Configuration sensitivity** — lints, analysis options, feature flags or settings that
   change what the *correct* output is. Ask it directly: "does any config change the expected
   result here?" If the answer is no, it's N/A — don't invent a config arm.
6. **Negatives** — a "does nothing / throws / declines" case for each applicable axis *whose
   negative behaves differently* from the others. Not one per axis by default; one per distinct
   failure path.

### Extra axes for code-transforming work (analyzer plugins, lints, fixes, assists, codegen)

Skip this section entirely unless the unit reads or rewrites source code.

7. **Nesting, generated both directions** — for any two constructs that can each contain the
   other, write A-in-B *and* B-in-A.
8. **Collision and formatting survival** — generated identifiers colliding with existing ones;
   multi-line input, trailing commas and existing whitespace surviving the operation intact.

## Two questions that restructure the work

- **"What is the user-visible outcome of each case?"** Write out the message, return value or
  error for every row before writing any test. When rows want materially different outcomes,
  the unit under test is usually N units rather than one — this is where an over-broad contract
  shows itself, while it's still cheap to split. When many rows want the *same* outcome, they
  are one case, not many.
- **"Which error or diagnostic does each case actually produce?"** Forces verification instead
  of assumption. Cases that look adjacent frequently report through entirely different paths and
  need separate handling.

## Scope boundary

The sweep tells you which cases *exist*. It does not license testing behavior the contract never
promised. An axis the contract leaves undefined is a **`gap-finder` finding**, not a test you
invent an expected value for. Report it; don't guess it.

**Unrequested-work check:** if a case you're about to add only exists "for completeness", "just
in case", or to make the code "more robust"/"more secure" — and neither the request nor the
contract mentioned that concern — don't write it. List it under `Unrequested extras` as a
question for the human ("is this case necessary?") and leave it out unless they say yes.
