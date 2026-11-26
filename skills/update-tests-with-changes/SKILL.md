---
name: update-tests-with-changes
description: Decide what to do with the tests when this project's production behavior changes. Use whenever a code change breaks an existing test or introduces behavior that has no test yet.
---

# Update tests with the changes

- if an existing test fails because the behavior changed on purpose, adjust the test to reflect the new behavior; no need to ask first;
- add the new tests the change requires, following the structure and rules in `AGENTS.md` (Testing);
- if a test fails and there is not enough evidence to say whether the implementation or the test's expectation is wrong, investigate the contract and the related flows first; if the ambiguity remains, ask the user which behavior should prevail before changing the code or the test, so a wrong implementation is never masked by a test adjustment.
