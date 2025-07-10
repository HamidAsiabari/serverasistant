#!/bin/bash

# Test all domain mappings for ServerAssistant
echo "🧪 Testing all domain mappings..."

# Define all domains to test
domains=(
    "app.soject.com"
    "docker.soject.com"
    "gitlab.soject.com"
    "admin.soject.com"
    "mail.soject.com"
)

# Test each domain
for domain in "${domains[@]}"; do
    echo ""
    echo "🔍 Testing: $domain"
    echo "   URL: http://$domain"
    
    # Test HTTP response
    if curl -s -o /dev/null -w "%{http_code}" "http://$domain" | grep -q "200\|301\|302"; then
        echo "   ✅ HTTP response: OK"
        
        # Get page title for verification
        title=$(curl -s "http://$domain" | grep -i "<title>" | head -1 | sed 's/.*<title>\(.*\)<\/title>.*/\1/')
        if [ ! -z "$title" ]; then
            echo "   📄 Title: $title"
        fi
    else
        echo "   ❌ HTTP response: Failed"
        echo "   📋 Checking if service is running..."
        
        # Check if the corresponding service is running
        case $domain in
            "app.soject.com")
                if docker ps | grep -q "web-app"; then
                    echo "   ✅ web-app is running"
                else
                    echo "   ❌ web-app is not running"
                fi
                ;;
            "docker.soject.com")
                if docker ps | grep -q "portainer"; then
                    echo "   ✅ portainer is running"
                else
                    echo "   ❌ portainer is not running"
                fi
                ;;
            "gitlab.soject.com")
                if docker ps | grep -q "gitlab"; then
                    echo "   ✅ gitlab is running"
                else
                    echo "   ❌ gitlab is not running"
                fi
                ;;
            "admin.soject.com")
                if docker ps | grep -q "phpmyadmin"; then
                    echo "   ✅ phpmyadmin is running"
                else
                    echo "   ❌ phpmyadmin is not running"
                fi
                ;;
            "mail.soject.com")
                if docker ps | grep -q "roundcube"; then
                    echo "   ✅ roundcube is running"
                else
                    echo "   ❌ roundcube is not running"
                fi
                ;;
        esac
    fi
done

echo ""
echo "🔍 Checking nginx configuration..."
if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    docker-compose exec nginx nginx -t
fi

echo ""
echo "📋 Checking running containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🎉 Domain testing complete!" 