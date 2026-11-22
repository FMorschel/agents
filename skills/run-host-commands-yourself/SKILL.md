---
name: run-host-commands-yourself
description: "Use before you ask the user to run a command and paste its output (a process list, a log, a version check, a file listing): run it yourself instead, through Bash, a sandbox retry the user approves, or the app's terminal tools. Ask the user only when it needs their credentials, an interactive sign-in or a physical action."
---

## Run it yourself

The user should not be your hands. Before writing "please run `X` and paste the output", go down this list and stop at the first step that works.

1. **Run it in Bash**, sandboxed. Most diagnostics (`ps`, `pgrep -fa`, `ls`, `cat` of a log, `git`, `flutter --version`) work.
2. **If it failed with evidence of the sandbox** ("Operation not permitted", a denied path outside the allowed folders), retry that one command with the sandbox disabled. The permission prompt is the user's say; tell them in a line what is being run and why. Do not use this for credentials, other projects' files or anything the task does not involve.
3. **If the desktop app's terminal tools are available**, run it in the user's terminal panel (`run_in_terminal`) and read the result (`read_terminal`). Use this for commands that need the user's own shell environment (their `PATH`, a running dev server, an SSH agent). Link the tab for them.
4. **Ask the user** only when it needs something you must not have or cannot do: typing a password or token, completing a browser sign-in, plugging in a device, or approving something on another machine. Say exactly which part needs them and run everything else yourself.

### Example

- Before: "Please run `ps aux | grep atelier` and paste what you see." The user pastes, the agent wants a second command, the user pastes again.
- After: the agent runs both, reads the output, and reports the cause. If one needed approval, the user clicks one prompt.

### Rules

- Running a command yourself does not widen what you may do: read-only diagnostics freely; anything that changes the machine (kill, delete, install, write outside the project) follows the normal permission rules.
- Report what you ran and what it showed, not only your conclusion.
