#!/bin/bash

# Setup all domains for nginx services
# This script configures all service domains

set -e

echo "🔧 Setting up all service domains..."

# Get the server IP address
echo "📡 Detecting server IP address..."
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "✅ Server IP: $SERVER_IP"

# Define all domains
DOMAINS=("app.soject.com" "docker.soject.com" "gitlab.soject.com")

# Check and update hosts file for each domain
echo "📝 Updating /etc/hosts file..."
for domain in "${DOMAINS[@]}"; do
    echo "🔍 Checking $domain..."
    
    # Remove existing entry if it exists
    if grep -q "$domain" /etc/hosts; then
        echo "🗑️  Removing existing entry for $domain"
        sudo sed -i "/$domain/d" /etc/hosts
    fi
    
    # Add new entry
    echo "➕ Adding $domain to /etc/hosts"
    echo "$SERVER_IP $domain" | sudo tee -a /etc/hosts
done

# Verify all entries were added
echo ""
echo "✅ Hosts file updated successfully!"
echo "📄 Current entries:"
grep "soject.com" /etc/hosts

echo ""
echo "🧪 Testing DNS resolution..."
for domain in "${DOMAINS[@]}"; do
    if nslookup "$domain" > /dev/null 2>&1; then
        echo "✅ DNS resolution works for $domain"
    else
        echo "❌ DNS resolution failed for $domain"
    fi
done

echo ""
echo "🌐 Testing HTTP connections..."
for domain in "${DOMAINS[@]}"; do
    echo "🔗 Testing $domain..."
    if curl -s --connect-timeout 5 "http://$domain" > /dev/null 2>&1; then
        echo "✅ $domain is accessible"
        echo "📄 Response: $(curl -s "http://$domain" | head -1)"
    else
        echo "❌ $domain is not accessible"
    fi
done

echo ""
echo "🔧 Checking nginx configuration..."
if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    docker-compose exec nginx nginx -t
fi

echo ""
echo "🎉 All domains setup complete!"
echo ""
echo "📋 Available services:"
echo "   🌐 Web App:     http://app.soject.com"
echo "   🐳 Portainer:   http://docker.soject.com"
echo "   📦 GitLab:      http://gitlab.soject.com"
echo ""
echo "📋 Test endpoints:"
echo "   curl http://app.soject.com/health"
echo "   curl http://docker.soject.com/health"
echo "   curl http://gitlab.soject.com/health"
echo ""
echo "📝 Note: These changes are local to this server."
echo "   For production, configure DNS records for each domain." 