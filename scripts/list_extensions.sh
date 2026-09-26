#!/usr/bin/env bash
# list_extensions.sh — Compact index of existing extension methods, so the reviewer can spot
# PR code that re-implements one (ARCH-S1 / ARCH-S6 / MAP-1).
# Usage: list_extensions.sh <owner> <repo> <base_ref> [module ...]
#   module = folder name under src/Modules touched by the PR (e.g. Configuration Dashboard).
# Always includes the shared layers: src/BuildingBlocks*, src/Shared*, Modules.Domain, Modules.Infrastructure.
# Output: one line per file — "<area>/<File>.cs: Method(this Type), Method2(this Type2)".
# Kept compact on purpose (names only) — use search_code.sh to open a candidate. Reads the local clone only.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWNER="${1:?owner required}"
REPO="${2:?repo required}"
BASE_REF="${3:?base ref required (PR base_ref)}"
shift 3

source "$SCRIPT_DIR/resolve_repo.sh" || exit 2

paths=(
  'src/BuildingBlocks*' 'src/Shared*'
  'src/Modules/Modules.Domain' 'src/Modules/Modules.Infrastructure'
)
for module in "$@"; do
  paths+=("src/Modules/${module}")
done

echo "===EXTENSIONS=== (ref: ${SEARCH_REF})"
git -C "$REPO_ROOT" grep -n -I -E 'public static [^=(]+\(\s*this ' "$SEARCH_REF" -- "${paths[@]}" \
    ':(exclude)*/Migrations/*' ':(exclude)*/bin/*' ':(exclude)*/obj/*' \
  | sed -E "s#^${SEARCH_REF}:##" \
  | sed -E 's#^src/(Modules/)?([^/]+)/.*/([^/]+\.cs):[0-9]+:.*public static [^(]* ([A-Za-z_][A-Za-z0-9_]*(<[^(]*>)?)\(\s*this\s+([^,)]*[^ ,)])\s+[A-Za-z_][A-Za-z0-9_]*\s*[,)].*#\2/\3\t\4(\6)#' \
  | grep -P '\t' \
  | grep -vP '\t\w+\((WebApplication|IServiceCollection|IEndpointRouteBuilder|RouteGroupBuilder|IApplicationBuilder|ModelBuilder|IHostBuilder|WebApplicationBuilder)\)$' \
  | awk -F'\t' '{ if ($1 != file) { if (file != "") print file ": " methods; file = $1; methods = $2 } else { methods = methods ", " $2 } }
                END { if (file != "") print file ": " methods }'
