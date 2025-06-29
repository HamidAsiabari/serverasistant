#!/bin/bash

# Add subdomains to hosts file for local testing
# This script adds the soject.com subdomains to /etc/hosts

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

HOSTS_FILE="/etc/hosts"
DOMAINS=(
    "app.soject.com"
    "admin.soject.com"
    "portainer.soject.com"
    "gitlab.soject.com"
    "mail.soject.com"
)

print_status "Adding subdomains to hosts file..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

# Backup hosts file
cp "$HOSTS_FILE" "${HOSTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
print_success "Hosts file backed up"

# Add domains to hosts file
for domain in "${DOMAINS[@]}"; do
    if grep -q "$domain" "$HOSTS_FILE"; then
        print_warning "$domain already exists in hosts file"
    else
        echo "127.0.0.1 $domain" >> "$HOSTS_FILE"
        print_success "Added $domain to hosts file"
    fi
done

print_success "Hosts file updated successfully!"
print_status "You can now access your services at:"
for domain in "${DOMAINS[@]}"; do
    echo "  - https://$domain"
done
print_status ""
print_status "Note: For production, configure these domains in Cloudflare to point to your server IP" 