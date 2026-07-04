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

# Key-level merge: local file is the structural base (keeps comments/order),
# remote values are overlaid. Matching values pass through; remote-only keys are
# appended; conflicting keys are resolved by policy (ask | local | remote).
do_merge() {
  local name="$1"; shift || true
  local policy="ask" push=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --prefer-local)  policy=local ;;
      --prefer-remote) policy=remote ;;
      --ask)           policy=ask ;;
      --no-push)       push=0 ;;
    esac; shift
  done
  local file; file="$(expand_path "$(lookup_path "$name")")"
  [ -n "$file" ] || { echo "  ! no path for '$name' (not in manifest)" >&2; return 1; }
  local rtmp merged; rtmp="$(mktemp)"; merged="$(mktemp)"
  remote_decode "$name" > "$rtmp"
  if [ ! -s "$rtmp" ]; then
    echo "  ! no remote note '$name' — nothing to merge (use: env-sync.sh save $name)" >&2
    rm -f "$rtmp" "$merged"; return 1
  fi
  [ -f "$file" ] || : > "$file"

  if EN_POLICY="$policy" python3 - "$file" "$rtmp" "$policy" > "$merged" <<'PY'
import sys, re
local_path, remote_path, policy = sys.argv[1], sys.argv[2], sys.argv[3]
kv = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)=(.*)$')
def parse(p):
    d = {}
    with open(p) as f:
        for line in f:
            mo = kv.match(line.rstrip('\n'))
            if mo: d[mo.group(1)] = mo.group(2)
    return d
remote = parse(remote_path)
_tty = None
def ask(k, lv, rv):
    global _tty
    if _tty is None:
        try: _tty = open('/dev/tty')
        except Exception: return 'local'
    sys.stderr.write(f"CONFLICT {k}:\n  (l)ocal : {lv}\n  (r)emote: {rv}\nkeep local / take remote? [l/r] ")
    sys.stderr.flush()
    return 'remote' if _tty.readline().strip().lower().startswith('r') else 'local'
out, seen, nconf = [], set(), 0
with open(local_path) as f:
    for line in f:
        raw = line.rstrip('\n')
        mo = kv.match(raw)
        if not mo:
            out.append(raw); continue
        k, lv = mo.group(1), mo.group(2); seen.add(k)
        if k in remote and remote[k] != lv:
            nconf += 1
            choice = policy if policy in ('local', 'remote') else ask(k, lv, remote[k])
            out.append(raw if choice == 'local' else f"{k}={remote[k]}")
            sys.stderr.write(f"  * {k}: {'kept local' if choice=='local' else 'took remote'}\n")
        else:
            out.append(raw)
extras = [k for k in remote if k not in seen]
if extras:
    out.append(""); out.append("# --- added from remote (env-sync merge) ---")
    for k in extras: out.append(f"{k}={remote[k]}")
    sys.stderr.write(f"  + added {len(extras)} remote-only key(s): {', '.join(extras)}\n")
sys.stdout.write("\n".join(out) + "\n")
sys.stderr.write(f"  merged: {nconf} conflict(s), {len(extras)} addition(s)\n")
PY
  then
    if ! cmp -s "$file" "$merged"; then backup "$file" "${name}.local" >/dev/null; fi
    umask 077; mkdir -p "$(dirname "$file")"; cp "$merged" "$file"; chmod 600 "$file"
    echo "  = merged -> $file"
    [ "$push" -eq 1 ] && do_save "$name" "$file"
  else
    echo "  ! merge failed for '$name'" >&2
  fi
  rm -f "$rtmp" "$merged"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  list)   read_manifest ;;
  save)   bw_auth; do_save "$@" ;;
  load)   bw_auth; do_load "$@" ;;
  diff)   bw_auth; do_diff "$@" ;;
  merge)  bw_auth; do_merge "$@" ;;
  push)   bw_auth; while read -r name path _; do do_save "$name" "$path" || true; done < <(read_manifest) ;;
  pull)   bw_auth; while read -r name path _; do do_load "$name" "$path" || true; done < <(read_manifest) ;;
  status) bw_auth; while read -r name path _; do do_diff "$name" "$path" || true; done < <(read_manifest) ;;
  sync)   bw_auth; while read -r name path _; do do_merge "$name" "$@" || true; done < <(read_manifest) ;;
  *) echo "usage: env-sync.sh {pull|push|sync|status|diff <name>|merge <name> [--prefer-local|--prefer-remote|--ask|--no-push]|load <name> [path]|save <name> [path]|list}" >&2; exit 1 ;;
esac
