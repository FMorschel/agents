# plugin_builder

## Confirmations

- Anything that would replace or delete existing things must ask for confirmation first, in the builder and in the scripts it generates (e.g. `--clean` deleting `out`, the Codex installer overwriting `~/.codex/agents/*.toml`).
- Every such confirmation needs a `--yes` / `-y` escape (`-Yes` in PowerShell) so scripts and CI can skip it.
- With nobody to ask (no terminal), a builder step fails without deleting or replacing anything; a generated installer skips that file.
- Regenerating the builder's own previous output inside `out` is not covered; it is what a build is for.
