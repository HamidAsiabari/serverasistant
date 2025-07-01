#!/bin/bash

echo "🚀 Starting Portainer service..."

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Not in nginx directory"
    exit 1
fi

# Go to portainer directory
echo "📁 Going to portainer directory..."
cd ../portainer

# Check if portainer docker-compose exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Portainer docker-compose.yml not found"
    echo "📋 Please ensure portainer service is set up in ../portainer/"
    exit 1
fi

# Start portainer
echo "🚀 Starting portainer..."
docker-compose up -d

# Wait a moment for portainer to start
echo "⏳ Waiting for portainer to start..."
sleep 10

# Check if portainer is running
if docker ps | grep -q "portainer"; then
    echo "✅ Portainer is running"
    
    # Test if portainer is accessible
    if curl -s http://localhost:9000 > /dev/null 2>&1; then
        echo "✅ Portainer is accessible on localhost:9000"
        echo ""
        echo "🎉 Success! Now test the nginx proxy:"
        echo "   curl http://docker.soject.com"
    else
        echo "⚠️  Portainer is running but not accessible yet"
        echo "📋 Wait a moment and try again"
    fi
else
    echo "❌ Failed to start portainer"
    echo "📋 Check logs: docker-compose logs portainer"
fi 