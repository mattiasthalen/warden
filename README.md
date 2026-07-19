![Warden](docs/assets/hero.png)

A ticket-patrolling agent for Claude Code. Summoned with `/warden:patrol`, the warden walks **rounds** over your issue tracker's frontier: it claims agent-ready tickets, dispatches implementer subagents into fresh worktrees, babysits the resulting draft change requests through CI, and applies your repo's **ready gate** when they go green — then arms the next round and waits.

Built on [Matt Pocock's engineering skills](https://github.com/mattpocock/skills): the warden dispatches `/implement` and `/code-review`, and speaks the same triage-role vocabulary and `docs/agents/*` config layout.

## Install

Warden declares `mattpocock-skills` as a cross-marketplace dependency, so add Matt's marketplace first:

```
claude plugin marketplace add mattpocock/skills
claude plugin marketplace add mattiasthalen/warden
claude plugin install warden@mattiasthalen
```

(Skipping the first step is a soft failure — the install completes and Warden reports `dependency-unsatisfied` with the exact command to run.)

## Setup

In each repo you want patrolled, run `/warden:setup`. It runs Matt's setup for the base config (issue tracker, triage labels, domain docs) if the repo doesn't have it yet, then asks one question — what a green change request earns (`human` / `ready` / `merge`) — and writes the ready gate and frontier definition into `docs/agents/issue-tracker.md`.

## Use

- `/warden:patrol` — patrol until told to stand down
- `/warden:patrol once` — walk one round, report, stop
- `/warden:patrol merge` — override the ready gate to `merge` for this patrol only

The warden only consumes tickets carrying the agent-ready triage role — `/triage` (from mattpocock-skills) produces them.

By default the warden patrols issues only. To have it also review external PRs carrying the agent-ready role, flip `PRs as a request surface` to `yes` in `docs/agents/issue-tracker.md`.

## License

MIT
