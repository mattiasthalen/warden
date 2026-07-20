---
name: patrol
description: Summon the warden — walk rounds over the frontier until told to stand down. `/warden:patrol once` walks one round.
disable-model-invocation: true
---

# Warden

The warden walks **rounds**, each in a fresh session. Between rounds
the patrol exists only as one one-shot Routine — canonical name
`warden:patrol <owner>/<repo>`, prompt `/warden:patrol <args>` (the
args this patrol was summoned with), created with
`create_new_session_on_fire` + `run_once_at`. Rescheduling that one
Routine is both arming and a dead-man's switch:

- **Round start** — pre-flight the standing rules: each round is a
  fresh session, so first check `.claude/settings.json` exists and
  allows the claude-code-remote trigger tools. If missing, tell the
  user to run `warden:setup` step 4 — then still attempt the re-arm
  (the dead-man fire is the safety net), never stall silently on a
  permission prompt. Then push its fire time to +90 min. A fired
  one-shot
  Routine disables itself; setting a new `run_once_at` re-arms that
  same Routine — never create a second. A crash mid-round leaves
  this safety fire armed; the patrol self-heals with at worst one
  90-min gap.
- **Round end** — pull it in to cadence: **+1 min** if work completed
  or the frontier is non-empty, **+10 min** if only waiting on CI,
  **+30 min** if dry. Hygiene: delete any *other* stale patrol
  Routine for this repo seen on the page already fetched — keeps
  future dup-checks to page one; never list again just to clean.

Cloud only: Routines don't exist in the local CLI, so patrol
currently requires Claude cloud sessions.

The frontier script (below) needs `GH_TOKEN`: the patrol
environment mints it via its setup script — the same mechanism
that installs dependencies — and network policy must allow
`api.github.com`. A plain repo-scoped token works. If the
environment rewrites git remotes (proxies, mirrors) so the origin
URL no longer names GitHub, set `GH_REPO=<owner>/<repo>` — the
script prefers it over the remote.

Rounds must be zero-prompt: `warden:setup` commits standing allow
rules to the repo's `.claude/settings.json` covering the Routine
tools, the frontier script, git operations, and the tracker/forge
writes. At summons, check the rules are present (the file exists and
allows the claude-code-remote trigger tools); if missing, say so and
point at `warden:setup` step 4 instead of letting a later round
stall silently on a permission prompt. The same check re-runs as the
round-start pre-flight above — summons catches it early, the
pre-flight catches environments that drifted since.

Summoning: refuse if an **armed** patrol Routine for this repo
already exists (enabled, fire pending) — one patrol per repo.
Dup-check cheaply: `list_triggers` with `limit` ≤10, stop at the
first enabled match of the canonical name; page via `cursor` only
while no match and a `next_cursor` exists. Ignore disabled or
`ended_reason`-set Routines entirely — fired one-shots are noise,
not dups. Residual cost stays bounded at ~limit × payload size; the
real fix is a name filter/projection upstream in `list_triggers`. A
disabled one that just fired is not a duplicate: it is this patrol's
own Routine delivering the round you are in — adopt it and walk.
`/warden:patrol once`: walk one round, touch no Routine, report.
`/warden:patrol merge`: override the ready gate to `merge` for this
patrol only — the flag in issue-tracker.md is untouched. Args combine.
Stand down when the user says so: delete the named Routine. That
works from any session — and the claude.ai Routines UI works too.

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
- `ready` — flip the draft to ready for review (that flip is the
  whole action); a human still merges.
- `merge` — flip the draft to ready for review, then merge, as two
  ordered steps — a merge attempted on a draft fails at the forge.
  Then delete branch, remove worktree, close the linked ticket if
  the merge didn't. If the forge refuses the merge (e.g. branch
  protection requires review), fall back to `human` behavior and
  note the refusal on the CR. Cleanup is non-fatal: if branch
  deletion is refused, try once, note it briefly on the CR, and
  move on — never retry through alternate APIs in the same round. A
  failed worktree removal is likewise noted and skipped. Merge and
  ticket-close outcomes never depend on cleanup succeeding — the
  ticket still closes.

## 1. Claim & dispatch

First, release orphans: a ticket claimed by the warden with **no
open CR** was orphaned by a dead round (healthy rounds open the
draft CR before dispatching) — release the claim back to the
frontier. No timestamps, no timeouts; the orphan is inferred, not
remembered.

Then query the frontier: run
`${CLAUDE_PLUGIN_ROOT}/scripts/frontier.sh` from the repo root —
one Bash result, one JSON line per ticket (number, title, labels,
assignees, open-blocker count), already partitioned and ordered
per issue-tracker.md's frontier rules. For each, in frontier
order:

**Issue ticket** — there's a spec; build it:
1. Claim it (the claim removes it from the frontier — claim first)
2. Worktree on a fresh branch `<bug|feat>/issue-<id>` (type from the
   ticket's labels; default `feat`)
3. Push; open a draft change request linking the ticket
4. Dispatch a subagent: /implement this ticket in that worktree —
   and wait for it

**External-PR ticket** — there's a diff; judge it, never touch it:
1. Claim it
2. Dispatch a subagent: /code-review the PR against its merge-base
   (Spec axis = the PR's stated intent / linked issue) — and wait
   for it
3. Post the review; mechanical fixes go as suggestion blocks the
   contributor can apply. Apply the needs-info role — waiting on
   reporter. PR tickets never enter the babysit set.

Dispatch is **synchronous**: the round waits for every subagent it
dispatched (implement, code-review, fix) before arming and ending.
Rounds are strictly serialized — a fresh round never sees a running
subagent, so every CR it encounters is fully pushed and babysit
judges CI/forge state alone.

## 2. Babysit in-flight change requests

In-flight = my open draft change requests whose ticket is claimed by
me and not carrying the needs-info or ready-for-human roles. For each:

- **CI green** (or the forge has no CI) → apply the ready gate.
  Under `human`, the ready-for-human label means notified: labeled
  CRs are the human's queue and the warden skips them until the
  human promotes. Keep the ticket's claim under every gate.
- **CI red** → read the failure. Count prior `patrol: fix attempt N`
  comments. Fewer than 2: dispatch a fix subagent into the worktree
  (and wait for it), comment `patrol: fix attempt N+1`. At 2:
  comment the diagnosis and apply the needs-info role to the ticket
  — back to human triage.
- **CI running** → leave it; the next round catches it. CI outcomes
  are only visible by checking — the forge pushes nothing — which is
  why this step runs every round.

## Context discipline

A round is cheap only if its reads are. Rules, in force every round:

- **Every tracker read is a projection** — the frontier, and any
  listing or scanning pass, goes through
  `${CLAUDE_PLUGIN_ROOT}/scripts/frontier.sh`; intermediate
  payloads stay in the pipe. Never read the frontier via GitHub
  MCP `search_issues`/`list_issues` — they return full bodies
  (~25k chars a round). MCP remains the write path (labels,
  comments, PRs) and the single-ticket body read. Read a ticket's
  body once, at claim time — never in the listing.
- **One CI check per in-flight CR per round.** Never poll within a
  round; running CI is the next round's problem (step 2 already says
  so — this is the enforcement).
- **Never subscribe to CR activity** (`subscribe_pr_activity` or the
  forge's equivalent). The armed Routine already covers re-entry;
  the subscription only echoes boilerplate into context.
- **Batch independent reads into one turn** — all ticket reads
  together, all CR/CI checks together. One tool call per turn is the
  expensive way to walk a frontier.

## Round complete when

Every agent-ready frontier ticket is claimed-and-dispatched (and its
subagent finished), every in-flight change request is gated,
deferred, or still running — and the Routine is rescheduled to
cadence (`once`: report instead).
