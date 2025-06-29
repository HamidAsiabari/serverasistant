#!/bin/bash

# Nginx Reverse Proxy Setup Script
# This script sets up Nginx as a reverse proxy for all services

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

print_status "Nginx Reverse Proxy Setup"
print_status "Working directory: $SCRIPT_DIR"

# Create necessary directories
print_status "Creating directories..."
mkdir -p config/conf.d logs ssl

# Set file permissions
print_status "Setting file permissions..."
chmod 755 config logs ssl
chmod 644 config/conf.d/*.conf 2>/dev/null || true

# Create Docker networks if they don't exist
print_status "Creating Docker networks..."

# Function to create network if it doesn't exist
create_network_if_not_exists() {
    local network_name=$1
    if ! docker network ls | grep -q "$network_name"; then
        print_status "Creating network: $network_name"
        docker network create "$network_name"
        print_success "Network $network_name created"
    else
        print_success "Network $network_name already exists"
    fi
}

# Create all required networks
create_network_if_not_exists "web_network"
create_network_if_not_exists "mail_network"
create_network_if_not_exists "gitlab_network"
create_network_if_not_exists "portainer_network"

# Test Docker Compose configuration
print_status "Testing Nginx configuration..."

# First try the simple configuration
if [ -f "docker-compose.simple.yml" ]; then
    print_status "Testing simple configuration first..."
    if docker-compose -f docker-compose.simple.yml config >/dev/null 2>&1; then
        print_success "Simple Docker Compose configuration is valid"
        USE_SIMPLE_CONFIG=true
    else
        print_error "Simple Docker Compose configuration is invalid"
        exit 1
    fi
else
    USE_SIMPLE_CONFIG=false
fi

# Try the full configuration
if [ "$USE_SIMPLE_CONFIG" = false ]; then
    if docker-compose config >/dev/null 2>&1; then
        print_success "Full Docker Compose configuration is valid"
        USE_SIMPLE_CONFIG=false
    else
        print_warning "Full configuration invalid, falling back to simple configuration"
        USE_SIMPLE_CONFIG=true
    fi
fi

# Generate SSL certificates if they don't exist
if [ ! -f "ssl/nginx.crt" ] || [ ! -f "ssl/nginx.key" ]; then
    print_status "Generating SSL certificates..."
    if [ -f "generate_ssl.sh" ]; then
        chmod +x generate_ssl.sh
        ./generate_ssl.sh
    else
        print_warning "generate_ssl.sh not found, creating basic certificates..."
        
        # Create basic self-signed certificate
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout ssl/nginx.key \
            -out ssl/nginx.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
            -addext "subjectAltName=DNS:localhost,DNS:*.soject.com"
        
        chmod 600 ssl/nginx.key
        chmod 644 ssl/nginx.crt
        print_success "Basic SSL certificates created"
    fi
fi

# Start Nginx
print_status "Starting Nginx reverse proxy..."

if [ "$USE_SIMPLE_CONFIG" = true ]; then
    print_status "Using simple configuration..."
    if docker-compose -f docker-compose.simple.yml up -d; then
        print_success "Nginx reverse proxy started successfully (simple config)"
    else
        print_error "Failed to start Nginx with simple configuration"
        docker-compose -f docker-compose.simple.yml logs nginx
        exit 1
    fi
else
    print_status "Using full configuration..."
    if docker-compose up -d; then
        print_success "Nginx reverse proxy started successfully (full config)"
    else
        print_error "Failed to start Nginx with full configuration"
        docker-compose logs nginx
        exit 1
    fi
fi

# Wait a moment for Nginx to start
sleep 3

# Check if Nginx is running
if [ "$USE_SIMPLE_CONFIG" = true ]; then
    if docker-compose -f docker-compose.simple.yml ps | grep -q "Up"; then
        print_success "Nginx is running and healthy (simple config)"
    else
        print_error "Nginx failed to start properly"
        docker-compose -f docker-compose.simple.yml logs nginx
        exit 1
    fi
else
    if docker-compose ps | grep -q "Up"; then
        print_success "Nginx is running and healthy (full config)"
    else
        print_error "Nginx failed to start properly"
        docker-compose logs nginx
        exit 1
    fi
fi

# Test HTTP access
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|301\|302"; then
    print_success "HTTP access working (port 80)"
else
    print_warning "HTTP access test failed"
fi

# Test HTTPS access (ignore SSL certificate warnings)
if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 | grep -q "200\|301\|302"; then
    print_success "HTTPS access working (port 443)"
else
    print_warning "HTTPS access test failed"
fi

print_success "Nginx reverse proxy setup completed!"
print_status "Access your services at:"
print_status "  - HTTP:  http://localhost"
print_status "  - HTTPS: https://localhost"
print_status "  - Admin: https://admin.soject.com"
print_status "  - App:   https://app.soject.com"
print_status "  - GitLab: https://gitlab.soject.com"
print_status "  - Mail:  https://mail.soject.com"
print_status "  - Portainer: https://portainer.soject.com"

if [ "$USE_SIMPLE_CONFIG" = true ]; then
    print_warning "Using simple configuration - external networks not connected"
    print_status "To upgrade to full configuration, ensure all services are running first"
fi 