#!/bin/bash

echo "🔍 Checking running services..."

# Check what's running on port 9000
echo "📡 Checking port 9000..."
if netstat -tlnp 2>/dev/null | grep -q ":9000"; then
    echo "✅ Port 9000 is in use"
    netstat -tlnp | grep ":9000"
else
    echo "❌ Nothing is running on port 9000"
fi

# Check Docker containers
echo ""
echo "🐳 Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check if portainer container exists
echo ""
echo "🔍 Checking for portainer container..."
if docker ps -a | grep -q "portainer"; then
    echo "✅ Portainer container exists"
    docker ps -a | grep portainer
else
    echo "❌ Portainer container not found"
fi

# Check if portainer service is running
echo ""
echo "🚀 Checking portainer service status..."
if docker ps | grep -q "portainer"; then
    echo "✅ Portainer is running"
else
    echo "❌ Portainer is not running"
    echo ""
    echo "📋 To start portainer:"
    echo "   cd ../portainer"
    echo "   docker-compose up -d"
fi

echo ""
echo "🌐 Testing nginx proxy..."
if curl -s http://localhost:9000 > /dev/null 2>&1; then
    echo "✅ Portainer is accessible on localhost:9000"
else
    echo "❌ Portainer is not accessible on localhost:9000"
fi 