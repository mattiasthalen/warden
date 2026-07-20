# Fresh session per round, chained by a single rescheduled Routine

A patrol that loops in one session via `ScheduleWakeup` accumulates ~49k tokens per round on a ~46k baseline (measured), degrading every round after the second. Rounds are stateless by design — the skill already mandates "state lives in the tracker and forge" — so the persistent conversation buys nothing. We therefore run **each round in a fresh session**: instead of `ScheduleWakeup`, a round arms its successor with a one-shot Routine (`create_new_session_on_fire` + `run_once_at`), capping every round at baseline context forever. Cloud sessions only — Routines don't exist in the local CLI.

## Consequences

- **Synchronous dispatch.** A round waits for its subagents (implement, code-review, fix) before arming and ending. Rounds are strictly serialized, and a fresh round never sees a running subagent: every CR it encounters is fully pushed, so babysit judges CI/forge state alone. *Clarification:* "synchronous" means a **round-end barrier** — the round waits for all its subagents before arming and ending — not that subagents are serialized against each other; within a round, independent subagents may run concurrently.
- **Orphan claims are inferred, not remembered.** Healthy rounds open the draft CR before dispatching, so at round start "claimed by warden + no open CR" = orphan → release the claim back to the frontier. No timestamps or timeouts.
- **One Routine, rescheduled — a dead-man's switch.** The patrol owns exactly one Routine, canonically named `warden:patrol <owner>/<repo>`. Round start pushes its fire time to +90 min (safety); round end pulls it in to the real cadence: **+1 min** when work completed or the frontier is non-empty (hot chain — a DAG layer unblocks the next round almost immediately), **+10 min** when only waiting on CI, **+30 min** when dry. A crash mid-round leaves the safety fire armed, so the patrol self-heals with at worst one 90-min gap. Residual: a round outliving 90 min briefly overlaps its successor; claims make double-dispatch impossible.
- **Stand-down = delete the Routine**, from any session or the claude.ai Routines UI. Summoning refuses if a patrol Routine for the repo already exists.

## Considered Options

**Thin warden, fat round-subagent** kept early-wake semantics but still grew the dispatcher session ~2-3k/round — delaying the breach, not removing it. **Status quo + periodic `/compact`** was cheapest but risked compacting away the claim ledger the (now-fixed) design kept in conversation memory.
