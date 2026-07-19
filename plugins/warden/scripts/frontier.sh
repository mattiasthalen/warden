#!/usr/bin/env bash
# frontier.sh — print the projected frontier: open agent-ready issues,
# one compact JSON line each (number, title, labels, assignees,
# blocked_by), ordered per the frontier-query rules in
# docs/agents/issue-tracker.md — maps oldest-first with children in
# map order, then unmapped oldest-first. Tickets with an open blocker
# or an assignee are dropped. Intermediate payloads never leave the
# pipe; output is the projection only.
#
# Requires: curl, jq, git, and GH_TOKEN or GITHUB_TOKEN (a plain
# repo-scoped token works). The repo is taken from $1 or GH_REPO
# (<owner>/<repo>) if set, else inferred from the origin remote.
set -euo pipefail

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  echo "frontier.sh: GH_TOKEN or GITHUB_TOKEN must be set (a plain repo-scoped token works)" >&2
  exit 1
fi

READY_LABEL="${WARDEN_READY_LABEL:-ready-for-agent}"
MAP_LABEL="${WARDEN_MAP_LABEL:-wayfinder:map}"

# <owner>/<repo>: an explicit override ($1 or GH_REPO) wins; otherwise
# parse the origin remote URL (https, scp-like ssh, or ssh://, with
# optional userinfo).
repo="${1:-${GH_REPO:-}}"
if [ -z "$repo" ]; then
  remote="$(git remote get-url origin 2>/dev/null || true)"
  repo="$(printf '%s\n' "$remote" \
    | sed -nE 's#^((https?|ssh|git)://)?([^@/[:space:]]+@)?github\.com[:/]([^/[:space:]]+/[^/[:space:]]+)$#\4#p' \
    | sed 's/\.git$//')"
fi
if [ -z "$repo" ]; then
  echo "frontier.sh: could not infer <owner>/<repo> from the origin remote ('${remote:-none}'); set GH_REPO=<owner>/<repo> (or pass it as the first argument)" >&2
  exit 1
fi

api="https://api.github.com/repos/${repo}"

# Paginated GET of a JSON-array endpoint; prints one concatenated array.
gh_get_all() {
  local url="$1" sep='?' page=1 chunk acc="[]"
  case "$url" in *\?*) sep='&' ;; esac
  while :; do
    chunk="$(curl -sfS \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${url}${sep}per_page=100&page=${page}")"
    acc="$(jq -c --argjson a "$acc" '$a + .' <<<"$chunk")"
    [ "$(jq 'length' <<<"$chunk")" -lt 100 ] && break
    page=$((page + 1))
  done
  printf '%s' "$acc"
}

ready="$(gh_get_all "${api}/issues?state=open&labels=${READY_LABEL}")"
maps="$(gh_get_all "${api}/issues?state=open&labels=${MAP_LABEL}")"

# Walk order: maps oldest-first, each map's children in map (sub-issue)
# order. Sub-issues may be unavailable — treat that map as childless.
walk="[]"
for m in $(jq -r 'map(select(has("pull_request") | not)) | sort_by(.created_at) | .[].number' <<<"$maps"); do
  children="$(gh_get_all "${api}/issues/${m}/sub_issues" || printf '[]')"
  walk="$(jq -c --argjson a "$walk" '$a + [.[].number]' <<<"$children")"
done

jq -c --argjson walk "$walk" '
  map(select((has("pull_request") | not)
    and ((.assignees // []) | length == 0)
    and ((.issue_dependencies_summary.blocked_by // 0) == 0)))
  | . as $issues
  | ($walk | reduce .[] as $n ([]; if index($n) then . else . + [$n] end)) as $order
  | ([ $order[] as $n | $issues[] | select(.number == $n) ]
     + ([ $issues[] | select(.number as $x | ($order | index($x)) == null) ]
        | sort_by(.created_at)))
  | .[]
  | {number, title,
     labels: [.labels[].name],
     assignees: [.assignees[].login],
     blocked_by: (.issue_dependencies_summary.blocked_by // 0)}
' <<<"$ready"
