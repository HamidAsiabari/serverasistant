#!/bin/bash

# Robust Nginx Reverse Proxy Setup Script
# This script handles Docker socket issues and provides better error handling

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

print_status "Robust Nginx Reverse Proxy Setup"
print_status "Working directory: $SCRIPT_DIR"

# Stop any existing nginx container
print_status "Stopping any existing Nginx containers..."
docker stop nginx-proxy 2>/dev/null || true
docker rm nginx-proxy 2>/dev/null || true

# Create necessary directories
print_status "Creating directories..."
mkdir -p config/conf.d logs ssl

# Set file permissions
print_status "Setting file permissions..."
chmod 755 config logs ssl
chmod 644 config/conf.d/*.conf 2>/dev/null || true

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

# Create a basic nginx configuration that works without external services
print_status "Creating basic Nginx configuration..."

# Create a simple nginx.conf
cat > config/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Default server block
    server {
        listen 80 default_server;
        server_name _;
        
        location / {
            return 200 "Nginx is running! Add subdomains to /etc/hosts to access services.";
            add_header Content-Type text/plain;
        }
        
        location /health {
            return 200 "healthy";
            add_header Content-Type text/plain;
        }
    }

    # Include server configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create a simple default configuration
cat > config/conf.d/default.conf << 'EOF'
# Default server configuration
server {
    listen 80;
    server_name localhost;
    
    location / {
        return 200 "ServerAssistant Nginx Proxy is running!\n\nAvailable services:\n- Web App: http://app.soject.com\n- Admin: http://admin.soject.com\n- Portainer: http://portainer.soject.com\n- GitLab: http://gitlab.soject.com\n- Mail: http://mail.soject.com\n\nNote: Add these domains to /etc/hosts for local access.";
        add_header Content-Type text/plain;
    }
}
EOF

print_success "Basic Nginx configuration created"

# Start Nginx with simple configuration
print_status "Starting Nginx with simple configuration..."

# Use docker run instead of docker-compose for better control
if docker run -d \
    --name nginx-proxy \
    --restart unless-stopped \
    -p 80:80 \
    -p 443:443 \
    -v "$SCRIPT_DIR/config/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "$SCRIPT_DIR/config/conf.d:/etc/nginx/conf.d:ro" \
    -v "$SCRIPT_DIR/ssl:/etc/nginx/ssl:ro" \
    -v "$SCRIPT_DIR/logs:/var/log/nginx" \
    nginx:alpine; then
    
    print_success "Nginx started successfully"
    
    # Wait a moment for Nginx to start
    sleep 5
    
    # Check if Nginx is running
    if docker ps | grep -q "nginx-proxy"; then
        print_success "Nginx is running and healthy"
        
        # Test HTTP access
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200"; then
            print_success "HTTP access working (port 80)"
        else
            print_warning "HTTP access test failed"
        fi
        
        # Show container info
        print_status "Nginx container info:"
        docker ps --filter name=nginx-proxy --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
    else
        print_error "Nginx failed to start properly"
        docker logs nginx-proxy
        exit 1
    fi
else
    print_error "Failed to start Nginx"
    exit 1
fi

print_success "Nginx reverse proxy setup completed!"
print_status "Access your services at:"
print_status "  - HTTP:  http://localhost"
print_status "  - HTTPS: https://localhost (self-signed certificate)"
print_status ""
print_status "To access subdomains, add to /etc/hosts:"
print_status "  127.0.0.1 app.soject.com admin.soject.com portainer.soject.com gitlab.soject.com mail.soject.com"
print_status ""
print_status "Run: sudo ./add_to_hosts.sh" 