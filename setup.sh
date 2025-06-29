#!/bin/bash
# Wrapper script for scripts/startup/setup.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/scripts/startup/setup.sh" "$@" 