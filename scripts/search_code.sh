#!/usr/bin/env bash
# search_code.sh — Search the base branch for code that already does what a PR adds (ARCH-S1 / ARCH-S6).
# Usage: search_code.sh <owner> <repo> <base_ref> <regex> [module ...]
#   regex  = extended regex, e.g. 'UserProfileId.*RoleId|RoleIds?\('
#   module = folders under src/Modules to search, plus the shared layers (always included).
#            Pass no module to search all of src/.
# Output: at most 40 "<path>:<line>: <code>" lines. Reads the local clone only.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWNER="${1:?owner required}"
REPO="${2:?repo required}"
BASE_REF="${3:?base ref required (PR base_ref)}"
PATTERN="${4:?regex required}"
shift 4

source "$SCRIPT_DIR/resolve_repo.sh" || exit 2

if [[ $# -eq 0 ]]; then
  paths=('src')
else
  paths=('src/BuildingBlocks*' 'src/Shared*' 'src/Modules/Modules.Domain' 'src/Modules/Modules.Infrastructure')
  for module in "$@"; do
    paths+=("src/Modules/${module}")
  done
fi

echo "===MATCHES=== (ref: ${SEARCH_REF}, pattern: ${PATTERN})"
results=$(git -C "$REPO_ROOT" grep -n -I -E -e "$PATTERN" "$SEARCH_REF" -- "${paths[@]}" \
    ':(exclude)*/Migrations/*' ':(exclude)*/bin/*' ':(exclude)*/obj/*' \
  | sed -E "s#^${SEARCH_REF}:##" | grep -E '^[^:]+\.cs:' | sed -E 's#\s+# #g' | cut -c1-220)

total=$(printf '%s\n' "$results" | grep -c . || true)
printf '%s\n' "$results" | head -n 40
if [[ "$total" -gt 40 ]]; then
  echo "... ${total} matches in total — narrow the pattern or the modules."
fi
