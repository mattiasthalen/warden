# Sandbox reset machinery is owned by warden-sandbox

The reset-and-seed workflow that returns `warden-sandbox` to its baseline lives entirely in the sandbox (`.github/workflows/reset.yml`, seed source of truth in `.github/seed/`). It runs on the workflow's own `github.token` via `workflow_dispatch`, so it needs no cross-repo credentials and the sandbox stays usable standalone. Warden holds **no reset trigger and no seed data**: resets are kicked from the sandbox's Actions tab or `gh workflow run reset.yml -R <owner>/warden-sandbox`.

## Consequences

- **No cross-repo coupling.** Warden's PAT for the sandbox is not involved in resets; nothing in this repo must stay in sync with the sandbox's fixtures.
- **Fixtures are versioned next to the workflow that seeds them**, not next to the warden behaviors they exercise. Changing a fixture means a PR to the sandbox.
- **Resetting is a manual, sandbox-side action.** If kicking resets from warden ever becomes a real workflow need, a thin trigger (`gh workflow run` against the sandbox) can be added here without moving any machinery.

## Considered Options

**Thin warden-side trigger** (a workflow here that dispatches the sandbox's `reset.yml` using the PAT) adds a secret dependency to save one CLI flag — deferred until a demonstrated need. **Full warden-side ownership** (seed data + reset logic here, pushed to the sandbox) was what a stale `ci.yml` header in the sandbox once described; it never existed, and would couple every fixture change to a cross-repo push with no gained capability.
