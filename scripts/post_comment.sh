#!/usr/bin/env bash
# post_comment.sh — Post ONE summary comment on the PR (no inline anchoring).
# Usage: post_comment.sh <owner> <repo> <pr_number> <body_markdown_path>
# Requires: GITHUB_TOKEN (classic PAT, `repo` scope), curl, jq.
# Use this when the reviewer wants a single summary comment instead of inline threads.
set -euo pipefail

# Auto-load token from saved file if not in environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load_token.sh"

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
NUM="${3:?pr number required}"
BODY_FILE="${4:?path to markdown body required}"

[[ -f "$BODY_FILE" ]] || { echo "ERROR: file not found: $BODY_FILE" >&2; exit 1; }
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is not set. Run install.bat to set up your token." >&2; exit 1
fi

URL="https://api.github.com/repos/${OWNER}/${REPO}/issues/${NUM}/comments"
payload=$(jq -Rs '{ body: . }' < "$BODY_FILE")

resp=$(curl -s -w '\n%{http_code}' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -X POST "$URL" -d "$payload")

body=$(echo "$resp" | sed '$d')
code=$(echo "$resp" | tail -n1)

if [[ "$code" == "201" ]]; then
  echo "OK: comment posted → $(echo "$body" | jq -r '.html_url')"
else
  echo "ERROR: GitHub returned HTTP ${code}" >&2
  echo "$body" | jq -r '.message // .' >&2
  exit 1
fi
