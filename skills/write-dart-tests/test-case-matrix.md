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
   failure path. Pin the **error contract**, not just "it failed": the exception type (or error
   code) and a stable part of the message, whether it surfaces as a synchronous throw or a failed
   `Future`/`Stream`, and that state is left unchanged afterwards (`expect(() => f(''),
   throwsA(isA<FormatException>()))`, then the balance is still 100 — not `throwsA(anything)`).

### Conditional axes (only when the unit's types or behavior call for them)

Each of these applies only to a unit with that kind of input or behavior; for everything else it
goes on the `N/A:` line. An axis the contract is silent about is still reported to `gap-finder`,
never given an invented expected value (see Scope boundary).

7. **Text input: malformed and hostile strings** — for a unit that parses, validates, formats or
   forwards a `String`. Pick the classes the unit could plausibly treat differently:
   whitespace-only; leading/trailing whitespace; very long; control characters, newlines, null
   bytes; Unicode (combining marks, emoji and surrogate pairs — is `'👩‍👩‍👧'` 1 character or 5? —
   zero-width and right-to-left characters, lookalike quotes); strings that look like another
   type (`'1e5'`, `'0x10'`, `'../etc'`, `'null'`, `'NaN'`); case and locale quirks (`'İ'`).
   Expected outcome per class: accepted, normalized, or rejected with the unit's error contract —
   never an unrelated exception from deeper in the stack. Several classes that resolve to the same
   outcome are one case with one representative, not one test each.
   `parseUsername(String)` today gets `''` and `'bad name'`; this axis adds `'   '`, `'a\u0000b'`,
   the emoji family, and a 10,000-character string.
8. **Numeric boundaries** — for a unit that takes or returns numbers: 0, -1, the limits of any
   documented range and one step either side, `int` overflow (and VM vs. web, where `int` differs),
   `NaN`, infinities, `-0.0`, division by zero, rounding direction at `.5`.
   `percent(int part, int total)` gets `(1, 2)` today; this adds `(0, 0)`, `(1, -2)` and
   `(maxInt, 1)`.
9. **Time and date** — for a unit that does calendar or clock arithmetic: DST gaps and overlaps,
   leap day, month/year rollover (`Jan 31` + 1 month), UTC vs. local, `DateTime` with and without
   a zone, and an injected clock instead of `DateTime.now()` so the test is deterministic.
10. **Idempotency and round-trip** — a property check that needs no per-case expected value:
    `f(f(x)) == f(x)` for normalizers and formatters, and `decode(encode(x)) == x` for every
    inverse pair, including `x` with null optionals and empty collections.
11. **Input mutation and aliasing** — the unit leaves its arguments unchanged, does not hand back
    the caller's own collection or its internal one, and later changes to an argument do not leak
    into a stored result. `sorted(xs)` called with `[3, 1, 2]` leaves `xs` as `[3, 1, 2]`; a
    getter returning the internal list lets `x.items.add(…)` corrupt state.
12. **Async and concurrency** — for an `async` unit or one holding state across calls: two
    overlapping calls, out-of-order completion (`search('a')` finishing after `search('ab')`),
    cancel or dispose mid-flight, a failure on the second step of a sequence, a stream that errors
    or closes early, and a repeated call while one is still pending.
13. **Scale** — for a unit that loops or recurses over its input: empty, one, a large size (10⁵
    elements, a very long string), and deep nesting (a 10,000-deep nested list into a recursive
    `flatten`). Assert it completes and returns the right result, not a wall-clock time.

### Extra axes for code-transforming work (analyzer plugins, lints, fixes, assists, codegen)

Skip this section entirely unless the unit reads or rewrites source code.

14. **Nesting, generated both directions** — for any two constructs that can each contain the
    other, write A-in-B *and* B-in-A.
15. **Collision and formatting survival** — generated identifiers colliding with existing ones;
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
