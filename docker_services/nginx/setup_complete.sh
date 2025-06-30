#!/bin/bash

# Complete nginx setup script
# This script sets up all necessary components for nginx to work properly

set -e

echo "=== Nginx Complete Setup Script ==="
echo "This script will set up all necessary components for nginx"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (for port 80/443 binding)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. This is required for binding to ports 80 and 443."
else
    print_warning "Not running as root. You may need sudo for ports 80 and 443."
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p ssl
mkdir -p config/conf.d

# Set proper permissions
print_status "Setting proper permissions..."
chmod 755 logs
chmod 700 ssl
chmod 644 config/conf.d/*.conf 2>/dev/null || true

# Generate SSL certificates if they don't exist
if [ ! -f "ssl/default.crt" ]; then
    print_status "Generating SSL certificates..."
    if command -v openssl &> /dev/null; then
        ./generate_ssl.sh
    else
        print_error "OpenSSL not found. Please install OpenSSL and run generate_ssl.sh manually."
        exit 1
    fi
else
    print_status "SSL certificates already exist."
fi

# Validate nginx configuration
print_status "Validating nginx configuration..."
if command -v nginx &> /dev/null; then
    # Test configuration syntax
    if nginx -t -c "$(pwd)/config/nginx.conf" 2>/dev/null; then
        print_status "Nginx configuration is valid."
    else
        print_warning "Nginx configuration validation failed. This is normal if nginx is not installed locally."
    fi
else
    print_warning "Nginx not found locally. Configuration will be validated when container starts."
fi

# Check if Docker is available
if command -v docker &> /dev/null; then
    print_status "Docker found. Testing nginx configuration in container..."
    
    # Create a temporary container to test configuration
    if docker run --rm -v "$(pwd)/config:/etc/nginx:ro" nginx:stable nginx -t 2>/dev/null; then
        print_status "Nginx configuration is valid in Docker container."
    else
        print_error "Nginx configuration is invalid in Docker container."
        exit 1
    fi
else
    print_warning "Docker not found. Skipping container configuration test."
fi

# Create a simple health check file
print_status "Creating health check file..."
cat > logs/health.txt << EOF
Nginx is running
Last updated: $(date)
EOF

# Set up log rotation (optional)
print_status "Setting up log rotation..."
cat > logs/nginx.logrotate << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 nginx nginx
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \$(cat /var/run/nginx.pid)
        fi
    endscript
}
EOF

print_status "Log rotation configuration created at logs/nginx.logrotate"

# Create a startup script
print_status "Creating startup script..."
cat > start_nginx.sh << 'EOF'
#!/bin/bash
echo "Starting nginx with Docker Compose..."
docker-compose down
docker-compose up -d --build

echo "Nginx container started!"
echo "Check logs with: docker-compose logs -f nginx"
echo "Stop with: docker-compose down"
EOF

chmod +x start_nginx.sh

# Create a stop script
print_status "Creating stop script..."
cat > stop_nginx.sh << 'EOF'
#!/bin/bash
echo "Stopping nginx..."
docker-compose down
echo "Nginx stopped!"
EOF

chmod +x stop_nginx.sh

# Create a restart script
print_status "Creating restart script..."
cat > restart_nginx.sh << 'EOF'
#!/bin/bash
echo "Restarting nginx..."
docker-compose down
docker-compose up -d --build
echo "Nginx restarted!"
EOF

chmod +x restart_nginx.sh

# Display final information
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Nginx setup is complete! Here's what was configured:"
echo ""
echo "📁 Directories created:"
echo "  - logs/ (for nginx logs)"
echo "  - ssl/ (for SSL certificates)"
echo "  - config/conf.d/ (for site configurations)"
echo ""
echo "🔐 SSL Certificates:"
echo "  - Generated self-signed certificates for all domains"
echo "  - For production, replace with proper certificates"
echo ""
echo "📝 Scripts created:"
echo "  - start_nginx.sh (start nginx)"
echo "  - stop_nginx.sh (stop nginx)"
echo "  - restart_nginx.sh (restart nginx)"
echo ""
echo "🚀 To start nginx:"
echo "  ./start_nginx.sh"
echo ""
echo "📋 To check status:"
echo "  docker-compose ps"
echo ""
echo "📊 To view logs:"
echo "  docker-compose logs -f nginx"
echo ""
echo "⚠️  Important notes:"
echo "  - SSL certificates are self-signed (development only)"
echo "  - Add domains to /etc/hosts for local testing"
echo "  - For production, use proper SSL certificates"
echo ""

print_status "Setup completed successfully!" 