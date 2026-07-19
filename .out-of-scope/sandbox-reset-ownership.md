# Warden-Side Ownership of the Sandbox Reset

Warden does not own, host, or trigger the `warden-sandbox` reset-and-seed
machinery. No reset workflow, no thin trigger, no seed data lives in this
repo.

## Why this is out of scope

The sandbox already carries a complete, self-contained reset
(`warden-sandbox/.github/workflows/reset.yml`, seed source of truth in
`.github/seed/`) that runs on its own `github.token` via
`workflow_dispatch`. Moving any of it here was rejected because:

- **It adds a credential dependency for nothing.** Sandbox self-reset needs
  no cross-repo auth; a warden-side owner or trigger would put warden's
  sandbox PAT on the critical path of every reset.
- **It splits fixtures from the workflow that seeds them.** The seed data
  is versioned next to `reset.yml`, so a fixture change is one sandbox PR.
  Warden-side ownership would make every fixture change a cross-repo push.
- **The convenience gained is one CLI flag.** Kicking a reset from
  anywhere is already `gh workflow run reset.yml -R <owner>/warden-sandbox`
  (or the sandbox's Actions tab). A thin warden-side trigger was considered
  and deferred until a demonstrated need.

The full decision record is ADR
[`docs/adr/0003-sandbox-reset-is-sandbox-owned.md`](../docs/adr/0003-sandbox-reset-is-sandbox-owned.md).
If a real workflow need for a warden-side trigger emerges, reconsider by
deleting this file and re-triaging.

## Prior requests

- #11 — "Consider owning the warden-sandbox reset/seed workflow from this repo"
