---
name: review-sql-safety
description: "Use when writing or reviewing hand-written SQLite/Postgres query code (data sources, raw SQL) to check for injection risk and whether the tests pass hostile input, and when reviewing a validator for SQL from an untrusted source, such as AI-generated SQL (allowed table and function lists, company scoping, fail closed). Report-only; not for passwords, tokens or personal data (`review-sensitive-data`)."
---

## Reviewing SQL safety

Check raw SQL and query construction in the data source layer for injection risk. This is only about the safety of hand-written queries, not general code quality or architecture. Findings go to the user.

### What to check

- String interpolation or concatenation used to build a query with any value that comes from outside the method (a parameter, user input, data from another layer). It should be a parameterized query or a placeholder.
- Table or column names built dynamically from untrusted input.
- Batch or transaction code where a single unparameterized statement undoes the safe code around it.
- `ORDER BY`, `LIMIT`/`OFFSET`, `IN (...)` lists or column lists built by joining or interpolating values. Placeholders usually cannot bind these elements, so they need an allow-list or per-element placeholders.
- `LIKE` patterns built from external text without escaping `%`, `_` and the escape character. The query is parameterized, but the caller can still match everything.
- Second-order injection: a value read back from the database (or from another layer) and later interpolated into another query.

### What not to flag

- Static SQL with no external input.
- Parameterized queries, even verbose ones.
- Query builder or ORM calls that already handle parameterization internally.

### Validator for SQL from an untrusted source

When reviewing a SQL validator whose input comes from an AI model, a user or any other untrusted system, you cannot prove by reading that it is safe. Report each point below as what you saw in the code and as a hypothesis to confirm with a hostile test, never as "the validator is safe", and say what you could not verify (the real database dialect, the connection's role). Check:

- **Allow-list, not block-list:** only explicitly allowed tables and functions pass. A list of forbidden names is a finding.
- **One statement, read-only:** multiple statements, comments that hide parts, `UNION` into tables outside the list, and statements that write or alter the schema are rejected. The validator parses the same string that will be executed, and execution uses a read-only connection or role, not just validation.
- **Company scoping:** the company/tenant filter is enforced by the validator or the connection, never requested from the model. Every allowed table that is multi-company is only read with that filter.
- **Fail closed:** a validator error, a parse that cannot finish or an ambiguous result rejects the query. Never "when in doubt, run it".
- **Placeholders and real identifiers:** the model sees only placeholders; the real scoping identifier is substituted after validation finishes, never before (and never handed to the model; see `review-sensitive-data`).
- **Hostile validator tests:** each rule above has a test that passes an input violating it (a table outside the list, a second statement, `UNION`, a disallowed function, a missing company filter) and confirms the rejection.

### Output

```
## Data access safety review

- path:L## — <query construction> interpolates <source of the risky value> directly.
  Fix: parameterize via <the project's existing query mechanism, if visible in the file>.
```

If you are not sure a value is really untrusted, say so as a question instead of a finding. Omit the output section if nothing is found.

### Tests with hostile input

For each finding, and for each parameterized query that receives external text, check whether any test passes a hostile string through that query, and say so in one line. Suggested payloads (pick what fits the query; do not list them all): `"'"`, `"\""`, `"'; DROP TABLE t; --"`, `"%"` and `"_"` for `LIKE`, `"\\"`, a null byte, a look-alike Unicode quote (`'’'`), the empty string and a very long string. The assertion is that the text is stored or matched literally, or rejected with the unit's documented error, and that the table is still intact afterwards.

- The fix for a finding needs a regression test using the payload that exploited it (`write-regression-test`).
- A parameterized query without such a test is `[info]`, never a finding, and is not a defect; the human decides whether it is wanted. Static SQL with no external input needs none.
