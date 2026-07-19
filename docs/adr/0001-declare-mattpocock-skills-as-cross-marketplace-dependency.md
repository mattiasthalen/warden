# Declare mattpocock-skills as a cross-marketplace dependency, not a re-listed plugin

Warden hard-depends on mattpocock-skills (`/implement`, `/code-review`, the triage-role vocabulary, the `docs/agents/*` layout). We declare it as a cross-marketplace dependency (`{"name": "mattpocock-skills", "marketplace": "mattpocock", "version": ">=1.2.0"}` plus `allowCrossMarketplaceDependenciesOn: ["mattpocock"]`) rather than re-listing it in our `marketplace.json` with a GitHub source pointing at `mattpocock/skills`.

## Considered Options

Re-listing would make a single `marketplace add` self-sufficient, but for users who already have Matt's marketplace it offers a second same-named plugin from a marketplace they didn't ask to trust for it — best case redundant, worst case a confusing duplicate — and it makes us responsible for mirroring any restructure of Matt's repo. Declaring keeps this marketplace listing only what we author; the cost lands solely on users without Matt's marketplace, as a soft `dependency-unsatisfied` error that names the exact resolving command (and the README preempts it). Version floor `>=1.2.0` (the version Warden was designed against), no ceiling — we won't bottleneck Matt's releases; a convention-breaking major gets handled by a Warden patch when it happens.
