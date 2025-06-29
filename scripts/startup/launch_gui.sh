#!/bin/bash
"""
Launch script for ServerAssistant GUI
"""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "🚀 Starting ServerAssistant GUI..."
echo "📁 Project root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed or not in PATH"
    exit 1
fi

# Check if textual is installed
if ! python3 -c "import textual" 2>/dev/null; then
    echo "📦 Installing textual..."
    pip3 install textual>=0.52.0
fi

# Check if config file exists
if [ ! -f "config.json" ]; then
    echo "❌ config.json not found in project root"
    exit 1
fi

# Launch the GUI
echo "🎯 Launching GUI..."
python3 gui_main.py

echo "👋 GUI closed" 