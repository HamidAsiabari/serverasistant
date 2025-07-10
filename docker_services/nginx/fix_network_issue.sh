#!/bin/bash

echo "🔧 Fixing nginx network issue..."

# Check if web_network exists
if ! docker network ls | grep -q "web_network"; then
    echo "❌ web_network does not exist"
    echo "📋 Creating web_network..."
    docker network create web_network
    echo "✅ web_network created"
else
    echo "✅ web_network already exists"
fi

# Check if portainer is running and connect it to web_network
if docker ps | grep -q "portainer"; then
    echo "🔗 Connecting portainer to web_network..."
    docker network connect web_network portainer 2>/dev/null || echo "⚠️  Portainer might already be connected"
fi

# Now try to start nginx
echo "🚀 Starting nginx..."
docker-compose up -d

# Wait for nginx to start
echo "⏳ Waiting for nginx to start..."
sleep 5

# Check if nginx is running
if docker ps | grep -q "nginx"; then
    echo "✅ Nginx is running successfully!"
    
    # Test the configuration
    echo "🧪 Testing nginx configuration..."
    if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration is invalid"
        docker-compose exec nginx nginx -t
    fi
    
    # Test the proxy
    echo "🌐 Testing proxy..."
    if curl -s http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Nginx is responding on port 80"
    else
        echo "⚠️  Nginx is not responding on port 80"
        echo "📋 Check logs: docker-compose logs nginx"
    fi
    
else
    echo "❌ Nginx failed to start"
    echo "📋 Checking logs..."
    docker-compose logs nginx
fi

echo ""
echo "🎉 Network fix complete!" 