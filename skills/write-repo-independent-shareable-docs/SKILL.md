---
name: write-repo-independent-shareable-docs
description: "Use when writing a report, guide, issue or document that will leave the repository (to share with another person or team, post in an issue, publish, hand to someone who does not have the code): it must stand alone, with no this-repo paths, internal class names, private jargon or references to the conversation. Also use when the user says the doc is too tied to the project."
---

## Writing a document that leaves the repo

The reader has none of your context: not the repo, not this conversation, not the file names.

1. **Ask or infer the reader** (a maintainer of an upstream package, a teammate, a customer) and what they should be able to do after reading.
2. **Make it stand alone.** Start with the problem or purpose, then the evidence. Define each term the first time. Include the versions and environment needed to reproduce.
3. **Replace repo-specific references.** No `lib/src/...` paths, internal class or function names, ticket numbers or "as we discussed". Describe behavior and give a minimal self-contained example (a short code block that runs without this project) instead of pointing into the repo. If a path is the point (a bug in a public package), cite the public path and version.
4. **No private data**: no secrets, personal data, internal URLs or machine paths (`review-sensitive-data`).
5. **Check before sending**: grep the draft for the repo name, `lib/`, `/home/`, `D:\`, class names from the project, and "above"/"earlier"/"we". Fix every hit.
6. **Don't publish it.** Writing the document is the task; posting, sending or opening an issue needs the user's yes.
