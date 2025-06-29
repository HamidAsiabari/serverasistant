#!/bin/bash
# Script to activate virtual environment and run commands

# Check if virtual environment exists
if [[ ! -d "venv" ]]; then
    echo "Virtual environment not found. Please run setup_ubuntu.sh first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if activation was successful
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Failed to activate virtual environment"
    exit 1
fi

echo "Virtual environment activated: $VIRTUAL_ENV"

# If arguments are provided, run them
if [[ $# -gt 0 ]]; then
    echo "Running: $@"
    exec "$@"
else
    echo "Virtual environment is now active."
    echo "You can run Python commands, or use:"
    echo "  python3 test_installation_simple.py"
    echo "  python3 main.py status"
    echo "  python3 monitor.py"
    
    # Start an interactive shell
    exec bash
fi 