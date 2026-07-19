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

## Done when

`docs/agents/issue-tracker.md` carries both a ready gate and a
frontier definition. Report the gate's value and that the warden is
ready to summon with `/warden:patrol`.
