#!/bin/bash

# Quick Start Script for ServerAssistant (Organized Version)

echo "=========================================="
echo "    ServerAssistant Quick Start"
echo "         (Organized Version)"
echo "=========================================="
echo ""

# Check if src directory exists
if [ ! -d "src" ]; then
    echo "ERROR: Organized structure not found!"
    echo "Please ensure the src/ directory exists."
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "Virtual environment created and dependencies installed."
else
    echo "Virtual environment found."
    source venv/bin/activate
fi

# Check if dependencies are installed
echo "Checking dependencies..."
python3 -c "import tabulate, psutil, colorama" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing missing dependencies..."
    pip install tabulate psutil colorama
fi

echo ""
echo "Starting ServerAssistant (Organized Version)..."
echo ""

# Try to run the organized version
if [ -f "src/main.py" ]; then
    python3 src/main.py
elif [ -f "run_organized.py" ]; then
    python3 run_organized.py
elif [ -f "serverassistant.py" ]; then
    python3 serverassistant.py
else
    echo "ERROR: No ServerAssistant found!"
    exit 1
fi 