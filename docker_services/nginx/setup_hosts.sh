#!/bin/bash

# Setup hosts file for app.soject.com
# This script adds app.soject.com to the local hosts file

set -e

echo "🔧 Setting up hosts file for app.soject.com..."

# Get the server IP address
echo "📡 Detecting server IP address..."
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "✅ Server IP: $SERVER_IP"

# Check if app.soject.com is already in hosts file
if grep -q "app.soject.com" /etc/hosts; then
    echo "⚠️  app.soject.com already exists in /etc/hosts"
    echo "📄 Current entry:"
    grep "app.soject.com" /etc/hosts
    echo ""
    read -p "Do you want to update it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove existing entry
        sudo sed -i '/app\.soject\.com/d' /etc/hosts
        echo "🗑️  Removed existing entry"
    else
        echo "❌ Aborted"
        exit 1
    fi
fi

# Add new entry to hosts file
echo "➕ Adding app.soject.com to /etc/hosts..."
echo "$SERVER_IP app.soject.com" | sudo tee -a /etc/hosts

# Verify the entry was added
if grep -q "app.soject.com" /etc/hosts; then
    echo "✅ Successfully added app.soject.com to /etc/hosts"
    echo "📄 New entry:"
    grep "app.soject.com" /etc/hosts
else
    echo "❌ Failed to add entry to /etc/hosts"
    exit 1
fi

echo ""
echo "🧪 Testing the setup..."

# Test DNS resolution
if nslookup app.soject.com > /dev/null 2>&1; then
    echo "✅ DNS resolution works for app.soject.com"
else
    echo "❌ DNS resolution failed for app.soject.com"
fi

# Test HTTP connection
sleep 2
if curl -s --connect-timeout 5 http://app.soject.com > /dev/null 2>&1; then
    echo "✅ app.soject.com is now accessible"
    echo "📄 Response: $(curl -s http://app.soject.com)"
else
    echo "❌ app.soject.com is still not accessible"
    echo "🔍 Checking if nginx is running..."
    if docker-compose ps | grep -q "Up"; then
        echo "✅ Nginx is running"
    else
        echo "❌ Nginx is not running"
    fi
fi

echo ""
echo "🎉 Hosts file setup complete!"
echo ""
echo "📋 You can now test:"
echo "   curl http://app.soject.com"
echo "   curl http://app.soject.com/health"
echo "   curl http://app.soject.com/test"
echo ""
echo "📝 Note: This change is local to this server."
echo "   For production, you'll need to configure DNS records." 