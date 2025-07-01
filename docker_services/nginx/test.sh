#!/bin/bash

echo "🧪 Testing nginx configuration..."

# Test nginx config
echo "📋 Testing nginx configuration..."
if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    docker-compose exec nginx nginx -t
    exit 1
fi

# Test if nginx is responding
echo "🌐 Testing nginx response..."
if curl -s http://localhost:80 > /dev/null 2>&1; then
    echo "✅ Nginx is responding on port 80"
else
    echo "❌ Nginx is not responding on port 80"
fi

echo "✅ Test complete!" 