#!/usr/bin/env bash
# post_review.sh — Post a review with inline + summary comments.
# Usage: post_review.sh <owner> <repo> <pr_number> <review_json_path>
# Requires: GITHUB_TOKEN (classic PAT, `repo` scope), curl, jq.
#
# review_json_path must contain a GitHub "create review" payload, e.g.:
# {
#   "event": "COMMENT",
#   "body": "### Automated review against OSOS standards\n...summary...",
#   "comments": [
#     { "path": "Modules/Lnd/.../PathwayService.cs", "line": 42, "side": "RIGHT",
#       "body": "🟡 [naming] Private field should be camelCase without underscore..." }
#   ]
# }
# NOTE: inline comments must target lines that appear in the PR diff, RIGHT side.
# event=REQUEST_CHANGES blocks the PR from merging; event=APPROVE approves it.
set -euo pipefail

# Auto-load token from saved file if not in environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load_token.sh"

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
NUM="${3:?pr number required}"
PAYLOAD="${4:?path to review json required}"

[[ -f "$PAYLOAD" ]] || { echo "ERROR: file not found: $PAYLOAD" >&2; exit 1; }
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is not set. Run install.bat to set up your token." >&2; exit 1
fi
jq empty "$PAYLOAD" 2>/dev/null || { echo "ERROR: $PAYLOAD is not valid JSON." >&2; exit 1; }

URL="https://api.github.com/repos/${OWNER}/${REPO}/pulls/${NUM}/reviews"
resp=$(curl -s -w '\n%{http_code}' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -X POST "$URL" -d @"$PAYLOAD")

body=$(echo "$resp" | sed '$d')
code=$(echo "$resp" | tail -n1)

if [[ "$code" == "200" || "$code" == "201" ]]; then
  echo "OK: review posted → $(echo "$body" | jq -r '.html_url')"
else
  echo "ERROR: GitHub returned HTTP ${code}" >&2
  echo "$body" | jq -r '.message // .' >&2
  # Most common cause: a comment targets a line not present in the diff.
  echo "$body" | jq -r '.errors[]? | "  - \(.resource): \(.message // .field)"' >&2 || true
  exit 1
fi
