---
name: setup
description: Configure this repo for the warden — run Matt's skills setup, then write the ready gate and frontier that `/warden:patrol` reads.
disable-model-invocation: true
---

# Warden Setup

The warden patrols config laid down in two layers: the base layer
(issue tracker, triage labels, domain docs) belongs to Matt's setup;
the warden layer adds the **ready gate** and the **frontier** on top.
Both warden writes land in `docs/agents/issue-tracker.md`.

## 1. Base layer

When `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md`
already exist, the base layer is done — go straight to step 2.
Otherwise run `/mattpocock-skills:setup-matt-pocock-skills` and
complete its interview first.

## 2. Ready gate — ask

One question, recommended answer first:

> What should a green change request earn? (recommended: **human**)
>
> - `human` — label the draft CR ready-for-human, notify, leave it
>   draft; you review, promote, merge
> - `ready` — mark the CR ready for review; you still merge
> - `merge` — the warden merges, deletes the branch, closes the ticket

Record the answer as a `## Ready gate` section in
`docs/agents/issue-tracker.md`:

```markdown
## Ready gate

**Ready gate: human.** _(What the warden does when a change request
goes green: `human` = label ready-for-human, leave draft; `ready` =
mark ready for review; `merge` = merge, delete branch, close ticket.
`/warden:patrol` reads this flag.)_
```

## 3. Frontier — write silently

When `issue-tracker.md` already defines a frontier query (wayfinder
repos do), keep it as the single source of truth. Otherwise append:

```markdown
## Frontier

The frontier is every open ticket carrying the agent-ready role,
unblocked and unclaimed (no assignee), oldest first. `/warden:patrol`
claims from it.
```

Every other flag keeps the value the base layer wrote — including
"PRs as a request surface".

## 4. Standing authorization — write

Rounds run in fresh, unattended sessions (ADR 0002): any permission
prompt stalls the round until a human answers, which defeats AFK
patrol. Setup therefore establishes durable, repo-scoped allow rules
covering exactly what the patrol skill instructs a round to do — no
blanket bypass modes.

Merge these rules into the repo's `.claude/settings.json` under
`permissions.allow` (create the file if absent; keep any existing
entries):

```json
{
  "permissions": {
    "allow": [
      "mcp__claude-code-remote__list_triggers",
      "mcp__claude-code-remote__create_trigger",
      "mcp__claude-code-remote__update_trigger",
      "mcp__claude-code-remote__delete_trigger",
      "mcp__github__get_me",
      "mcp__github__issue_read",
      "mcp__github__issue_write",
      "mcp__github__add_issue_comment",
      "mcp__github__sub_issue_write",
      "mcp__github__list_pull_requests",
      "mcp__github__pull_request_read",
      "mcp__github__create_pull_request",
      "mcp__github__update_pull_request",
      "mcp__github__merge_pull_request",
      "mcp__github__pull_request_review_write",
      "mcp__github__add_comment_to_pending_review",
      "Bash(*/scripts/frontier.sh*)",
      "Bash(git fetch*)",
      "Bash(git pull*)",
      "Bash(git branch*)",
      "Bash(git checkout*)",
      "Bash(git worktree*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(git push*)",
      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git remote*)"
    ]
  }
}
```

The Routine tools ride the claude-code-remote MCP server (the
"schedule" prompts: dup-check at summons, reschedule at round start
and end, delete at stand-down). The `mcp__github__*` rules are the
tracker/forge write path (labels, comments, draft CRs — and merge,
used only when the ready gate is `merge`). The Bash rules cover the
frontier script and the worktree/branch/push cycle. Where the merge
gate is never used, the human may drop `merge_pull_request`.

Commit the file — allow rules only work AFK if they survive fresh
sessions, which is the whole point of putting them in the repo's
project settings rather than a local override.

## Done when

`docs/agents/issue-tracker.md` carries both a ready gate and a
frontier definition, and `.claude/settings.json` carries the standing
allow rules. Report the gate's value and that the warden is ready to
summon with `/warden:patrol`.
