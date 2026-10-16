---
name: report-script-progress
description: "Use whenever you write or edit a script or CLI tool (Dart especially) that does more than one step or may run longer than a moment: it must always tell the user what it is doing right now, before the slow part starts, instead of sitting silent, and offer a verbose mode where that helps. Covers what to announce, when to print it, how to keep progress separate from results, and what verbose adds."
---

## Reporting script progress

A script that goes quiet for seconds looks hung. The user can't tell "working" from "stuck" and can't tell which step is slow. Always show the current state of things, by default, without a flag.

### The rule

**Announce each step before it starts, not after it ends.** If the step takes ten seconds, the line it belongs to is already on screen for those ten seconds.

- Name the step the way the user thinks of it: `warming A`, `running A1`, `cloning repo`, `resolving dependencies`, not `step 3` or `phase_run`.
- Include position when there is a series: `running A2`, `file 14/200`. Leave the number out when there is only one (`warming A`, not `warming A1`).
- Say what is slow, not just what exists. Quick steps may share a line; anything that can take long gets its own announcement.
- Finish the step's line with its outcome when it is cheap to know: the elapsed time, a count, `ok` or `failed`.

### Format

For a step whose output is not shown, use one line that is completed when the step ends. Write the announcement, flush, do the work, then write the result:

```dart
stdout.write('$label ... ');
await stdout.flush();
// ... do the work ...
stdout.writeln(_fmt(elapsed));
```

Result: `running A1 ... 130.0 ms`. The `flush` is what makes the first half visible during the work; without it, buffered output can appear all at once at the end.

For a step whose output is shown (a `--show-output` or `--verbose` mode, or a child process printing straight to the terminal), the one-line form would be cut up by that output. Wrap the step in start and end markers on their own lines instead:

```
--- start running A1 ---
<the step's output>
--- end running A1 ---
```

The same labels appear in both forms, so switching modes doesn't change what the user is told, only how much of the step is shown.

### Verbose mode

Whenever it makes sense, also add a verbose mode: `-v` / `--verbose`. It adds the *how* on top of the *what* that progress already gives:

- the exact commands run, resolved paths and arguments, the working directory
- the child process's stdout and stderr (merged into stdout), between the start/end markers above
- counts, sizes and skipped items that the default lines leave out
- per-step timings when the default only shows a total

It makes sense when the script runs other programs, touches many files, or makes decisions the user may want to check. Skip it for a script with a single trivial step, where default progress already shows everything.

Rules for it:

- Progress lines stay the same in both modes. Verbose only inserts more lines around them; it never replaces or reorders them.
- Name it `-v` / `--verbose`, unless the script already has a more specific flag for the same thing (such as `--show-output` in `cmd_compare`); then keep that one and don't add a second flag with the same effect.
- When verbose output can change what is being measured (printing during a timed step), say so in `--help`.
- List it in `--help` with what it adds.

### Details that matter

- **Progress is on by default.** Don't hide it behind a flag. The verbose flag may add more detail (the child's output, a per-file list), never the basic "what are you doing" line.
- **Silent preparation counts.** Warmups, dependency resolution, scanning a directory, connecting: announce them too. These are the steps that usually cause "it just sat there".
- **Show everything the script runs, including runs that are not measured.** A step the user didn't see is a step they can't account for in the total time.
- **Progress is not the result.** Keep results in one clearly separated block at the end (a blank line, then the table or summary) so they can be found and copied. Progress lines come first.
- **Errors go to stderr, progress and results to stdout**, so redirecting stdout to a file still yields only the results and progress, and failures stay visible. When a step fails, finish its line (`failed`, exit code) before printing the error.
- **Stream, don't collect.** If a child process's output should be visible, let it inherit stdio (`ProcessStartMode.inheritStdio`) instead of capturing and printing it afterwards. Capturing delays the output until the step ends and changes timing.
- **Don't announce a loop's every iteration when it runs thousands of times.** Throttle: print every N items or every second, or overwrite one status line. The goal is that the user never watches a frozen screen for more than a moment, not that the screen scrolls forever.
- **Say how to see more.** When output is discarded by default, the help text should mention the flag that shows it.

### Checklist before reporting a script done

1. Run it. Does something appear within about a second of starting?
2. Is every step that can take more than a moment announced before it begins?
3. Do the announcements use the same names the user would use?
4. Is the final result visually separated from the progress lines?
5. Does `--help` describe what progress is printed and the verbose flag that adds more?
6. Would a verbose mode help here? If yes, is it there, and does it only add lines?
