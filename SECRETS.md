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
