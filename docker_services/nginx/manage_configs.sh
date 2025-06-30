#!/bin/bash

# Nginx configuration management script
# This script helps switch between different nginx configurations

set -e

echo "🔧 Nginx Configuration Manager"

# Function to show current configuration
show_current_config() {
    echo "📁 Current active configuration files:"
    ls -la conf.d/*.conf 2>/dev/null || echo "No .conf files found"
    echo ""
}

# Function to backup current config
backup_config() {
    echo "💾 Creating backup of current configuration..."
    BACKUP_DIR="conf.d/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp conf.d/*.conf "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created in $BACKUP_DIR"
    echo ""
}

# Function to enable simple configuration
enable_simple() {
    echo "🔄 Enabling simple configuration..."
    backup_config
    
    # Remove all existing configs
    rm -f conf.d/*.conf
    
    # Copy simple config
    cp conf.d/app.soject.com.conf.backup conf.d/app.soject.com.conf 2>/dev/null || {
        echo "❌ Simple config backup not found"
        exit 1
    }
    
    echo "✅ Simple configuration enabled"
}

# Function to enable service configurations
enable_services() {
    echo "🔄 Enabling service configurations..."
    backup_config
    
    # Remove all existing configs
    rm -f conf.d/*.conf
    
    # Copy service configs
    cp conf.d/app.soject.com.conf.backup conf.d/app.soject.com.conf 2>/dev/null || true
    cp conf.d/docker.soject.com.conf.backup conf.d/docker.soject.com.conf 2>/dev/null || true
    cp conf.d/gitlab.soject.com.conf.backup conf.d/gitlab.soject.com.conf 2>/dev/null || true
    
    echo "✅ Service configurations enabled"
}

# Function to enable multi-domain configuration
enable_multi_domain() {
    echo "🔄 Enabling multi-domain configuration..."
    backup_config
    
    # Remove all existing configs
    rm -f conf.d/*.conf
    
    # Copy multi-domain config
    cp conf.d/multi-domain.conf.backup conf.d/multi-domain.conf 2>/dev/null || {
        echo "❌ Multi-domain config backup not found"
        exit 1
    }
    
    echo "✅ Multi-domain configuration enabled"
}

# Function to restart nginx
restart_nginx() {
    echo "🔄 Restarting nginx..."
    docker-compose restart nginx
    
    # Wait for nginx to start
    sleep 5
    
    # Test configuration
    if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration is invalid"
        docker-compose exec nginx nginx -t
        exit 1
    fi
}

# Main menu
while true; do
    echo ""
    echo "📋 Configuration Options:"
    echo "1) Show current configuration"
    echo "2) Enable simple configuration (app.soject.com only)"
    echo "3) Enable service configurations (all services)"
    echo "4) Enable multi-domain configuration (fallback for all)"
    echo "5) Restart nginx"
    echo "6) Test all domains"
    echo "7) Exit"
    echo ""
    read -p "Select option (1-7): " choice
    
    case $choice in
        1)
            show_current_config
            ;;
        2)
            enable_simple
            restart_nginx
            ;;
        3)
            enable_services
            restart_nginx
            ;;
        4)
            enable_multi_domain
            restart_nginx
            ;;
        5)
            restart_nginx
            ;;
        6)
            echo "🧪 Testing all domains..."
            for domain in app.soject.com docker.soject.com gitlab.soject.com; do
                echo "🔗 Testing $domain..."
                if curl -s --connect-timeout 5 "http://$domain" > /dev/null 2>&1; then
                    echo "✅ $domain is accessible"
                else
                    echo "❌ $domain is not accessible"
                fi
            done
            ;;
        7)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid option. Please select 1-7."
            ;;
    esac
done 