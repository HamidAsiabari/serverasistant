#!/bin/bash

# Clean restart script for nginx
# This script stops nginx, cleans up, and restarts with working configuration

set -e

echo "🔄 Restarting nginx with clean configuration..."

# Stop nginx
echo "🛑 Stopping nginx..."
docker-compose down

# Wait a moment
sleep 2

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
        echo "📄 Test page: curl http://localhost:80"
        echo "🏥 Health check: curl http://localhost:80/health"
        echo "🧪 Test endpoint: curl http://localhost:80/test"
    else
        echo "⚠️  Nginx is not responding on port 80"
    fi
    
else
    echo "❌ Nginx failed to start"
    echo "📋 Checking logs..."
    docker-compose logs nginx
    exit 1
fi

echo ""
echo "🎉 Nginx restart completed successfully!"
echo ""
echo "📋 You can now test:"
echo "   curl http://app.soject.com"
echo "   curl http://app.soject.com/health"
echo "   curl http://app.soject.com/test" 