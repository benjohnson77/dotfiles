# GitHub CLI Configuration

## Setup
The gh config directory is symlinked to `~/.config/gh`

## Authentication
`hosts.yml` contains authentication tokens and is excluded from git via `.gitignore`

To authenticate on a new machine:
```bash
gh auth login
```

This will regenerate `hosts.yml` with your authentication tokens.
