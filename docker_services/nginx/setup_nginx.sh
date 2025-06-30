#!/bin/bash

# Comprehensive Nginx Reverse Proxy Setup Script
# This script sets up nginx with SSL certificates for all domains

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

print_status "🚀 Starting Comprehensive Nginx Setup..."
print_status "Working directory: $SCRIPT_DIR"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Install required packages
print_status "📦 Installing required packages..."
apt update
apt install -y openssl docker.io docker-compose curl

# Stop any existing nginx container
print_status "🛑 Stopping existing nginx containers..."
docker stop nginx-proxy 2>/dev/null || true
docker rm nginx-proxy 2>/dev/null || true

# Create necessary directories
print_status "📁 Creating directories..."
mkdir -p config/conf.d logs ssl

# Set file permissions
print_status "🔒 Setting file permissions..."
chmod 755 config logs ssl
chmod 644 config/conf.d/*.conf 2>/dev/null || true

# Clean up old configurations if cleanup script exists
if [ -f "cleanup_old_configs.sh" ]; then
    print_status "🧹 Cleaning up old configurations..."
    chmod +x cleanup_old_configs.sh
    ./cleanup_old_configs.sh
fi

# Generate SSL certificates
print_status "🔐 Generating SSL certificates..."
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

# Set proper permissions for SSL files
print_status "🔒 Setting SSL permissions..."
chmod 600 ssl/*.key 2>/dev/null || true
chmod 644 ssl/*.crt 2>/dev/null || true

# Create logs directory with proper permissions
mkdir -p logs
chown -R 101:101 logs  # nginx user in container

# Verify configuration files exist
print_status "🔍 Verifying configuration files..."
required_files=(
    "config/nginx.conf"
    "config/conf.d/default.conf"
    "config/conf.d/app.soject.com.conf"
    "config/conf.d/admin.soject.com.conf"
    "config/conf.d/docker.soject.com.conf"
    "config/conf.d/gitlab.soject.com.conf"
    "config/conf.d/mail.soject.com.conf"
    "docker-compose.yml"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
        print_warning "Missing: $file"
    else
        print_success "Found: $file"
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    print_error "Missing required configuration files. Please ensure all config files are present."
    exit 1
fi

# Test Docker Compose configuration
print_status "🧪 Testing Docker Compose configuration..."
if docker-compose config >/dev/null 2>&1; then
    print_success "Docker Compose configuration is valid"
else
    print_error "Docker Compose configuration is invalid"
    docker-compose config
    exit 1
fi

# Start nginx
print_status "🚀 Starting nginx..."
docker-compose up -d

# Wait for nginx to start
print_status "⏳ Waiting for nginx to start..."
sleep 5

# Check if nginx is running
if docker ps | grep -q nginx-proxy; then
    print_success "Nginx is running successfully!"
    
    # Test HTTP access
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|301\|302"; then
        print_success "HTTP access working (port 80)"
    else
        print_warning "HTTP access test failed"
    fi
    
    # Test HTTPS access (ignore certificate warnings)
    if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 | grep -q "200\|301\|302"; then
        print_success "HTTPS access working (port 443)"
    else
        print_warning "HTTPS access test failed"
    fi
    
    # Show container info
    print_status "Nginx container info:"
    docker ps --filter name=nginx-proxy --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    print_success "🌐 Your services are now available at:"
    echo "   - Web App:     https://app.soject.com"
    echo "   - phpMyAdmin:  https://admin.soject.com"
    echo "   - Portainer:   https://docker.soject.com"
    echo "   - GitLab:      https://gitlab.soject.com"
    echo "   - Mail:        https://mail.soject.com"
    echo "   - Default:     https://your-server-ip"
    echo ""
    print_warning "📝 Note: You'll need to add these domains to your hosts file or DNS:"
    echo "   127.0.0.1 app.soject.com admin.soject.com docker.soject.com gitlab.soject.com mail.soject.com"
    echo ""
    print_status "🔍 Useful commands:"
    echo "   - Check logs:     docker logs nginx-proxy"
    echo "   - Restart:        docker-compose restart"
    echo "   - Stop:           docker-compose down"
    echo "   - View status:    docker-compose ps"
    echo ""
    print_warning "⚠️  Security Warning: Self-signed certificates are for development only."
    echo "   For production, use trusted certificates from Let's Encrypt or a CA."
    
else
    print_error "Nginx failed to start. Check logs with: docker logs nginx-proxy"
    docker logs nginx-proxy
    exit 1
fi

print_success "🎉 Nginx reverse proxy setup completed successfully!" 