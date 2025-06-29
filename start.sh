#!/bin/bash
# Simple startup script for ServerAssistant
# This script just launches the application without environment setup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if virtual environment exists and activate it
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "Virtual environment activated"
fi

# Launch ServerAssistant
if [ -f "serverassistant.py" ]; then
    python serverassistant.py "$@"
elif [ -f "src/main.py" ]; then
    python src/main.py "$@"
else
    echo "ERROR: No ServerAssistant found!"
    exit 1
fi 