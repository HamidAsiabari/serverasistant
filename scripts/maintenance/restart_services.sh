#!/bin/bash

# Restart All Services Script
# This script restarts all services and fixes common issues

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

print_status "Restarting All Services"
print_status "Working directory: $SCRIPT_DIR"

# Stop all containers
print_status "Stopping all containers..."
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove unused networks
print_status "Cleaning up networks..."
docker network prune -f

# Create required networks
print_status "Creating required networks..."
docker network create web_network 2>/dev/null || true
docker network create mail_network 2>/dev/null || true
docker network create gitlab_network 2>/dev/null || true
docker network create portainer_network 2>/dev/null || true

print_success "Networks created"

# Start services in order
print_status "Starting services..."

# 1. Start databases first
print_status "Starting MySQL..."
cd example_services/mysql
docker-compose up -d
cd "$SCRIPT_DIR"

print_status "Starting PostgreSQL/Redis..."
cd example_services/database
docker-compose up -d
cd "$SCRIPT_DIR"

# 2. Start web-app
print_status "Starting Web App..."
cd example_services/web-app
docker-compose up -d
cd "$SCRIPT_DIR"

# 3. Start Portainer
print_status "Starting Portainer..."
cd example_services/portainer
docker-compose up -d
cd "$SCRIPT_DIR"

# 4. Start GitLab
print_status "Starting GitLab..."
cd example_services/gitlab
docker-compose up -d
cd "$SCRIPT_DIR"

# 5. Start Mail Server
print_status "Starting Mail Server..."
cd example_services/mail-server
docker-compose up -d
cd "$SCRIPT_DIR"

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 10

# Check service status
print_status "Checking service status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test basic connectivity
print_status "Testing basic connectivity..."

# Test HTTP access
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    print_success "HTTP access working (port 80)"
else
    print_warning "HTTP access test failed"
fi

# Test individual services
services=(
    "web-app:8080"
    "portainer:9000"
    "roundcube:8083"
)

for service in "${services[@]}"; do
    service_name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$port | grep -q "200\|301\|302"; then
        print_success "$service_name accessible on port $port"
    else
        print_warning "$service_name not accessible on port $port"
    fi
done

print_success "Service restart completed!"
print_status ""
print_status "Access your services at:"
print_status "  - HTTP:  http://localhost"
print_status "  - Web App: http://localhost:8080"
print_status "  - Portainer: http://localhost:9000"
print_status "  - Roundcube: http://localhost:8083"
print_status ""
print_status "To access subdomains, add to /etc/hosts:"
print_status "  127.0.0.1 app.soject.com admin.soject.com portainer.soject.com gitlab.soject.com mail.soject.com"
print_status ""
print_status "Run: sudo ./add_to_hosts.sh" 