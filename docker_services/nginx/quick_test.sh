#!/bin/bash

# Quick test script for nginx configuration
# This script tests the basic nginx setup without SSL

set -e

echo "🧪 Quick Nginx Configuration Test..."

# Check if required files exist
echo "📁 Checking required files..."
required_files=(
    "docker-compose.yml"
    "nginx.conf"
    "conf.d/default.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Test Docker Compose configuration
echo "🐳 Testing Docker Compose configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    echo "🔍 Error details:"
    docker-compose config
    exit 1
fi

# Test if nginx container can start and stop
echo "🚀 Testing nginx container startup..."
if docker-compose up -d nginx > /dev/null 2>&1; then
    echo "✅ Nginx container started successfully"
    
    # Wait a moment for nginx to start
    sleep 5
    
    # Test nginx configuration inside container
    if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration is invalid"
        docker-compose exec nginx nginx -t
    fi
    
    # Test if nginx is responding
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Nginx is responding on port 80"
    else
        echo "⚠️  Nginx is not responding on port 80 (this is normal if web-app is not running)"
    fi
    
    # Stop the container
    docker-compose down > /dev/null 2>&1
    echo "🛑 Nginx container stopped"
else
    echo "❌ Failed to start nginx container"
    docker-compose logs nginx
    exit 1
fi

echo ""
echo "🎉 Quick test completed successfully!"
echo ""
echo "📋 The nginx service is ready to use."
echo "📋 To start: docker-compose up -d"
echo "📋 To test with web-app: make sure web-app is running first" 