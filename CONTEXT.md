# Warden

A Claude Code plugin marketplace hosting the `warden` plugin — a ticket-patrolling agent that automates the seam between triage and implementation.

## Language

**Warden**:
The patrolling agent identity — one session per round, walking rounds until stood down.
_Avoid_: bot, daemon, watcher

**Round**:
One full pass of the warden's duties, run in its own session: claim & dispatch, babysit, arm the next round.
_Avoid_: iteration, cycle, loop

**Patrol**:
The warden's lifetime from summons to stand-down; a sequence of rounds carrying the summons' args throughout. Between rounds the patrol exists only as its armed Routine.
_Avoid_: session, run

**Arm**:
Create the one-shot Routine that fires the next round in a fresh session — the patrol's only between-round state.
_Avoid_: schedule, wake, loop

**Ticket**:
Anything carrying the agent-ready triage role: an issue, or an external PR when the tracker treats PRs as a request surface.
_Avoid_: task, item

**Frontier**:
The set of open, agent-ready, unblocked, unclaimed tickets: mapped tickets first (each map in map order, maps oldest-first), then unmapped tickets oldest-first. A ticket appearing on multiple maps counts once, at its first position.
_Avoid_: queue, backlog

**Claim**:
Assigning a ticket to the warden — the write that removes it from the frontier.
_Avoid_: lock, reserve, work-in-progress label

**Change request (CR)**:
The forge's draft PR/MR opened by the warden for a claimed issue ticket.
_Avoid_: patch, changeset

**In-flight**:
A warden-owned open draft CR whose ticket is claimed and carries neither the needs-info nor ready-for-human role — the babysit set.
_Avoid_: pending, active

**Ready gate**:
Repo policy for what a green CR earns: `human` (label + notify, stay draft), `ready` (mark ready for review), or `merge` (warden merges).
_Avoid_: auto-merge, merge policy

**Fix attempt**:
One dispatched repair of a red CR, counted via `patrol: fix attempt N` comments; capped at 2 before the ticket goes back to human triage via needs-info.
_Avoid_: retry
