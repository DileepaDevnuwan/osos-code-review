#!/usr/bin/env bash
# resolve_repo.sh — Find a local clone of <owner>/<repo> and the git ref to search. Sourced by
# list_extensions.sh and search_code.sh; never fetches or changes the repo.
#
# Expects OWNER, REPO, BASE_REF to be set by the caller. Sets:
#   REPO_ROOT   path to the local clone (empty if none found)
#   SEARCH_REF  origin/<BASE_REF> if it exists locally, else HEAD
#
# Clone lookup order: current directory → $OSOS_REPO_PATH → path saved in ~/.osos/repo_path.

_to_unix_path() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi
}

_is_clone_of() {
  local dir="$1" url
  [[ -n "$dir" ]] || return 1
  url=$(git -C "$dir" remote get-url origin 2>/dev/null) || return 1
  [[ "$url" == *"${OWNER}/${REPO}"* || "$url" == *"${OWNER}/${REPO}.git"* ]]
}

REPO_ROOT=""
_candidates=("$PWD")
[[ -n "${OSOS_REPO_PATH:-}" ]] && _candidates+=("$(_to_unix_path "$OSOS_REPO_PATH")")
if [[ -s "$HOME/.osos/repo_path" ]]; then
  _candidates+=("$(_to_unix_path "$(tr -d '\r\n' < "$HOME/.osos/repo_path")")")
fi

for _dir in "${_candidates[@]}"; do
  if _is_clone_of "$_dir"; then
    REPO_ROOT="$(git -C "$_dir" rev-parse --show-toplevel)"
    break
  fi
done
unset _dir _candidates

if [[ -z "$REPO_ROOT" ]]; then
  echo "NO_LOCAL_CLONE: no local clone of ${OWNER}/${REPO} found — reuse check skipped." >&2
  echo "  Fix: open the clone as your working folder, or save its path once:" >&2
  echo "       mkdir -p ~/.osos && echo 'C:\\path\\to\\${REPO}' > ~/.osos/repo_path" >&2
  return 2 2>/dev/null || exit 2
fi

if git -C "$REPO_ROOT" rev-parse --verify -q "origin/${BASE_REF}" >/dev/null; then
  SEARCH_REF="origin/${BASE_REF}"
else
  SEARCH_REF="HEAD"
  echo "WARN: origin/${BASE_REF} not found locally — searching HEAD of $(git -C "$REPO_ROOT" branch --show-current). Run 'git fetch' for exact results." >&2
fi
