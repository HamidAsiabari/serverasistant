#!/bin/bash

# Test nginx configuration and setup
# This script verifies the nginx service configuration

set -e

echo "🧪 Testing Nginx Configuration..."

# Check if required files exist
echo "📁 Checking required files..."
required_files=(
    "docker-compose.yml"
    "nginx.conf"
    "conf.d/app.soject.com.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check SSL certificates
echo "🔐 Checking SSL certificates..."
if [ -f "ssl/app.soject.com.crt" ] && [ -f "ssl/app.soject.com.key" ]; then
    echo "✅ SSL certificates found"
    
    # Check certificate validity
    if openssl x509 -in ssl/app.soject.com.crt -text -noout > /dev/null 2>&1; then
        echo "✅ SSL certificate is valid"
        
        # Check expiry date
        expiry=$(openssl x509 -in ssl/app.soject.com.crt -noout -enddate | cut -d= -f2)
        echo "📅 Certificate expires: $expiry"
    else
        echo "❌ SSL certificate is invalid"
        exit 1
    fi
else
    echo "⚠️  SSL certificates not found (will use HTTP-only mode)"
fi

# Test Docker Compose configuration
echo "🐳 Testing Docker Compose configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    docker-compose config
    exit 1
fi

# Check if nginx container can start
echo "🚀 Testing nginx container startup..."
if docker-compose up -d nginx > /dev/null 2>&1; then
    echo "✅ Nginx container started successfully"
    
    # Wait a moment for nginx to start
    sleep 3
    
    # Test nginx configuration inside container
    if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration is invalid"
        docker-compose exec nginx nginx -t
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
echo "🎉 All tests passed! Nginx service is ready to use."
echo ""
echo "📋 To start the service:"
echo "   docker-compose up -d"
echo ""
echo "📋 To test the service:"
echo "   curl http://app.soject.com/health" 