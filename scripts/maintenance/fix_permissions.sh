#!/bin/bash
# Quick Permission Fix Script
# Run this script to fix permission issues with the Docker Service Manager

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}Permission Fix Script${NC}"
echo -e "${CYAN}==========================================${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    print_error "Please run as a regular user with sudo privileges"
    exit 1
fi

# Get current user and group
CURRENT_USER=$(whoami)
CURRENT_GROUP=$(id -gn)

print_status "Current user: $CURRENT_USER"
print_status "Current group: $CURRENT_GROUP"

# Fix ownership of current directory
print_status "Fixing ownership of current directory..."
sudo chown -R $CURRENT_USER:$CURRENT_GROUP .

# Set proper permissions
print_status "Setting proper permissions..."
chmod -R 755 .

# Set permissions for specific file types using find to avoid errors
print_status "Setting file permissions..."
find . -name "*.json" -type f -exec chmod 644 {} \; 2>/dev/null || true
find . -name "*.txt" -type f -exec chmod 644 {} \; 2>/dev/null || true
find . -name "*.md" -type f -exec chmod 644 {} \; 2>/dev/null || true
find . -name "*.sh" -type f -exec chmod 755 {} \; 2>/dev/null || true
find . -name "*.py" -type f -exec chmod 755 {} \; 2>/dev/null || true

# Remove root-owned virtual environment if it exists
if [[ -d "venv" ]]; then
    VENV_OWNER=$(stat -c '%U' venv)
    if [[ "$VENV_OWNER" == "root" ]]; then
        print_warning "Removing root-owned virtual environment..."
        sudo rm -rf venv
        print_status "Creating new virtual environment..."
        python3 -m venv venv
        sudo chown -R $CURRENT_USER:$CURRENT_USER venv
    fi
fi

# Create necessary directories with proper ownership
print_status "Creating necessary directories..."
mkdir -p logs reports services backups
sudo chown -R $CURRENT_USER:$CURRENT_USER logs reports services backups
chmod 755 logs reports services backups

print_success "Permissions fixed successfully!"
print_success "You can now run the test script: ./test_ubuntu22.sh" 