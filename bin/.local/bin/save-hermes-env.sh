#!/usr/bin/env bash
# Save ~/.hermes/.env into a Bitwarden secure note (personal vault).
#
# Stores the entire .env as a single secure note. Creates the note the first
# time, updates it on subsequent runs. Pull it back with load-hermes-env.sh.
#
# Prereqs:
#   - bw CLI (brew install bitwarden-cli), logged in: `bw login`
#   - Vault unlocked: the script runs `bw unlock` if BW_SESSION isn't set
#
# Config (env vars, optional):
#   HERMES_BW_ITEM   name of the Bitwarden item  (default: hermes-env)
#
# Usage:
#   save-hermes-env.sh                # saves ~/.hermes/.env
#   save-hermes-env.sh /path/to/.env  # saves a custom path
set -euo pipefail

ITEM="${HERMES_BW_ITEM:-hermes-env}"
ENV_FILE="${1:-$HOME/.hermes/.env}"

command -v bw >/dev/null 2>&1 || { echo "bw not found — brew install bitwarden-cli" >&2; exit 1; }
[ -f "$ENV_FILE" ] || { echo "No file to save: $ENV_FILE" >&2; exit 1; }

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

# Store the file gzip+base64-encoded: keeps it byte-for-byte identical and fits
# under Bitwarden's 10,000-char note limit. load-hermes-env.sh reverses it.
export _BW_ITEM="$ITEM"
export _BW_NOTES="$(gzip -c "$ENV_FILE" | openssl base64 -A)"

# Find an existing item id with this exact name
id="$(bw list items --search "$ITEM" \
  | python3 -c 'import sys,json,os; items=json.load(sys.stdin); print(next((i["id"] for i in items if i.get("name")==os.environ["_BW_ITEM"]), ""))')"

if [ -n "$id" ]; then
  bw get item "$id" \
    | python3 -c 'import sys,json,os; d=json.load(sys.stdin); d["notes"]=os.environ["_BW_NOTES"]; print(json.dumps(d))' \
    | bw encode | bw edit item "$id" >/dev/null
  echo "Updated Bitwarden note '$ITEM' ($id) from $ENV_FILE"
else
  bw get template item \
    | python3 -c 'import sys,json,os; d=json.load(sys.stdin); d.update({"type":2,"name":os.environ["_BW_ITEM"],"notes":os.environ["_BW_NOTES"],"secureNote":{"type":0},"login":None,"card":None,"identity":None}); print(json.dumps(d))' \
    | bw encode | bw create item >/dev/null
  echo "Created Bitwarden secure note '$ITEM' from $ENV_FILE"
fi
