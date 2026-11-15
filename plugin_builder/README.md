# plugin_builder

Builds a plugin package from a collection of skills, agents and global
instructions, as one self-contained folder per client (Claude Code, Codex,
VS Code/Copilot, plus a vendor-neutral one). Pure Dart, no runtime
dependencies. The design and the platform research behind it are in
[`specs/cross-platform-plugin-packaging.md`](specs/cross-platform-plugin-packaging.md).

## Usage

Run from this folder (`dart pub get` once first). The source collection is any
folder with a `skills/` directory (and optionally `agents/`, a prompts file and
an MCP config); it does not have to live next to this tool.

```bash
dart run plugin_builder:build_plugin --config path/to/plugin.config.json --clean
```

A config holds the same fields as the flags (camelCase keys); paths in it
resolve against the config's directory:

```json
{
  "name": "my-plugin",
  "source": ".",
  "out": "dist",
  "version": "1.0.0",
  "prompts": "prompts/instructions.md",
  "targets": ["claude", "codex"]
}
```

Or with flags only:

```bash
dart run plugin_builder:build_plugin --source path/to/collection --name my-plugin \
    --out path/to/dist --prompts path/to/instructions.md --targets claude,codex
```

Flags are parsed with `package:args`; `--help` prints the full generated list. Unknown flags and stray arguments are errors, a repeated option keeps its last value, and list options (`--targets`, `--exclude`) take commas and accumulate across repeats.

| Flag | Meaning |
| --- | --- |
| `--config <file>` | JSON file with the same fields as the flags; flags win. Relative paths in it resolve against the file's directory |
| `--source <dir>` | Collection root; must hold `skills/` (required) |
| `--name <id>` | Plugin name, kebab-case (required) |
| `--out <dir>` | Output directory, default `dist`; one folder per target inside |
| `--targets a,b` | Harness ids to build, default all |
| `--list-targets` | Print the supported targets with a one-line description and exit |
| `--agents <dir>` | Agent definitions, default `<source>/agents`; a missing folder means no agents |
| `--prompts <file>` | Wrapped as the `global-instructions` skill |
| `--mcp <file>` | MCP server config to bundle |
| `--exclude a,b` | Skill folders to leave out, in every file-selection mode |
| `--files tracked\|unignored\|all` | Which skill files ship (default `tracked`); see below |
| `--version`, `--description`, `--author`, `--repository`, `--license` | Manifest fields (version defaults to `0.1.0`) |
| `--marketplace`, `--display-name`, `--category` | Marketplace fields (marketplace defaults to the plugin name) |
| `--clean` | Delete `--out` first |
| `--verbose` | Log every file written |

`--files` chooses which skill files ship:

| Value | Ships |
| --- | --- |
| `tracked` (default) | files git tracks |
| `unignored` | tracked files plus untracked files `.gitignore` does not ignore (package new, uncommitted work) |
| `all` | every file on disk, ignored ones included |

Outside a git checkout everything on disk ships. `--exclude` is applied on top
of all of these. Config key: `files`.

## Output

```text
dist/
├── claude/    install.sh, install.ps1, marketplace file; plugin in claude/<name>/
├── codex/     install.sh, install.ps1, marketplace file; plugin in codex/<name>/
├── vscode/    plugin in vscode/<name>/
└── portable-v1.0/  plugin in portable-v1.0/<name>/ (Agent Plugins 1.0: skills + MCP, no agents)
```

Every folder carries its own copy of the skills and only the files its client
reads. `install.sh` (POSIX `sh`) and `install.ps1` (PowerShell) register the
marketplace and install the plugin; the Codex one first copies the agent
`.toml` files into `~/.codex/agents`, because Codex loads no plugin agents.

## How it is built

```mermaid
graph LR
    S[Source collection] --> C[PluginBuilder<br/>validate + parse once]
    C --> H[Harness.emit]
    H --> O[out/id/]
```

`PluginBuilder` (`lib/src/plugin_builder.dart`) validates the source, parses the
agents and MCP config once, then for each selected harness copies the skills
and calls `emit`. Everything client-specific lives in a `Harness`:

| Harness | Writes |
| --- | --- |
| `claude` | `.claude-plugin/plugin.json`, `agents/*.md`, `.mcp.json`, marketplace, install scripts |
| `codex` | `plugin.json`, `mcp.json`, `.codex/agents/*.toml`, marketplace, install scripts |
| `vscode` | `plugin.json`, `mcp.json`, `com.github.copilot/agents/*.agent.md` |
| `portable-v1.0` | `plugin.json`, `mcp.json` (Agent Plugins 1.0; the id carries the format version) |

## MCP servers

`--mcp` takes a Claude-style config. Claude gets it as `.mcp.json` unchanged;
Codex, VS Code and portable-v1.0 get a converted `mcp.json` that follows Agent
Plugins 1.0 (required `type`, `http` becomes `streamable-http`, plugin-root
placeholders only in `args`, `env` values and `cwd`, `command` a bare name or
`./` path, no unknown fields). A server that cannot be converted (for example
`ws` or `envFile`) fails those targets with a list of problems; `claude` is
unaffected. Details in the spec.

## Adding a client

1. Create `lib/src/harnesses/<client>.dart` with a class implementing
   `Harness`: an `id` (the folder name and `--targets` value) and
   `emit(HarnessContext context)`.
2. In `emit`, write files with `context.writeInPackage`, `writeInRoot` or the
   `writeJson…` variants. Read `context.agents`, `context.mcpServers` and
   `context.options`. Add install scripts with `writeInstallScripts` and a list
   of `RunCommand`/`CopyFiles` steps if the client has an install CLI.
3. Add the class to `builtInHarnesses` in `lib/src/harnesses/built_in.dart`.
4. Add a test next to the existing ones; `test/plugin_builder_test.dart` shows a
   custom harness.

## Layout

```text
bin/build_plugin.dart          CLI: parse flags, run the builder, map errors to exit codes
lib/plugin_builder.dart        Public API
lib/src/plugin_builder.dart    Core: validation, skills, per-harness loop
lib/src/harness.dart           Harness interface and HarnessContext
lib/src/harnesses/             claude, codex, vscode, portable (portable-v1.0), built_in
lib/src/install_script.dart    InstallStep model, install.sh / install.ps1 rendering
lib/src/options.dart           Flags + config file parsing
lib/src/agent.dart             Client-neutral agent definition and parsing
lib/src/frontmatter.dart       Minimal frontmatter reader
lib/src/manifests.dart         Portable manifest and MCP builders
lib/src/skill_source.dart      Git-aware skill copying
lib/src/environment.dart       Git lookup and chmod, swappable in tests
test/                          Unit and in-memory end-to-end tests
```

Exit codes: `0` ok, `2` the source failed validation, `64` bad arguments or a
missing config/source.

## Development

```bash
dart test
dart analyze
dart format lib bin test
```

Files go through the analyzer's `ResourceProvider` (`BuildOptions` holds
`Folder`/`File` objects), so tests build into a `MemoryResourceProvider` and
assert exactly which files land where (`test/support/memory_workspace.dart`).
Git and `chmod` are the only things reached outside it, through
`BuildEnvironment`; tests replace both. One test runs against the real file
system to cover the physical provider.
