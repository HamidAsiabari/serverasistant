#!/bin/bash

# Nginx service setup script
# This script sets up the nginx reverse proxy service

set -e

echo "🚀 Setting up Nginx Reverse Proxy Service..."

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs
mkdir -p ssl
mkdir -p conf.d

# Check if SSL certificates exist
if [ ! -f "ssl/app.soject.com.crt" ] || [ ! -f "ssl/app.soject.com.key" ]; then
    echo "🔐 SSL certificates not found. Generating self-signed certificates..."
    ./generate_ssl.sh
else
    echo "✅ SSL certificates found"
fi

# Set proper permissions
echo "🔒 Setting file permissions..."
chmod 644 ssl/app.soject.com.crt 2>/dev/null || true
chmod 600 ssl/app.soject.com.key 2>/dev/null || true

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    exit 1
fi

echo ""
echo "🎉 Nginx service setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Add app.soject.com to your hosts file or DNS"
echo "   2. Start the service: docker-compose up -d"
echo "   3. Test the service: curl http://app.soject.com/health"
echo ""
echo "📚 For more information, see README.md" 