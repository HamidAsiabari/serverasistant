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
    if [ -f "generate_ssl.sh" ]; then
        chmod +x generate_ssl.sh
        ./generate_ssl.sh
    else
        echo "⚠️  generate_ssl.sh not found. SSL certificates will need to be added manually."
        echo "   For now, nginx will work with HTTP-only configuration."
    fi
else
    echo "✅ SSL certificates found"
fi

# Set proper permissions if certificates exist
if [ -f "ssl/app.soject.com.crt" ] && [ -f "ssl/app.soject.com.key" ]; then
    echo "🔒 Setting file permissions..."
    chmod 644 ssl/app.soject.com.crt 2>/dev/null || true
    chmod 600 ssl/app.soject.com.key 2>/dev/null || true
fi

# Test nginx configuration
echo "🧪 Testing nginx configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    echo "🔍 Showing detailed error:"
    docker-compose config
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