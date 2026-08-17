#!/usr/bin/env bash
# fetch_pr.sh — Pull everything needed to review a PR.
# Usage: fetch_pr.sh <owner> <repo> <pr_number>
# Requires: GITHUB_TOKEN env var (classic PAT with `repo` scope), curl, jq.
#
# Emits three clearly delimited sections to stdout so the reviewer model can parse them:
#   ===META===   JSON: title, body, author, state, head sha/ref, base ref, counts
#   ===DIFF===   Raw unified diff of the whole PR
#   ===FILES===  JSON array: [{ path, status, additions, deletions, patch }]
set -euo pipefail

# Auto-load token from saved file if not in environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load_token.sh"

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
NUM="${3:?pr number required}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "ERROR: GITHUB_TOKEN is not set." >&2
  echo "  Run install.bat from the osos-code-review repo to set up your token," >&2
  echo "  or export it manually:  export GITHUB_TOKEN=ghp_xxx" >&2
  exit 1
fi

API="https://api.github.com/repos/${OWNER}/${REPO}/pulls/${NUM}"
AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}" -H "X-GitHub-Api-Version: 2022-11-28")

# --- Fail fast with a clear message on auth/404 problems ---
code=$(curl -s -o /dev/null -w '%{http_code}' "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$API")
if [[ "$code" == "404" ]]; then
  echo "ERROR: PR not found or token lacks access to ${OWNER}/${REPO}#${NUM} (HTTP 404)." >&2
  echo "Check the token has 'repo' scope and you are a collaborator on the repo." >&2
  exit 1
elif [[ "$code" == "401" ]]; then
  echo "ERROR: Bad or expired token (HTTP 401). Run install.bat to update your token." >&2
  exit 1
elif [[ "$code" != "200" ]]; then
  echo "ERROR: GitHub returned HTTP ${code} for ${API}." >&2
  exit 1
fi

meta=$(curl -s "${AUTH[@]}" -H "Accept: application/vnd.github+json" "$API")

echo "===META==="
echo "$meta" | jq '{
  title, body, state, draft,
  author: .user.login,
  head_sha: .head.sha, head_ref: .head.ref, base_ref: .base.ref,
  additions, deletions, changed_files, commits
}'

echo "===DIFF==="
curl -s "${AUTH[@]}" -H "Accept: application/vnd.github.v3.diff" "$API"

echo "===FILES==="
# Paginate up to 300 files (3 pages of 100).
{
  for page in 1 2 3; do
    curl -s "${AUTH[@]}" -H "Accept: application/vnd.github+json" \
      "${API}/files?per_page=100&page=${page}"
  done
} | jq -s 'add | map({ path: .filename, status, additions, deletions, patch })'
