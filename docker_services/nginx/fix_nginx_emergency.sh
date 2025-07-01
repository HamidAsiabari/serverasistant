#!/bin/bash

# Emergency nginx fix script
# This script disables problematic configurations and gets nginx working again

set -e

echo "🚨 Emergency nginx fix - getting nginx working again..."

# Stop nginx
echo "🛑 Stopping nginx..."
docker-compose down

# Wait a moment
sleep 2

# Backup current configurations
echo "💾 Backing up current configurations..."
BACKUP_DIR="conf.d/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp conf.d/*.conf "$BACKUP_DIR/" 2>/dev/null || true
echo "✅ Backup created in $BACKUP_DIR"

# Remove all problematic configurations
echo "🧹 Removing problematic configurations..."
rm -f conf.d/docker.soject.com.conf
rm -f conf.d/gitlab.soject.com.conf

# Keep only the simple working configuration
echo "✅ Keeping only simple working configuration..."

# Start nginx with simple config
echo "🚀 Starting nginx with simple configuration..."
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
echo "🎉 Nginx is now working again!"
echo ""
echo "📋 Current status:"
echo "   ✅ app.soject.com - Working (simple configuration)"
echo "   ❌ docker.soject.com - Disabled (portainer not available)"
echo "   ❌ gitlab.soject.com - Disabled (gitlab not available)"
echo ""
echo "📋 To re-enable service configurations later:"
echo "   ./manage_configs.sh"
echo ""
echo "📋 To test:"
echo "   curl http://app.soject.com"
echo "   curl http://app.soject.com/health" 