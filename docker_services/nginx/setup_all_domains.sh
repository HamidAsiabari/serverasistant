#!/bin/bash

# Setup all domain mappings for ServerAssistant
echo "🔧 Setting up all domain mappings..."

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "📡 Server IP: $SERVER_IP"

# Define all domains and their descriptions
declare -A domains=(
    ["app.soject.com"]="Web Application"
    ["docker.soject.com"]="Portainer (Docker Management)"
    ["gitlab.soject.com"]="GitLab (Git Repository)"
    ["admin.soject.com"]="phpMyAdmin (Database Management)"
    ["mail.soject.com"]="Roundcube (Webmail)"
)

# Remove existing entries for all domains
echo "🗑️  Removing existing entries..."
for domain in "${!domains[@]}"; do
    if grep -q "$domain" /etc/hosts; then
        echo "   Removing: $domain"
        sudo sed -i "/$domain/d" /etc/hosts
    fi
done

# Add new entries for all domains
echo "➕ Adding domain mappings..."
for domain in "${!domains[@]}"; do
    echo "$SERVER_IP $domain" | sudo tee -a /etc/hosts
    echo "   Added: $domain → ${domains[$domain]}"
done

echo ""
echo "✅ All domain mappings setup complete!"
echo ""
echo "📋 Domain mappings:"
for domain in "${!domains[@]}"; do
    echo "   http://$domain → ${domains[$domain]}"
done
echo ""
echo "🌐 Test the domains:"
echo "   curl http://app.soject.com"
echo "   curl http://docker.soject.com"
echo "   curl http://gitlab.soject.com"
echo "   curl http://admin.soject.com"
echo "   curl http://mail.soject.com" 