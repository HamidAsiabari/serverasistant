#!/bin/bash
# Script to install Python dependencies on Ubuntu server

set -e

echo "Installing Python dependencies..."

# Check if virtual environment exists
if [[ ! -d "venv" ]]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

echo "Dependencies installed successfully!"
echo ""
echo "To activate the virtual environment in the future:"
echo "  source venv/bin/activate"
echo ""
echo "To run the test:"
echo "  python3 test_installation.py" 