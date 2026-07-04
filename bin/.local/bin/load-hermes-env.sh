#!/usr/bin/env bash
# Regenerate ~/.hermes/.env from Bitwarden Secrets Manager.
#
# Pulls every secret in your Bitwarden Secrets Manager project and writes them
# to a 0600 .env file. No secret values live in this repo — only this script,
# which just calls `bws`.
#
# Prerequisites (see ../../SECRETS.md):
#   - bws CLI installed  (Hermes auto-installs it; or `cargo install bws`,
#     or grab a release from github.com/bitwarden/sdk-sm)
#   - BWS_ACCESS_TOKEN and HERMES_BWS_PROJECT_ID in the environment
#     (loaded from the macOS Keychain by ~/.zshrc)
#
# Usage:
#   load-hermes-env.sh                # writes ~/.hermes/.env
#   load-hermes-env.sh /path/to/.env  # writes a custom path
set -euo pipefail

: "${BWS_ACCESS_TOKEN:?BWS_ACCESS_TOKEN not set — add it to the Keychain (see SECRETS.md)}"
: "${HERMES_BWS_PROJECT_ID:?HERMES_BWS_PROJECT_ID not set — add it to the Keychain (see SECRETS.md)}"

ENV_FILE="${1:-$HOME/.hermes/.env}"

if ! command -v bws >/dev/null 2>&1; then
  echo "bws CLI not found. Install it (Hermes can auto-install), then re-run." >&2
  exit 1
fi

umask 077
bws secret list "$HERMES_BWS_PROJECT_ID" --output env > "$ENV_FILE"
chmod 600 "$ENV_FILE"
echo "Wrote $(grep -cE '^[A-Za-z_]' "$ENV_FILE" || true) secrets to $ENV_FILE"
