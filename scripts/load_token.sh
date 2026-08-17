#!/usr/bin/env bash
# load_token.sh — Load GitHub token from saved file if not already in environment.
# Sourced by fetch_pr.sh, post_review.sh, post_comment.sh.

_TOKEN_FILE="$HOME/.claude/.github_token"

if [[ -z "${GITHUB_TOKEN:-}" ]] && [[ -f "$_TOKEN_FILE" ]]; then
  GITHUB_TOKEN="$(tr -d '\r\n' < "$_TOKEN_FILE")"
  export GITHUB_TOKEN
fi

unset _TOKEN_FILE
