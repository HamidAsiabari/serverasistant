#!/bin/bash

# Simple setup for docker.soject.com domain
echo "🔧 Setting up docker.soject.com domain..."

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📡 Server IP: $SERVER_IP"

# Remove existing entry if it exists
if grep -q "docker.soject.com" /etc/hosts; then
    echo "🗑️  Removing existing entry for docker.soject.com"
    sudo sed -i '/docker\.soject\.com/d' /etc/hosts
fi

# Add new entry
echo "➕ Adding docker.soject.com to /etc/hosts"
echo "$SERVER_IP docker.soject.com" | sudo tee -a /etc/hosts

echo "✅ Setup complete!"
echo "📋 Test with: curl http://docker.soject.com" 