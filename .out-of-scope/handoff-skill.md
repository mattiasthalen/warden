# A `warden:handoff` skill

Warden does not ship a dedicated `warden:handoff` skill for multi-session
work handoffs.

## Why this is out of scope

Handoff was considered as a first-class skill when sandbox fixture tickets
referenced `warden:handoff`, but the maintainer's decision is that it isn't
a thing any more — the fixtures are stale, not the plugin.

The practical reason: handoffs already work without a skill. In two separate
patrol verification rounds (warden-sandbox sessions `d9c010c5` and
`eda67fb6`), a two-part ticket was handed off between sessions via a
structured handoff comment on the ticket itself — a state snapshot plus a
next-step spec that the successor session resumed from. Both handoffs
completed successfully. The ticket comment thread is the natural, durable,
already-authenticated place for that state; a skill would only wrap what a
plain comment already does, and would add a third skill surface (`patrol`,
`setup`, `handoff`) for the plugin to version and users to discover, with no
new capability behind it.

Sandbox fixtures that mention `warden:handoff` should be treated as stale
references and ignored — they are not to be "fixed" as part of this
decision, and patrol sessions encountering such a reference should fall back
to the handoff-comment approach.

## Prior requests

- #33 — "Decide: add a warden:handoff skill or codify the handoff-comment convention"
