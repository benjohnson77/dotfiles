#!/usr/bin/env bash
# Sync .env files to/from Bitwarden secure notes (gzip+base64 encoded).
#
# Files are registered in a manifest — one "<note-name>  <local-path>" per line
# (default: ~/.dotfiles/env-sync.manifest, override with $ENV_SYNC_MANIFEST).
# On a new workstation, `env-sync.sh pull` recreates every registered .env.
#
# Commands:
#   env-sync.sh pull                 # download ALL manifest entries
#   env-sync.sh push                 # upload   ALL manifest entries
#   env-sync.sh load <name> [path]   # download one note  -> path (path from manifest if omitted)
#   env-sync.sh save <name> [path]   # upload   one file  -> note (path from manifest if omitted)
#   env-sync.sh list                 # show the manifest
#
# Auth: uses `bw`. Non-interactive when BW_CLIENTID/BW_CLIENTSECRET (+ optional
# BW_PASSWORD) are set — loaded from the macOS Keychain by ~/.zshrc; else prompts.
# Notes are gzip+base64-encoded so files stay byte-identical and fit Bitwarden's
# 10,000-char note limit. See SECRETS.md.
set -euo pipefail

MANIFEST="${ENV_SYNC_MANIFEST:-$HOME/.dotfiles/env-sync.manifest}"

expand_path() { eval printf '%s' "$1"; }   # expand ~ and $VARS in manifest paths

read_manifest() {
  [ -f "$MANIFEST" ] || { echo "No manifest at $MANIFEST" >&2; exit 1; }
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST"
}

lookup_path() { read_manifest | awk -v n="$1" '$1==n {print $2; exit}'; }

bw_auth() {
  command -v bw >/dev/null 2>&1 || { echo "bw not found — brew install bitwarden-cli" >&2; exit 1; }
  if ! bw login --check >/dev/null 2>&1; then
    if [ -n "${BW_CLIENTID:-}" ] && [ -n "${BW_CLIENTSECRET:-}" ]; then
      bw login --apikey >/dev/null || { echo "API-key login failed." >&2; exit 1; }
    else
      echo "Not logged in. Run: bw login  (or set BW_CLIENTID/BW_CLIENTSECRET)" >&2; exit 1
    fi
  fi
  if [ -z "${BW_SESSION:-}" ]; then
    if [ -n "${BW_PASSWORD:-}" ]; then
      BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)" || { echo "Unlock failed." >&2; exit 1; }
    else
      BW_SESSION="$(bw unlock --raw)" || { echo "Unlock failed." >&2; exit 1; }
    fi
    export BW_SESSION
  fi
  bw sync >/dev/null 2>&1 || true
}

do_save() {
  local name="$1" file; file="$(expand_path "${2:-$(lookup_path "$1")}")"
  [ -n "$file" ] || { echo "  ! no path for '$name' (not in manifest)" >&2; return 1; }
  [ -f "$file" ] || { echo "  ! skip '$name': no file at $file" >&2; return 1; }
  export _EN_NAME="$name"
  export _EN_NOTES="$(gzip -c "$file" | openssl base64 -A)"
  local id
  id="$(bw list items --search "$name" | python3 -c 'import sys,json,os;items=json.load(sys.stdin);print(next((i["id"] for i in items if i.get("name")==os.environ["_EN_NAME"]),""))')"
  if [ -n "$id" ]; then
    bw get item "$id" | python3 -c 'import sys,json,os;d=json.load(sys.stdin);d["notes"]=os.environ["_EN_NOTES"];print(json.dumps(d))' | bw encode | bw edit item "$id" >/dev/null
    echo "  ^ updated '$name'  ($file)"
  else
    bw get template item | python3 -c 'import sys,json,os;d=json.load(sys.stdin);d.update({"type":2,"name":os.environ["_EN_NAME"],"notes":os.environ["_EN_NOTES"],"secureNote":{"type":0},"login":None,"card":None,"identity":None});print(json.dumps(d))' | bw encode | bw create item >/dev/null
    echo "  ^ created '$name'  ($file)"
  fi
}

do_load() {
  local name="$1" file; file="$(expand_path "${2:-$(lookup_path "$1")}")"
  [ -n "$file" ] || { echo "  ! no path for '$name' (not in manifest)" >&2; return 1; }
  umask 077; mkdir -p "$(dirname "$file")"
  bw get notes "$name" | openssl base64 -d -A | gunzip > "$file"
  chmod 600 "$file"
  echo "  v wrote '$name' -> $file"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  list) read_manifest ;;
  save) bw_auth; do_save "$@" ;;
  load) bw_auth; do_load "$@" ;;
  push) bw_auth; while read -r name path _; do do_save "$name" "$path" || true; done < <(read_manifest) ;;
  pull) bw_auth; while read -r name path _; do do_load "$name" "$path" || true; done < <(read_manifest) ;;
  *) echo "usage: env-sync.sh {pull|push|load <name> [path]|save <name> [path]|list}" >&2; exit 1 ;;
esac
