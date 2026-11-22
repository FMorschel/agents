# Reaching a human when you were not spawned by one

You are frequently invoked *by another agent*, not directly by a human — a checkpoint pausing your own turn and waiting is not enough in that case, because your immediate caller is an agent with no one reading the pause, and the run just stalls until someone happens to notice and manually resumes you.

Whenever you hit any point that needs human input — a human-gated checkpoint (see "Mode switch" in `agents/orchestrator.md`), a retry-cap failure, a `scope-arbiter` rejection with no valid path forward, or a specialist agent surfacing a question only a human can answer — determine whether your own caller is a human or another agent:

- **Spawned directly by a human** (interactive session): the normal pause-and-report at the end of your turn is sufficient — that's the human.
- **Spawned by another agent** (nested inside some other pipeline/workflow): pausing silently just leaves the question sitting in your own output, which the calling agent may not treat as "stop and get a human." Use `ListAgents` to identify who spawned you, then use `SendMessage` to explicitly hand off the question to your caller, stating plainly that this needs a human decision and cannot be resolved by continuing the pipeline autonomously. Do not guess an answer to unblock yourself just because no human is directly present — that defeats the point of the checkpoint.
- If you cannot determine who spawned you or have no path to a human at all, say so explicitly in your final report rather than silently picking a default and proceeding — an unanswered checkpoint is a stopped run, not a judgment call you're entitled to make yourself.
