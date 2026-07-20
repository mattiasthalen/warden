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
- prompt — two parts, exactly:
  1. `/warden:patrol <owner>/<repo> [args]` — the resolved repo from
     step 1 plus the pass-through args, so every round carries the
     summons' args
  2. the fallback clause, verbatim on the next line:
     `If /warden:patrol is an unknown command, read the newest
     ~/.claude/plugins/cache/*/warden/*/skills/patrol/SKILL.md and
     follow it for <owner>/<repo> with the same args.`
     Fresh sessions can hit a registry race — a plugin installed by
     a SessionStart hook registers its slash commands only for the
     *next* session, and rounds are always first sessions in fresh
     containers. The fallback lets the round find the skill on disk
     and walk anyway.
- `create_new_session_on_fire: true` — each round in a fresh session
- `run_once_at`: now + 1 minute

## 4. Finish the Routine in the claude.ai UI — required

`create_trigger` cannot attach a repository source or MCP
connectors — Routines it creates fire sessions with **no repo
checkout** and no connector tools. Until the maintainer finishes the
Routine in the claude.ai UI, every round fires into an empty session
with nothing to walk.

So the summons' final report must carry this as an explicit
**required step**, not an optional note: open the Routine in the
claude.ai Routines UI ("Edit routine"), attach the repository
(the "Select a repository" field will be empty), and attach any
connectors the rounds need — before the first round fires, or
re-arm after.

Then report: the warden is hired, name the Routine, say when the
first round fires, and state the finish-in-UI step above. Stand-down
is the same Routine deleted — from any session, or the claude.ai
Routines UI.
