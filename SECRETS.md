# Secrets Inventory

This repo is **public**, so no secret values are stored here. Real secrets live
in gitignored files on each machine (`.env`, credential JSONs). This document is
the **inventory** — what you need to obtain and where each value goes — to
replicate the Claude and Hermes configs on a new machine.

Everything below is a *reference*, not a store of values.

---

## Claude Code (`~/.claude/`)

**No manual API key required** — Claude Code authenticates via OAuth.

| What | Where it lives | How to replicate |
|------|----------------|------------------|
| OAuth login | `~/.claude/.credentials.json` (`claudeAiOauth`: access/refresh tokens) | Run `claude` → `/login`. Regenerates the file. **Never commit it** (gitignored). |
| Settings | `~/.claude/settings.json` (`enabledPlugins`) | Not a secret, but gitignored defensively. Recreate via the CLI or copy manually. |
| Skills | `~/.claude/skills/` | ✅ Tracked in this repo (`claude/` stow package). `stow claude`. |

> If you ever switch to API-key mode instead of OAuth, set `ANTHROPIC_API_KEY`
> (from <https://console.anthropic.com>) in your shell env.

---

## Hermes (`~/.hermes/`)

Real secrets stay local. On a new machine:

```bash
cp ~/.dotfiles/hermes/.hermes/env.example ~/.hermes/.env   # then fill in values
stow hermes                                                 # links SOUL.md persona
```

### 1. Environment variables → `~/.hermes/.env`

Template: [`hermes/.hermes/env.example`](hermes/.hermes/env.example)

| Variable | Purpose | Where to get it |
|----------|---------|-----------------|
| `ANTHROPIC_API_KEY` | Primary LLM | <https://console.anthropic.com> → API Keys |
| `ANTHROPIC_TOKEN` | Anthropic auth (Hermes-specific) | Hermes setup / Anthropic |
| `OPENAI_API_KEY` | OpenAI models | <https://platform.openai.com/api-keys> |
| `GEMINI_API_KEY` | Google Gemini models | <https://aistudio.google.com/apikey> |
| `XAI_API_KEY` | xAI / Grok models | <https://console.x.ai> |
| `MISTRAL_API_KEY` | Mistral models | <https://console.mistral.ai> |
| `BROWSERBASE_API_KEY` + `BROWSERBASE_PROJECT_ID` | Browser automation | <https://browserbase.com> dashboard |
| `FIGMA_API_KEY` | Figma MCP server | Figma → Settings → Security → personal access token |
| `BWS_ACCESS_TOKEN` | *(optional)* Bitwarden Secrets Manager | Bitwarden SM (only if `secrets.bitwarden.enabled: true`) |

### 2. Provider API keys in `~/.hermes/config.yaml`

`config.yaml` currently holds ~15 inline provider `api_key:` slots (openai,
gemini, xai, mistral, anthropic auxiliary, etc.). **`config.yaml` is not tracked**
(secret-laden). Options to replicate:
- Fill the keys inline again on the new machine, **or**
- Move them into `~/.hermes/.env` (above) and reference env vars, keeping
  `config.yaml` secret-free.

### 3. Credential files (gitignored — obtain & drop in place)

| File | Purpose | How to regenerate |
|------|---------|-------------------|
| `~/.hermes/auth.json` | Hermes account auth / pairing | Re-run Hermes login/pairing |
| `~/.hermes/google_client_secret.json` | Google OAuth client | Google Cloud Console → APIs & Services → Credentials → OAuth client |
| `~/.hermes/google_token.json` | Google OAuth token (Gmail/Calendar/Drive) | Auto-generated on first Google auth flow |
| `~/.hermes/readai_tokens.json` | Read.ai integration | Read.ai account/integration |

### 4. What is NOT replicated (local runtime state)

`state.db` (~64 MB), `sessions/` (~112 MB), `logs/`, `cache/`, `memories/` —
machine-specific runtime state, intentionally excluded. A fresh machine rebuilds
these on first run.

### Tracked in this repo

Only `~/.hermes/SOUL.md` (the agent persona) — via the `hermes/` stow package.

---

## Managing `.env` with Bitwarden (personal vault)

The whole `.env` is stored as a **single secure note** in your Bitwarden personal
vault, using the `bw` CLI. Two helper scripts (on PATH via the `bin/` package)
push it up and pull it down.

### One-time setup
```bash
brew install bitwarden-cli     # provides `bw` (already in the Brewfile)
bw login                       # log in to your personal vault
save-hermes-env.sh             # uploads your current ~/.hermes/.env as a note
```

### On a new machine
```bash
bw login
load-hermes-env.sh             # pulls the note down to a 0600 ~/.hermes/.env
```

Both scripts run `bw unlock` automatically if the vault is locked (prompts for
your master password), then `bw sync`. The note name defaults to `hermes-env`
(override with `HERMES_BW_ITEM`).

| Script | Direction |
|--------|-----------|
| `save-hermes-env.sh [file]` | `~/.hermes/.env` → Bitwarden note (create or update) |
| `load-hermes-env.sh [file]` | Bitwarden note → `~/.hermes/.env` (0600) |

The scripts contain **no secrets** — only `bw` commands. The `.env` never enters
this repo.

> The `.env` is stored **gzip+base64-encoded** in the note. This keeps the file
> byte-for-byte identical and fits Bitwarden's 10,000-char note limit (a 17 KB
> `.env` compresses to ~7.4 KB). Encoding/decoding is automatic in the scripts.

### Unattended login (for `./setup-macos.sh`)

By default `bw login` / `bw unlock` are interactive. To let the bootstrap pull
secrets without prompts, store a **personal API key** (Vault → Settings →
Security → Keys → "API Key") and — optionally — your master password in the
Keychain. `~/.zshrc` exports them; the scripts pick them up automatically:

```bash
security add-generic-password -U -s bw-clientid     -a "$USER" -w '<client_id>'
security add-generic-password -U -s bw-clientsecret -a "$USER" -w '<client_secret>'
# optional — enables fully unattended unlock (trade-off: master password at rest)
security add-generic-password -U -s bw-password     -a "$USER" -w '<master-password>'
```

Without `bw-password`, login is automatic but unlock still prompts once — a good
balance. `./setup-macos.sh` runs `load-hermes-env.sh` as its final step.

### Alternative: Bitwarden Secrets Manager (`bws`) for Hermes-native

Hermes can also pull individual keys from **Bitwarden Secrets Manager** at runtime
(`secrets.bitwarden.enabled: true` + `project_id` in `~/.hermes/config.yaml`). That
path uses the separate `bws` CLI and a machine access token — `~/.zshrc` loads
`BWS_ACCESS_TOKEN` / `HERMES_BWS_PROJECT_ID` from the macOS Keychain if you set them:
```bash
security add-generic-password -U -s bws-access-token -a "$USER" -w '<machine-token>'
security add-generic-password -U -s bws-project-id  -a "$USER" -w '<project-id>'
```
Use whichever fits: single-note (`bw`) for a portable file, or per-key (`bws`) for
Hermes' built-in runtime injection.
