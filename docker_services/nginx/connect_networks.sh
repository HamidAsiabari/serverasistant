#!/bin/bash

echo "🔧 Connecting portainer to web_network..."

# Check if web_network exists
if ! docker network ls | grep -q "web_network"; then
    echo "❌ web_network does not exist"
    echo "📋 Creating web_network..."
    docker network create web_network
fi

# Connect portainer to web_network
echo "🔗 Connecting portainer to web_network..."
if docker network connect web_network portainer 2>/dev/null; then
    echo "✅ Portainer connected to web_network"
else
    echo "⚠️  Portainer might already be connected to web_network"
fi

# Verify the connection
echo ""
echo "🔍 Verifying network connections..."
echo "📡 Portainer networks:"
docker inspect portainer | grep -A 5 "Networks"

echo ""
echo "📡 Nginx networks:"
docker inspect nginx | grep -A 5 "Networks"

# Restart nginx to apply configuration
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
    exit 1
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