#!/bin/bash

echo "🔧 Fixing nginx network issue and domain routing..."

# Check if web_network exists
if ! docker network ls | grep -q "web_network"; then
    echo "❌ web_network does not exist"
    echo "📋 Creating web_network..."
    docker network create web_network
    echo "✅ web_network created"
else
    echo "✅ web_network already exists"
fi

# Restart all services to ensure they're connected to web_network
echo ""
echo "🔄 Restarting all services to ensure proper network connectivity..."

# Restart services in order
services=("mysql" "gitlab" "mail-server" "portainer" "web-app")

for service in "${services[@]}"; do
    echo "   Restarting $service..."
    cd "../$service"
    if [ -f "docker-compose.yml" ]; then
        docker-compose down
        docker-compose up -d
        echo "   ✅ $service restarted"
    else
        echo "   ⚠️  $service docker-compose.yml not found"
    fi
    cd "../nginx"
done

# Check if portainer is running and connect it to web_network
if docker ps | grep -q "portainer"; then
    echo "🔗 Connecting portainer to web_network..."
    docker network connect web_network portainer 2>/dev/null || echo "⚠️  Portainer might already be connected"
fi

# Now try to start nginx
echo ""
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
        echo "📋 Checking logs..."
        docker-compose logs nginx
    fi
    
else
    echo "❌ Nginx failed to start"
    echo "📋 Checking logs..."
    docker-compose logs nginx
fi

echo ""
echo "🎉 Network fix complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: chmod +x setup_all_domains.sh && ./setup_all_domains.sh"
echo "   2. Run: chmod +x test_all_domains.sh && ./test_all_domains.sh"
echo "   3. Test domains in browser:"
echo "      - http://gitlab.soject.com"
echo "      - http://docker.soject.com"
echo "      - http://app.soject.com"
echo "      - http://admin.soject.com"
echo "      - http://mail.soject.com" 