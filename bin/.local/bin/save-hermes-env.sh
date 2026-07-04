#!/usr/bin/env bash
# Convenience wrapper: save ~/.hermes/.env to Bitwarden (note "hermes-env").
# Equivalent to: env-sync.sh save hermes-env [path]
exec env-sync.sh save hermes-env "$@"
