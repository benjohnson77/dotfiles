#!/usr/bin/env bash
# Convenience wrapper: load ~/.hermes/.env from Bitwarden (note "hermes-env").
# Equivalent to: env-sync.sh load hermes-env [path]
exec env-sync.sh load hermes-env "$@"
