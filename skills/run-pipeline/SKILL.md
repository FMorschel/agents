---
name: run-pipeline
description: "Use when driving the `orchestrator` agent to run this repo's pipeline (agents/orchestrator.md) end-to-end. Handles the mandatory phase-boundary (PB) halt/resume: the orchestrator halts and reports after every phase instead of continuing on its own, and the correct way to resume is a *fresh* orchestrator spawn that re-reads the run's state, never a SendMessage to the halted one."
---

## Driving the orchestrator across phase boundaries

`agents/orchestrator.md` documents this fully from the orchestrator's own point of view (see its "Plan persistence and phase boundaries" and "Resumability" sections) — but that text only gets read by the orchestrator subagent itself. Whoever *spawns* the orchestrator (you, right now) doesn't see that file unless they go look for it, so the halt/resume contract is easy to miss from the caller's side. This skill is that missing caller-side half.

**The rule:** the orchestrator processes exactly one phase per invocation. When more phases remain, it stops and reports — it does **not** continue into the next phase in the same turn, and it does **not** expect to be resumed via `SendMessage`. It expects a **brand-new** `Agent` call.

### Don't just rely on the orchestrator remembering its own spec — say it in the spawn prompt

Autonomous mode by default doesn't pause at the plan-skim checkpoint (see orchestrator.md's "Mode switch" section), so a plain "do the task" spawn can sail straight past plan creation into implementing phase 1's steps in the same turn — which then makes the *next* halt land mid-phase instead of at a clean boundary. Don't count on the orchestrator inferring the stop point; state it explicitly in every spawn prompt, based on which of these two situations you're in:

- **No plan exists yet** (fresh task, or resuming before `step-planner`/its existing-feature equivalent has run — check for `specs/plans/<run-id>.md` and `agents/.run-state/<run-id>.md` first): tell it to run the pipeline *only* up through producing and persisting a plan (phases + steps), then stop itself and report — not one phase further. Prompt language: *"Run the pipeline for: \<task\>. If no plan exists yet for this run, work through task-structurer (or the fitting entry point) up through step-planner until a plan with phases and steps is written to `specs/plans/<run-id>.md`. As soon as that plan exists, stop yourself and report the plan and run-id — do not begin implementing any step or phase in this same invocation."*
- **A plan already exists** (state files present, from a prior call or a prior session): tell it to advance exactly one phase and no more. Prompt language: *"Resume run `<run-id>`: read `agents/.run-state/<run-id>.md` and `specs/plans/<run-id>.md`. Continue with exactly the next phase's steps only, then stop yourself and report — do not continue into any further phase in this same invocation."*

This mirrors what orchestrator.md already commits to doing on its own at a genuine `PB`, but a plan-just-produced moment isn't itself a hard-coded halt in autonomous mode — so for this loop to keep landing on clean, resumable boundaries, the caller has to ask for that stop explicitly rather than assume it.

### The loop

1. Check whether `specs/plans/<run-id>.md` / `agents/.run-state/<run-id>.md` already exist for this task. Spawn the `orchestrator` agent (foreground — its own spec requires this of the calls *it* makes downstream, and the same reasoning applies to you calling it: you need its report directly, not via a notification you might miss) with the appropriate prompt from the section above — the "no plan yet" template if they don't exist, the "resume, one phase only" template if they do.
2. Read its final report. It ends in one of these states:
   - **Plan just produced, no phases run yet**: it names the run-id and the plan's phases/steps, confirms `specs/plans/<run-id>.md` is written, and (per your spawn instruction above) stops there rather than starting phase 1.
   - **Phase boundary (`PB` yes)**: it names the run-id, states which phase just finished, confirms `specs/plans/<run-id>.md` and `agents/.run-state/<run-id>.md` are up to date, and says it's halting pending re-invocation.
   - **Human-gated checkpoint**: it's paused for a decision (post-contract, pre-merge, existing-feature checkpoint, or a lighter requirements/plan skim). Handle the checkpoint, then continue the *same* agent via `SendMessage` if it's still alive — this is not a phase boundary and does not need a fresh spawn.
   - **Retry-cap failure / unresolvable `scope-arbiter` rejection**: the run stopped for a reason a human needs to resolve. Not a phase boundary either.
   - **Done (`O`)**: nothing to resume.
3. On a "plan just produced" or phase-boundary halt: spawn a **new** `orchestrator` agent (not the same one, not via `SendMessage`) using the "resume, one phase only" template, naming the run-id. Do not restate the original task from scratch — the point of the run-state file is that the new instance reconstructs context from it, not from you re-deriving the plan.
4. Repeat step 2–3 until the report says `O` (done) or stops for a reason that needs a human.

### Why not just SendMessage the same agent

`SendMessage` keeps the halted orchestrator's in-memory context alive and just nudges it forward. That works for the lighter human-gated checkpoints (step 2's second bullet), but a genuine `PB` halt is a *structural* stop, not a pause waiting for input — the orchestrator's own spec is written assuming the next phase is picked up by "a fresh orchestrator invocation... yours after a restart, or another one told to pick this up," reading the two state files. Resuming the live agent instead skips the very re-derivation-from-disk step the design relies on to survive a killed process, and blurs the phase boundary the spec treats as a hard gate.
