# Warden

## Plugin versioning

Any change under `plugins/warden/` must bump the `version` in `plugins/warden/.claude-plugin/plugin.json` (semver, by impact) — installed plugins are cached by version, so an unbumped version never reaches users. CI enforces this on PRs.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues (`mattiasthalen/warden`), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default triage vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
