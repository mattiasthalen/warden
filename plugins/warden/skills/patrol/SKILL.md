---
name: patrol
description: Summon the warden — walk rounds over the frontier until told to stand down. `/warden:patrol once` walks one round.
disable-model-invocation: true
---

# Warden

The warden walks **rounds**. Each round: claim & dispatch, babysit,
arm the next round — ScheduleWakeup with the same args you were
summoned with (1800s fallback while subagents or CI are in flight;
600s when the frontier is dry and nothing's running). Subagent
completions wake the warden early on their own.
`/warden:patrol once`: walk one round, arm nothing, report.
`/warden:patrol merge`: override the ready gate to `merge` for this
patrol only — the flag in issue-tracker.md is untouched. Args combine.
Stand down when the user says so: ScheduleWakeup stop.

A **ticket** is anything carrying the agent-ready triage role: an
issue, or an external PR when the tracker treats PRs as a request
surface. Tracker operations (query, claim, label, comment) follow
`docs/agents/issue-tracker.md`; triage-role label strings follow
`docs/agents/triage-labels.md`. Change requests (draft PRs / MRs) and
CI belong to the forge the git remote points at. State lives in the
tracker and forge — never in this conversation.

The **ready gate** flag in issue-tracker.md decides what green earns:

- `human` (default) — label the draft CR with the ready-for-human
  role, push-notify with the link, leave it draft. The human reviews,
  promotes, merges.
- `ready` — mark the CR ready for review; a human still merges.
- `merge` — mark ready and merge; delete branch, remove worktree,
  close the linked ticket if the merge didn't. If the forge refuses
  (e.g. branch protection requires review), fall back to `human`
  behavior and note the refusal on the CR.

## 1. Claim & dispatch

Query the frontier (per issue-tracker.md). For each, in
frontier order:

**Issue ticket** — there's a spec; build it:
1. Claim it (the claim removes it from the frontier — claim first)
2. Worktree on a fresh branch `<bug|feat>/issue-<id>` (type from the
   ticket's labels; default `feat`)
3. Push; open a draft change request linking the ticket
4. Dispatch a subagent: /implement this ticket in that worktree

**External-PR ticket** — there's a diff; judge it, never touch it:
1. Claim it
2. Dispatch a subagent: /code-review the PR against its merge-base
   (Spec axis = the PR's stated intent / linked issue)
3. Post the review; mechanical fixes go as suggestion blocks the
   contributor can apply. Apply the needs-info role — waiting on
   reporter. PR tickets never enter the babysit set.

## 2. Babysit in-flight change requests

In-flight = my open draft change requests whose ticket is claimed by
me and not carrying the needs-info or ready-for-human roles. For each:

- **CI green** (or subagent done, on a forge with no CI) → apply the
  ready gate. Under `human`, the ready-for-human label means notified:
  labeled CRs are the human's queue and the warden skips them until
  the human promotes. Keep the ticket's claim under every gate.
- **CI red** → read the failure. Count prior `patrol: fix attempt N`
  comments. Fewer than 2: dispatch a fix subagent into the worktree,
  comment `patrol: fix attempt N+1`. At 2: comment the diagnosis and
  apply the needs-info role to the ticket — back to human triage.
- **CI running** → leave it; the next round catches it. CI outcomes
  are only visible by checking — the forge pushes nothing — which is
  why this step runs every round.

## Context discipline

A round is cheap only if its reads are. Rules, in force every round:

- **Every tracker read is a projection** — the frontier query is
  numbers, titles, labels plus whatever fields the frontier filter
  needs; all other reads take the minimal field set too (per
  issue-tracker.md; drop bodies, comments, avatars, API URLs).
  Read a ticket's body once, at claim time — never in the listing.
- **One CI check per in-flight CR per round.** Never poll within a
  round; running CI is the next round's problem (step 2 already says
  so — this is the enforcement).
- **Never subscribe to CR activity** (`subscribe_pr_activity` or the
  forge's equivalent). Subagent completions and the armed wakeup
  already cover re-entry; the subscription only echoes boilerplate
  into context.
- **Batch independent reads into one turn** — all ticket reads
  together, all CR/CI checks together. One tool call per turn is the
  expensive way to walk a frontier.

## Round complete when

Every agent-ready frontier ticket is claimed-and-dispatched, every
in-flight change request is gated, deferred, or still running — and
the next round is armed (`once`: report instead).
