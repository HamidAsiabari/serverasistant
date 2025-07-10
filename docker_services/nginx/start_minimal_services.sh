#!/bin/bash

echo "🚀 Starting minimal services for nginx..."

# Ensure web_network exists
if ! docker network ls | grep -q "web_network"; then
    echo "📋 Creating web_network..."
    docker network create web_network
fi

# Start only essential services
echo ""
echo "📦 Starting essential services..."

# Start portainer (always needed for docker.soject.com)
echo "   Starting portainer..."
cd ../portainer
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
    echo "   ✅ Portainer started"
else
    echo "   ❌ Portainer docker-compose.yml not found"
fi
cd ../nginx

# Check what other services are available and start them if needed
echo ""
echo "🔍 Checking available services..."

# Check if gitlab is available
if [ -d "../gitlab" ] && [ -f "../gitlab/docker-compose.yml" ]; then
    echo "   Starting gitlab..."
    cd ../gitlab
    docker-compose up -d
    echo "   ✅ GitLab started"
    cd ../nginx
fi

# Check if web-app is available
if [ -d "../web-app" ] && [ -f "../web-app/docker-compose.yml" ]; then
    echo "   Starting web-app..."
    cd ../web-app
    docker-compose up -d
    echo "   ✅ Web App started"
    cd ../nginx
fi

# Check if mysql is available
if [ -d "../mysql" ] && [ -f "../mysql/docker-compose.yml" ]; then
    echo "   Starting mysql..."
    cd ../mysql
    docker-compose up -d
    echo "   ✅ MySQL started"
    cd ../nginx
fi

# Wait for services to start
echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Show running services
echo ""
echo "📋 Running services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Show web_network connections
echo ""
echo "🌐 Web network connections:"
docker network inspect web_network --format "{{range .Containers}}{{.Name}} {{end}}" 2>/dev/null || echo "   No containers connected to web_network"

echo ""
echo "🎉 Minimal services started!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: chmod +x fix_nginx_config.sh && ./fix_nginx_config.sh"
echo "   2. Run: chmod +x setup_all_domains.sh && ./setup_all_domains.sh" 