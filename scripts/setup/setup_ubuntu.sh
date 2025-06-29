#!/bin/bash
# Comprehensive setup script for Ubuntu server
# This script handles virtual environment creation and dependency installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}Ubuntu Setup Script${NC}"
echo -e "${CYAN}==========================================${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    print_error "Please run as a regular user with sudo privileges"
    exit 1
fi

# Get current user
CURRENT_USER=$(whoami)
print_status "Current user: $CURRENT_USER"

# Check if python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
    print_status "Installing python3-venv..."
    sudo apt update
    sudo apt install -y python3-venv python3-pip
fi

# Remove existing venv if it exists and is owned by root
if [[ -d "venv" ]]; then
    VENV_OWNER=$(stat -c '%U' venv)
    if [[ "$VENV_OWNER" == "root" ]]; then
        print_warning "Removing root-owned virtual environment..."
        sudo rm -rf venv
    fi
fi

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv

# Ensure proper ownership
sudo chown -R $CURRENT_USER:$CURRENT_USER venv

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Verify activation
if [[ "$VIRTUAL_ENV" != "" ]]; then
    print_success "Virtual environment activated: $VIRTUAL_ENV"
else
    print_error "Failed to activate virtual environment"
    exit 1
fi

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
print_status "Installing Python dependencies..."
pip install -r requirements.txt

print_success "Setup completed successfully!"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "1. Activate the virtual environment:"
echo "   source venv/bin/activate"
echo ""
echo "2. Run the test:"
echo "   python3 test_installation_simple.py"
echo ""
echo "3. Or run the comprehensive test:"
echo "   ./test_ubuntu22.sh"
echo ""
echo -e "${YELLOW}Note: Always activate the virtual environment before running Python scripts${NC}" 