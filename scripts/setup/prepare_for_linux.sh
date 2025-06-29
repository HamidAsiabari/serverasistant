#!/bin/bash
# Script to prepare files for Linux transfer
# This ensures proper line endings and permissions

set -e

echo "Preparing files for Linux transfer..."

# Fix line endings for all Python files
echo "Fixing line endings for Python files..."
find . -name "*.py" -type f -exec sed -i 's/\r$//' {} \;

# Fix line endings for shell scripts
echo "Fixing line endings for shell scripts..."
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

# Make shell scripts executable
echo "Making shell scripts executable..."
find . -name "*.sh" -type f -exec chmod +x {} \;

# Make Python scripts executable
echo "Making Python scripts executable..."
find . -name "*.py" -type f -exec chmod +x {} \;

# Set proper permissions for directories
echo "Setting directory permissions..."
find . -type d -exec chmod 755 {} \;

# Set proper permissions for files
echo "Setting file permissions..."
find . -type f -exec chmod 644 {} \;

# Make specific files executable
chmod +x *.py *.sh 2>/dev/null || true

echo "Files prepared for Linux transfer!"
echo "You can now transfer the files to your Ubuntu server." 