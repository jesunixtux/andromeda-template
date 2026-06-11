#!/usr/bin/env bash

set -e

ANDROMEDA_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROMEDA_ROOT="$(cd "$ANDROMEDA_SCRIPT_DIR/.." && pwd)"
export ANDROMEDA_ROOT

. "$ANDROMEDA_ROOT/core/env.sh"
. "$ANDROMEDA_ROOT/core/utils.sh"
. "$ANDROMEDA_ROOT/core/config.sh"
. "$ANDROMEDA_ROOT/core/logs.sh"
. "$ANDROMEDA_ROOT/core/sdk.sh"

andromeda_ensure_dirs
andromeda_config_load
andromeda_install_sdk "$@"
