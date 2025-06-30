#!/bin/bash

# Nginx Organization Script
# Cleans up and organizes the nginx folder structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

print_status "🧹 Organizing Nginx folder structure..."

# Create backup directory for old files
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_status "📁 Creating backup directory: $BACKUP_DIR"

# Move old files to backup
old_files=(
    "setup_nginx_robust.sh"
    "docker-compose.simple.yml"
    "admin.example.com.conf.disabled"
    "test.conf"
)

for file in "${old_files[@]}"; do
    if [ -f "$file" ]; then
        mv "$file" "$BACKUP_DIR/"
        print_status "Moved $file to backup"
    fi
done

# Clean up any remaining example.com files
print_status "🧹 Cleaning up old example.com configurations..."
find config/conf.d -name "*.example.com.*" -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true
find ssl -name "*.example.com.*" -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null || true

# Set proper permissions
print_status "🔒 Setting proper permissions..."
chmod +x *.sh
chmod 644 config/conf.d/*.conf
chmod 644 config/nginx.conf
chmod 600 ssl/*.key 2>/dev/null || true
chmod 644 ssl/*.crt 2>/dev/null || true

# Create logs directory if it doesn't exist
mkdir -p logs
chmod 755 logs

# Verify current structure
print_status "🔍 Verifying current structure..."
required_files=(
    "config/nginx.conf"
    "config/conf.d/default.conf"
    "config/conf.d/app.soject.com.conf"
    "config/conf.d/admin.soject.com.conf"
    "config/conf.d/docker.soject.com.conf"
    "config/conf.d/gitlab.soject.com.conf"
    "config/conf.d/mail.soject.com.conf"
    "docker-compose.yml"
    "setup_nginx.sh"
    "manage_nginx.sh"
    "generate_ssl.sh"
    "cleanup_old_configs.sh"
    "README.md"
)

echo ""
print_status "Current file structure:"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "✓ $file"
    else
        print_error "✗ $file"
    fi
done

# Show current directory structure
echo ""
print_status "📂 Current directory structure:"
tree -I 'backup_*' 2>/dev/null || ls -la

# Create a summary file
cat > organization_summary.txt << EOF
Nginx Organization Summary
==========================

Date: $(date)
Backup Directory: $BACKUP_DIR

Current Active Files:
$(for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file"
    fi
done)

Scripts Available:
- setup_nginx.sh: Main setup script
- manage_nginx.sh: Management script for common operations
- generate_ssl.sh: SSL certificate generation
- cleanup_old_configs.sh: Cleanup old configurations
- organize_nginx.sh: This organization script

Usage:
- Initial setup: sudo ./setup_nginx.sh
- Management: ./manage_nginx.sh [command]
- SSL regeneration: ./manage_nginx.sh ssl
- Health check: ./manage_nginx.sh health

Backup files are stored in: $BACKUP_DIR
EOF

print_success "📋 Organization summary saved to: organization_summary.txt"

echo ""
print_success "🎉 Nginx folder organization completed!"
print_status "Backup files stored in: $BACKUP_DIR"
print_status "Run './manage_nginx.sh help' for available commands" 