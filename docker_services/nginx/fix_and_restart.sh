#!/bin/bash

# Fix and restart nginx script
# This script ensures only the working configuration is loaded

set -e

echo "🔧 Fixing nginx configuration..."

# Stop nginx
echo "🛑 Stopping nginx..."
docker-compose down

# Wait a moment
sleep 2

# Verify only the working config is present
echo "📁 Checking configuration files..."
if [ -f "conf.d/app.soject.com.conf" ]; then
    echo "✅ Main config file exists"
else
    echo "❌ Main config file missing"
    exit 1
fi

# Remove any other .conf files that might cause issues
echo "🧹 Cleaning up configuration files..."
for file in conf.d/*.conf; do
    if [ "$file" != "conf.d/app.soject.com.conf" ]; then
        echo "⚠️  Removing: $file"
        rm -f "$file"
    fi
done

# Start nginx
echo "🚀 Starting nginx..."
docker-compose up -d

# Wait for nginx to start
echo "⏳ Waiting for nginx to start..."
sleep 5

# Check if nginx is running
if docker-compose ps | grep -q "Up"; then
    echo "✅ Nginx is running successfully!"
    
    # Test the configuration
    echo "🧪 Testing nginx configuration..."
    if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration is invalid"
        docker-compose exec nginx nginx -t
        exit 1
    fi
    
    # Test the endpoints
    echo "🌐 Testing endpoints..."
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Nginx is responding on port 80"
        echo ""
        echo "📄 Test results:"
        echo "   Root: $(curl -s http://localhost:80)"
        echo "   Health: $(curl -s http://localhost:80/health)"
        echo "   Test: $(curl -s http://localhost:80/test)"
    else
        echo "⚠️  Nginx is not responding on port 80"
        echo "📋 Checking logs..."
        docker-compose logs nginx
    fi
    
else
    echo "❌ Nginx failed to start"
    echo "📋 Checking logs..."
    docker-compose logs nginx
    exit 1
fi

echo ""
echo "🎉 Nginx is now working correctly!"
echo ""
echo "📋 You can now test:"
echo "   curl http://app.soject.com"
echo "   curl http://app.soject.com/health"
echo "   curl http://app.soject.com/test" 