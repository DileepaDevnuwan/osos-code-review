#!/usr/bin/env bash
# fetch_review_comments.sh — Fetch previous reviews and inline comments on a PR.
# Usage: fetch_review_comments.sh <owner> <repo> <pr_number>
# Requires: GITHUB_TOKEN (classic PAT with `repo` scope), curl, jq.
#
# Used during re-review to check whether the PR owner addressed earlier feedback.
# Emits two sections:
#   ===REVIEWS===          JSON array of reviews (state, body, author)
#   ===REVIEW_COMMENTS===  JSON array of inline comments (file, line, body, thread)
set -euo pipefail

# Auto-load token from saved file if not in environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load_token.sh"

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
NUM="${3:?pr number required}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is not set. Run install.bat to set up your token." >&2
  exit 1
fi

API="https://api.github.com/repos/${OWNER}/${REPO}/pulls/${NUM}"
AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28")

# --- Fail fast on auth/404 ---
code=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$API")
if [[ "$code" == "401" ]]; then
  echo "ERROR: Bad or expired token (HTTP 401). Run install.bat to update your token." >&2
  exit 1
elif [[ "$code" == "404" ]]; then
  echo "ERROR: PR not found or token lacks access to ${OWNER}/${REPO}#${NUM} (HTTP 404)." >&2
  exit 1
elif [[ "$code" != "200" ]]; then
  echo "ERROR: GitHub returned HTTP ${code}." >&2
  exit 1
fi

echo "===REVIEWS==="
# All reviews submitted on this PR (approved, changes_requested, commented, dismissed)
{
  for page in 1 2 3; do
    curl -s "${AUTH[@]}" -H "Accept: application/vnd.github+json" \
      "${API}/reviews?per_page=100&page=${page}"
  done
} | jq -s 'add | [.[] | {
  id, user: .user.login, state, body, submitted_at
}]'

echo "===REVIEW_COMMENTS==="
# Inline review comments — only fields needed for re-review (no diff_hunk, it's in the full diff)
{
  for page in 1 2 3; do
    curl -s "${AUTH[@]}" -H "Accept: application/vnd.github+json" \
      "${API}/comments?per_page=100&page=${page}"
  done
} | jq -s 'add | [.[] | {
  id, user: .user.login, path, line, body, in_reply_to_id
}]'
