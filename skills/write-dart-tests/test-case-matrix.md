# Test case matrix

A method for enumerating *which* cases to test, before writing any of them. Referenced by
`tester`, `test-writer`, `gap-finder`, and `test-adequacy-reviewer`.

The failure this exists to prevent: writing three good tests of one axis, zero of the other
seven, and reporting the unit as covered. Line coverage does not catch this — a single axis
can execute every line in the file.

## Sweep the axes before writing

Walk this list once per unit under test. For each axis produce either a case or an explicit
"N/A because …". A silently skipped axis is indistinguishable from an axis that doesn't apply.

1. **Input-state ladder** — how much of the input is already present and valid. Enumerate every
   rung, not just the interesting one: absent → empty → partial → complete → over-complete.
   Each rung is frequently a different code path, and in analyzer work a different diagnostic.
2. **Origin variation** — the same logical input arriving via different callers, constructors,
   or enclosing constructs that resolve differently. List the kinds explicitly; they do not get
   enumerated by intuition.
3. **Shape matrix of the types involved** — required / optional / named / nullable / empty
   collection / single element / many. Include shapes the type system permits but the happy
   path never produces.
4. **Position and ordering** — first, last, middle, interleaved with other kinds, and any
   ordering the API allows but doesn't encourage.
5. **Configuration sensitivity** — lints, analysis options, feature flags or settings that
   change what the *correct* output is. Ask it directly: "does any config change the expected
   result here?" This is the most consistently forgotten axis.
6. **Nesting, generated both directions** — for any two constructs that can each contain the
   other, write A-in-B *and* B-in-A. This rule reliably produces cases nobody enumerates by hand.
7. **Collision and formatting survival** — generated identifiers colliding with existing ones;
   multi-line input, trailing commas and existing whitespace surviving the operation intact.
8. **A negative per axis** — one "does nothing / throws / declines" case *per axis*, not one
   global negative. The interesting negatives are axis-specific.

## Two questions that restructure the work

- **"What is the user-visible outcome of each case?"** Write out the message, return value or
  error for every row before writing any test. When rows want materially different outcomes,
  the unit under test is usually N units rather than one — this is where an over-broad contract
  shows itself, while it's still cheap to split.
- **"Which error or diagnostic does each case actually produce?"** Forces verification instead
  of assumption. Cases that look adjacent frequently report through entirely different paths and
  need separate handling.

## Scope boundary

The sweep tells you which cases *exist*. It does not license testing behavior the contract never
promised. An axis the contract leaves undefined is a **`gap-finder` finding**, not a test you
invent an expected value for. Report it; don't guess it.
