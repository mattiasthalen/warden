---
name: summon
description: Hire the warden — validate the post and arm the patrol's first round. `/warden:summon [<owner>/<repo>] [args]`; done in seconds, walks no round here.
disable-model-invocation: true
---

# Warden Summons

The summons is the hiring act: validate the post, arm the patrol's
one Routine, report. It walks no round — the first round fires about
a minute later in its own fresh session, and this session is done in
seconds. The summons is the Routine's **single creation site**:
patrol rounds only reschedule the Routine the summons created, never
create one.

The summons touches only Routines. It never reads the frontier,
never writes the tracker, and never needs `GH_TOKEN` — all of that
belongs to rounds. Cloud only: Routines don't exist in the local
CLI, so summoning requires a Claude cloud session.

## 1. Resolve the repo

Resolve the target repo once, now — the resolution is baked into the
Routine and every future round inherits it:

- An explicit `<owner>/<repo>` argument wins.
- Otherwise infer `<owner>/<repo>` from the current clone's origin
  remote (`git remote get-url origin`).
- No argument and no clone → refuse: say the summons needs either a
  `<owner>/<repo>` argument or a checked-out clone to name its post.

All other arguments (`merge`, etc.) pass through verbatim into the
patrol prompt; `once` is patrol-only and has no meaning at summons.

## 2. Validate the post

Two checks, in order; refuse on either — a refused summons changes
nothing.

**One patrol per repo.** Refuse if an armed patrol Routine for this
repo already exists — enabled, fire pending, canonical name
`warden:patrol <owner>/<repo>`. Dup-check cheaply: `list_triggers`
with `limit` ≤10, stop at the first enabled match; page via `cursor`
only while no match and a `next_cursor` exists. Disabled or
`ended_reason`-set Routines are fired one-shots — noise, not dups.

**Standing authorization.** Refuse if the repo's
`.claude/settings.json` is missing the standing allow rules — the
file must exist and allow the claude-code-remote trigger tools.
Rounds are zero-prompt by design; without the rules the first round
stalls silently on a permission prompt. Point at `warden:setup`
step 4 to lay them down, then summon again.

## 3. Arm the first round

Create the patrol's one Routine with `create_trigger`:

- name: `warden:patrol <owner>/<repo>` (the canonical name the
  dup-check and stand-down look for)
- prompt: `/warden:patrol <args>` — the pass-through args from
  step 1, so every round carries the summons' args
- `create_new_session_on_fire: true` — each round in a fresh session
- `run_once_at`: now + 1 minute

Then report: the warden is hired, name the Routine, and say when the
first round fires. Stand-down is the same Routine deleted — from any
session, or the claude.ai Routines UI.
