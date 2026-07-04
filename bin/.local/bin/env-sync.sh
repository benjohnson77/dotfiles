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
#   env-sync.sh status               # show in-sync / differs for every entry
#   env-sync.sh diff <name>          # show local-vs-remote diff for one entry
#   env-sync.sh load <name> [path]   # download one note  -> path (path from manifest if omitted)
#   env-sync.sh save <name> [path]   # upload   one file  -> note (path from manifest if omitted)
#   env-sync.sh list                 # show the manifest
#
# Safety: pull/load never overwrite a differing local file without first copying
# it to $ENV_SYNC_BACKUPS (~/.cache/env-sync); push/save likewise stash a copy of
# a differing remote note before replacing it. Nothing is silently clobbered.
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

BACKUP_DIR="${ENV_SYNC_BACKUPS:-$HOME/.cache/env-sync}"
_ts() { date +%Y%m%d-%H%M%S; }

# Decode a remote note to stdout (empty if the note doesn't exist / isn't ours)
remote_decode() { bw get notes "$1" 2>/dev/null | openssl base64 -d -A 2>/dev/null | gunzip 2>/dev/null || true; }

backup() {  # backup <file> <label>  -> copies file into BACKUP_DIR as <label>.<ts>.bak
  local src="$1" label="$2" dst
  dst="$BACKUP_DIR/${label}.$(_ts).bak"
  mkdir -p "$BACKUP_DIR"; cp "$src" "$dst"; chmod 600 "$dst" 2>/dev/null || true
  echo "$dst"
}

do_save() {
  local name="$1" file; file="$(expand_path "${2:-$(lookup_path "$1")}")"
  [ -n "$file" ] || { echo "  ! no path for '$name' (not in manifest)" >&2; return 1; }
  [ -f "$file" ] || { echo "  ! skip '$name': no file at $file" >&2; return 1; }

  # Guard: if the remote note differs from what we're about to overwrite, stash a
  # local copy of the remote first so a push can't silently destroy remote-only data.
  local rtmp; rtmp="$(mktemp)"; remote_decode "$name" > "$rtmp"
  if [ -s "$rtmp" ] && ! cmp -s "$file" "$rtmp"; then
    local bak; bak="$(backup "$rtmp" "${name}.remote")"
    echo "  ! remote '$name' differed from local — saved remote copy to $bak" >&2
  fi
  rm -f "$rtmp"

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
  local tmp; tmp="$(mktemp)"
  remote_decode "$name" > "$tmp"
  [ -s "$tmp" ] || { echo "  ! no remote note '$name'" >&2; rm -f "$tmp"; return 1; }

  # Guard: if the local file differs from the incoming remote, back it up first so
  # a pull can't silently destroy local-only edits.
  if [ -f "$file" ] && ! cmp -s "$file" "$tmp"; then
    local bak; bak="$(backup "$file" "${name}.local")"
    echo "  ! local '$file' differed — backed up to $bak" >&2
  fi
  mv "$tmp" "$file"; chmod 600 "$file"
  echo "  v wrote '$name' -> $file"
}

do_diff() {
  local name="$1" file; file="$(expand_path "${2:-$(lookup_path "$1")}")"
  local tmp; tmp="$(mktemp)"; remote_decode "$name" > "$tmp"
  if [ ! -s "$tmp" ]; then echo "  $name: no remote note"; rm -f "$tmp"; return; fi
  if [ ! -f "$file" ]; then echo "  $name: no local file ($file)"; rm -f "$tmp"; return; fi
  if cmp -s "$file" "$tmp"; then
    echo "  = $name: in sync"
  else
    echo "  ~ $name: differs  (< local $file   > remote)"
    diff "$file" "$tmp" || true
  fi
  rm -f "$tmp"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  list)   read_manifest ;;
  save)   bw_auth; do_save "$@" ;;
  load)   bw_auth; do_load "$@" ;;
  diff)   bw_auth; do_diff "$@" ;;
  push)   bw_auth; while read -r name path _; do do_save "$name" "$path" || true; done < <(read_manifest) ;;
  pull)   bw_auth; while read -r name path _; do do_load "$name" "$path" || true; done < <(read_manifest) ;;
  status) bw_auth; while read -r name path _; do do_diff "$name" "$path" || true; done < <(read_manifest) ;;
  *) echo "usage: env-sync.sh {pull|push|status|diff <name>|load <name> [path]|save <name> [path]|list}" >&2; exit 1 ;;
esac
