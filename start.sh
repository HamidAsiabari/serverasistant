#!/bin/bash
# Wrapper script for scripts/startup/start.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/scripts/startup/start.sh" "$@" 