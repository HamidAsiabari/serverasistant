#!/bin/bash

echo "🔧 Fixing nginx configuration for running services only..."

# Stop nginx first
echo "🛑 Stopping nginx..."
docker-compose down

# Clear existing config files
echo "🧹 Clearing existing configuration files..."
rm -f conf.d/*.conf

# Function to check if a service is running
is_service_running() {
    local service_name=$1
    docker ps --format "{{.Names}}" | grep -q "^${service_name}$"
}

# Function to check if a service is connected to web_network
is_service_on_web_network() {
    local service_name=$1
    docker network inspect web_network 2>/dev/null | grep -q "\"${service_name}\""
}

# Create configuration only for running services
echo "📝 Creating nginx configuration for running services..."

# Always create docker.soject.com config (Portainer)
echo "✅ Creating docker.soject.com config (Portainer)"
cat > conf.d/docker.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name docker.soject.com;

    location / {
        proxy_pass http://portainer:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Portainer
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Portainer specific settings
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# Check and create gitlab.soject.com config
if is_service_running "gitlab" && is_service_on_web_network "gitlab"; then
    echo "✅ Creating gitlab.soject.com config (GitLab)"
    cat > conf.d/gitlab.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name gitlab.soject.com;

    location / {
        proxy_pass http://gitlab:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # GitLab specific headers
        proxy_set_header X-GitLab-Event $http_x_gitlab_event;
        proxy_set_header X-GitLab-Token $http_x_gitlab_token;
        
        # Large file uploads for GitLab
        client_max_body_size 500M;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF
else
    echo "⚠️  Skipping gitlab.soject.com config (GitLab not running or not on web_network)"
fi

# Check and create app.soject.com config
if is_service_running "web-app" && is_service_on_web_network "web-app"; then
    echo "✅ Creating app.soject.com config (Web App)"
    cat > conf.d/app.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name app.soject.com;

    location / {
        proxy_pass http://web-app:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://web-app:8080/health;
        proxy_set_header Host $host;
        access_log off;
    }
}
EOF
else
    echo "⚠️  Skipping app.soject.com config (Web App not running or not on web_network)"
fi

# Check and create admin.soject.com config
if is_service_running "phpmyadmin" && is_service_on_web_network "phpmyadmin"; then
    echo "✅ Creating admin.soject.com config (phpMyAdmin)"
    cat > conf.d/admin.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name admin.soject.com;

    location / {
        proxy_pass http://phpmyadmin:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
else
    echo "⚠️  Skipping admin.soject.com config (phpMyAdmin not running or not on web_network)"
fi

# Check and create mail.soject.com config
if is_service_running "roundcube" && is_service_on_web_network "roundcube"; then
    echo "✅ Creating mail.soject.com config (Roundcube)"
    cat > conf.d/mail.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name mail.soject.com;

    location / {
        proxy_pass http://roundcube:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
else
    echo "⚠️  Skipping mail.soject.com config (Roundcube not running or not on web_network)"
fi

# Show created configurations
echo ""
echo "📋 Created nginx configurations:"
ls -la conf.d/*.conf 2>/dev/null || echo "   No configuration files created"

# Test nginx configuration
echo ""
echo "🧪 Testing nginx configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    docker-compose config
    exit 1
fi

# Start nginx
echo ""
echo "🚀 Starting nginx..."
docker-compose up -d

# Wait for nginx to start
echo "⏳ Waiting for nginx to start..."
sleep 5

# Check if nginx is running
if docker ps | grep -q "nginx"; then
    echo "✅ Nginx is running successfully!"
    
    # Test nginx configuration
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
    exit 1
fi

echo ""
echo "🎉 Nginx configuration fix complete!"
echo ""
echo "📋 Available domains:"
for config in conf.d/*.conf; do
    if [ -f "$config" ]; then
        domain=$(grep "server_name" "$config" | awk '{print $2}' | sed 's/;$//')
        echo "   http://$domain"
    fi
done 