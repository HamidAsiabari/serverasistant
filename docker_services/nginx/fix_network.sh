#!/bin/bash

echo "🔧 Fixing nginx network configuration..."

# Check what networks exist
echo "📡 Checking Docker networks..."
docker network ls

# Check what network portainer is on
echo ""
echo "🔍 Checking portainer container network..."
if docker ps | grep -q "portainer"; then
    echo "✅ Portainer is running"
    docker inspect portainer | grep -A 10 "NetworkMode"
else
    echo "❌ Portainer is not running"
fi

# Check what network nginx is on
echo ""
echo "🔍 Checking nginx container network..."
if docker ps | grep -q "nginx"; then
    echo "✅ Nginx is running"
    docker inspect nginx | grep -A 10 "NetworkMode"
else
    echo "❌ Nginx is not running"
fi

# Restart nginx to apply new configuration
echo ""
echo "🔄 Restarting nginx..."
docker-compose restart nginx

# Wait for nginx to start
echo "⏳ Waiting for nginx to start..."
sleep 5

# Test the configuration
echo ""
echo "🧪 Testing nginx configuration..."
if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    docker-compose exec nginx nginx -t
fi

# Test the proxy
echo ""
echo "🌐 Testing proxy..."
if curl -s http://docker.soject.com > /dev/null 2>&1; then
    echo "✅ Proxy is working!"
    echo "📄 Response: $(curl -s http://docker.soject.com | head -1)"
else
    echo "❌ Proxy is not working"
    echo "📋 Check nginx logs: docker-compose logs nginx"
fi 