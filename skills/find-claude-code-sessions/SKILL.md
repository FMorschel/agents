---
name: find-claude-code-sessions
description: Use when you need to locate, identify, or resume a local Claude Code session by its title, ID, project, or conversation content.
metadata:
  scope: environment
  system: Claude Code
---

# Finding Claude Code sessions

Claude Code stores local conversations as JSONL transcript files under `projects` in its configuration directory. On Windows, the default is `%USERPROFILE%\.claude\projects`; if `CLAUDE_CONFIG_DIR` is set, use that directory instead of `%USERPROFILE%\.claude`. On macOS and Linux, the default is `~/.claude/projects`.

## Find a session by title

1. Determine the configuration directory and transcript folder:

   ```powershell
   $configDir = if ($env:CLAUDE_CONFIG_DIR) {
     $env:CLAUDE_CONFIG_DIR
   } else {
     Join-Path $HOME '.claude'
   }
   $projectsDir = Join-Path $configDir 'projects'
   ```

2. Search JSONL files for the exact title without printing conversation contents:

   ```powershell
   $title = 'Exact session title'
   $files = rg -l -F --glob '*.jsonl' -- $title $projectsDir
   ```

   Each path identifies a transcript. Folders under `projects` represent projects, and their names may encode the original project path.

3. Confirm the title in the file's `ai-title` metadata, especially if the search found multiple results. Extract only the title and ID, not conversation messages:

   ```powershell
   foreach ($file in $files) {
     $record = Get-Content -LiteralPath $file |
       ForEach-Object { $_ | ConvertFrom-Json } |
       Where-Object { $_.type -eq 'ai-title' -and $_.aiTitle -eq $title } |
       Select-Object -First 1
     if ($record) {
       [PSCustomObject]@{
         Title = $record.aiTitle
         SessionId = $record.sessionId
         Transcript = $file
       }
     }
   }
   ```

   Do not dump the full transcript; it may contain private information.

4. If `rg` is unavailable, use `Get-ChildItem -Recurse -Filter *.jsonl` with `Select-String -SimpleMatch -List` to list only matching file paths.

If no file matches, check whether `CLAUDE_CONFIG_DIR` points elsewhere and whether the requested text is the session title rather than a phrase mentioned in the conversation. `history.jsonl` stores prompt history; it is not a substitute for the transcripts under `projects`.

## Resume the session

In a terminal, change to the project directory where the session started and pass its ID to the resume command:

```powershell
Set-Location 'C:\path\to\project'
claude -r <session-id>
```

See the official [CLI reference](https://code.claude.com/docs/en/cli-reference) for current options and the [Claude Code directory guide](https://code.claude.com/docs/en/claude-directory) for configuration and `CLAUDE_CONFIG_DIR`.
