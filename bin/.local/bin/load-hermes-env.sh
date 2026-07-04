#!/usr/bin/env bash
# Pull ~/.hermes/.env from a Bitwarden secure note (personal vault).
#
# The whole .env is stored as a single secure note in your Bitwarden vault.
# This fetches that note's contents and writes them to a 0600 .env file.
# No secret values live in this repo — only this script, which calls `bw`.
#
# Prereqs:
#   - bw CLI (brew install bitwarden-cli), logged in: `bw login`
#   - Vault unlocked: the script runs `bw unlock` if BW_SESSION isn't set
#
# Config (env vars, optional):
#   HERMES_BW_ITEM   name of the Bitwarden item  (default: hermes-env)
#
# Usage:
#   load-hermes-env.sh                # writes ~/.hermes/.env
#   load-hermes-env.sh /path/to/.env  # writes a custom path
set -euo pipefail

ITEM="${HERMES_BW_ITEM:-hermes-env}"
ENV_FILE="${1:-$HOME/.hermes/.env}"

command -v bw >/dev/null 2>&1 || { echo "bw not found — brew install bitwarden-cli" >&2; exit 1; }
bw login --check >/dev/null 2>&1 || { echo "Not logged in. Run: bw login" >&2; exit 1; }

if [ -z "${BW_SESSION:-}" ]; then
  BW_SESSION="$(bw unlock --raw)" || { echo "Unlock failed." >&2; exit 1; }
  export BW_SESSION
fi

bw sync >/dev/null 2>&1 || true

umask 077
mkdir -p "$(dirname "$ENV_FILE")"
bw get notes "$ITEM" > "$ENV_FILE"
chmod 600 "$ENV_FILE"
echo "Wrote $(grep -cE '^[A-Za-z_]' "$ENV_FILE" || true) vars to $ENV_FILE (from Bitwarden note '$ITEM')"
