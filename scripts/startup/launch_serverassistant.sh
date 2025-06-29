#!/bin/bash

# Simple ServerAssistant Launcher
# This script directly launches ServerAssistant without setup

echo "=========================================="
echo "    ServerAssistant Launcher"
echo "=========================================="
echo ""

# Check if virtual environment exists
if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Check if serverassistant.py exists
if [ -f "serverassistant.py" ]; then
    echo "Launching ServerAssistant..."
    python3 serverassistant.py
else
    echo "Error: serverassistant.py not found!"
    exit 1
fi 