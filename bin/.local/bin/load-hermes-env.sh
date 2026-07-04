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

# Log in: use personal API key if provided (non-interactive), else require prior `bw login`
if ! bw login --check >/dev/null 2>&1; then
  if [ -n "${BW_CLIENTID:-}" ] && [ -n "${BW_CLIENTSECRET:-}" ]; then
    bw login --apikey >/dev/null || { echo "API-key login failed." >&2; exit 1; }
  else
    echo "Not logged in. Run: bw login  (or set BW_CLIENTID/BW_CLIENTSECRET)" >&2
    exit 1
  fi
fi

# Unlock: use master password from env if provided, else prompt
if [ -z "${BW_SESSION:-}" ]; then
  if [ -n "${BW_PASSWORD:-}" ]; then
    BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)" || { echo "Unlock failed." >&2; exit 1; }
  else
    BW_SESSION="$(bw unlock --raw)" || { echo "Unlock failed." >&2; exit 1; }
  fi
  export BW_SESSION
fi

bw sync >/dev/null 2>&1 || true

umask 077
mkdir -p "$(dirname "$ENV_FILE")"
# The note holds the .env gzip+base64-encoded (see save-hermes-env.sh); reverse it.
bw get notes "$ITEM" | openssl base64 -d -A | gunzip > "$ENV_FILE"
chmod 600 "$ENV_FILE"
echo "Wrote $(grep -cE '^[A-Za-z_]' "$ENV_FILE" || true) vars to $ENV_FILE (from Bitwarden note '$ITEM')"
