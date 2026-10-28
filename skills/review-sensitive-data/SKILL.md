---
name: review-sensitive-data
description: "Use when the user asks whether code or a design handles passwords, tokens, API keys, secrets or personal data safely (leaks into logs, plaintext storage, hardcoded secrets, exception messages), or whether a feature's requirements and contract protect such data. Two modes: design-time (FRs and contract) and implementation-time (code). Report-only. Not for SQL injection (`sql safety agent`). Used by `sensitive data agent` in the pipeline."
---

## Reviewing sensitive-data handling

Check that sensitive data (passwords, auth tokens, API keys, PII) is handled safely, at any layer. SQL injection at the DataSource layer is `sql safety agent`'s concern, not this one. Pick the mode by the artifact you were given.

### Design-time mode (FRs and emerging contract)

Run only when the FRs mention credentials, tokens, secrets or personal data. If none appear, say `No sensitive data in scope` and stop; do not look for data that might become sensitive later.

- Does an FR involve a password, token, secret or PII field? If so, does an NFR or the contract say how it is protected (hashed, encrypted in transit/at rest, redacted from logs)?
- Could the contract's error/exception design leak a value (an exception message carrying a raw password or token)?
- Does the data type imply a retention/deletion expectation that no NFR states?

Findings route to `task structurer` (missing NFR) or `api designer` (contract does not protect the field). Do not fix the contract yourself.

### Implementation-time mode (code)

Scan for:

- Hardcoded secrets, API keys or credentials in source.
- Sensitive fields passed to `print`/`log`/`debugPrint`, or included in a `toString()` that could reach a log.
- Passwords stored or compared in plaintext (look for a hashing call on both the write and the comparison path).
- Sensitive data in insecure local storage (a raw token in `SharedPreferences` where secure storage exists and is unused) or written to disk unencrypted.
- Sensitive values in a stack trace or exception message that could reach a log or crash report.

Never call something a leak unless you can point to the actual field or value at risk and its exposure path. "This touches user data" is not a finding.

### Exposure vs. hardening

- **Exposure**: a concrete sensitive value this code handles can leak. Report it. At implementation time in the pipeline it is blocking.
- **Hardening**: the code is fine as requested but could be "more secure" (extra encryption, retention policies, rate limits, audit logs, stricter validation) and nobody asked. Do not route it as a fix or missing NFR. List it under `Unrequested extras` as a question for the human.

### Output

```
## Sensitive data review — <design-time | implementation-time>

- <location/FR/contract symbol> — <what's exposed or unspecified>
  Risk: <one line>
  Fix / missing spec: <one line — task structurer / api designer if design-time, step planner if implementation-time; in a standalone review, just the fix>

### Unrequested extras (→ human)
- <hardening idea> — request didn't mention it — necessary?
```

Omit the section if nothing is found.
