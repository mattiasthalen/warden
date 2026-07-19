# Subagent Model/Effort Pinning

The warden does not pin the model or reasoning effort of the subagents it
dispatches (implement, code-review, fix). They inherit the round session's
model and effort.

## Why this is out of scope

The proposal was to run dispatched subagents on a cheaper tier (e.g.
sonnet-5 at medium effort) to cut patrol cost. Rejected because:

- **The savings land in the wrong place.** Implement and fix are where the
  patrol's value lives. A weaker implementer produces red CI, which burns
  the two capped fix attempts and bounces the ticket back to human triage
  via needs-info — a far costlier failure than the tokens saved. Only
  code-review of external PRs is plausibly safe to downgrade, and that
  alone doesn't justify the machinery.
- **Effort can't be set at dispatch time.** Claude Code's Agent tool takes
  a per-invocation `model` parameter but no `effort` parameter. Pinning
  effort requires the plugin to ship its own agent definitions
  (`plugins/warden/agents/*.md` with `model` + `effort` frontmatter) —
  new surface area, cached-by-version, for a marginal saving.
- **A pin cascades further than it looks.** Warden's subagents internally
  run the mattpocock-skills `/implement` → `/tdd` → `/code-review` chain;
  a pinned tier applies to that whole chain, not just the outer dispatch.
- **No upstream precedent.** The mattpocock-skills stack uses subagents
  purely for context isolation and takes no stance on model or effort —
  everything inherits the session. Warden pinning would be the first
  layer in the stack to diverge, without evidence it's safe.

Anyone wanting cheaper rounds should run the whole patrol session on a
cheaper model instead — the inheritance then does the right thing
everywhere at once.

## Prior requests

- Rejected during a grilling session (2026-07-19); no tracker issue was
  filed.
