#!/bin/bash

# Quick Test Script
# This script quickly tests if all services are working

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

print_status "Quick Service Test"
print_status "=================="

# Check Docker containers
print_status "Checking Docker containers..."
if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "Up"; then
    print_success "Docker containers are running"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    print_error "No Docker containers are running"
    exit 1
fi

# Test local access
print_status "Testing local access..."

# Test Nginx
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
    print_success "Nginx (port 80): OK"
else
    print_warning "Nginx (port 80): FAILED"
fi

# Test Web App
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|301\|302"; then
    print_success "Web App (port 8080): OK"
else
    print_warning "Web App (port 8080): FAILED"
fi

# Test Portainer
if curl -s -o /dev/null -w "%{http_code}" http://localhost:9000 | grep -q "200\|301\|302"; then
    print_success "Portainer (port 9000): OK"
else
    print_warning "Portainer (port 9000): FAILED"
fi

# Test Roundcube
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8083 | grep -q "200\|301\|302"; then
    print_success "Roundcube (port 8083): OK"
else
    print_warning "Roundcube (port 8083): FAILED"
fi

# Check hosts file
print_status "Checking hosts file..."
if grep -q "soject.com" /etc/hosts 2>/dev/null; then
    print_success "Subdomains found in hosts file"
else
    print_warning "Subdomains NOT found in hosts file"
    print_status "Run: sudo ./add_to_hosts.sh"
fi

print_status ""
print_status "Test completed!"
print_status "If services are not accessible, try:"
print_status "1. ./restart_services.sh"
print_status "2. sudo ./add_to_hosts.sh"
print_status "3. Check logs: docker logs <container-name>" 