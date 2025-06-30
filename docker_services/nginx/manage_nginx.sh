#!/bin/bash

# Nginx Management Script
# Provides easy commands for common nginx operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "Nginx Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       - Start nginx reverse proxy"
    echo "  stop        - Stop nginx reverse proxy"
    echo "  restart     - Restart nginx reverse proxy"
    echo "  status      - Show nginx status"
    echo "  logs        - Show nginx logs (follow)"
    echo "  logs-tail   - Show last 100 lines of logs"
    echo "  test        - Test nginx configuration"
    echo "  ssl         - Regenerate SSL certificates"
    echo "  health      - Check health of all services"
    echo "  backup      - Backup current configuration"
    echo "  cleanup     - Clean up old configurations"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs"
    echo "  $0 health"
}

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

start_nginx() {
    print_status "Starting nginx reverse proxy..."
    check_docker
    docker-compose up -d
    sleep 3
    if docker ps | grep -q nginx-proxy; then
        print_success "Nginx started successfully!"
    else
        print_error "Failed to start nginx"
        docker-compose logs
        exit 1
    fi
}

stop_nginx() {
    print_status "Stopping nginx reverse proxy..."
    check_docker
    docker-compose down
    print_success "Nginx stopped successfully!"
}

restart_nginx() {
    print_status "Restarting nginx reverse proxy..."
    check_docker
    docker-compose restart
    sleep 3
    if docker ps | grep -q nginx-proxy; then
        print_success "Nginx restarted successfully!"
    else
        print_error "Failed to restart nginx"
        exit 1
    fi
}

show_status() {
    print_status "Nginx Status:"
    echo ""
    if docker ps | grep -q nginx-proxy; then
        print_success "Nginx is running"
        docker ps --filter name=nginx-proxy --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        print_status "Service URLs:"
        echo "  - Web App:     https://app.soject.com"
        echo "  - phpMyAdmin:  https://admin.soject.com"
        echo "  - Portainer:   https://docker.soject.com"
        echo "  - GitLab:      https://gitlab.soject.com"
        echo "  - Mail:        https://mail.soject.com"
    else
        print_warning "Nginx is not running"
    fi
}

show_logs() {
    print_status "Showing nginx logs (press Ctrl+C to stop)..."
    check_docker
    docker-compose logs -f nginx-proxy
}

show_logs_tail() {
    print_status "Showing last 100 lines of nginx logs..."
    check_docker
    docker-compose logs --tail 100 nginx-proxy
}

test_config() {
    print_status "Testing nginx configuration..."
    check_docker
    if docker exec nginx-proxy nginx -t; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration has errors"
        exit 1
    fi
}

regenerate_ssl() {
    print_status "Regenerating SSL certificates..."
    if [ -f "generate_ssl.sh" ]; then
        chmod +x generate_ssl.sh
        ./generate_ssl.sh
        chmod 600 ssl/*.key
        chmod 644 ssl/*.crt
        print_success "SSL certificates regenerated"
        print_status "Restarting nginx to apply new certificates..."
        restart_nginx
    else
        print_error "generate_ssl.sh not found"
        exit 1
    fi
}

check_health() {
    print_status "Checking health of all services..."
    echo ""
    
    # Check nginx container
    if docker ps | grep -q nginx-proxy; then
        print_success "✓ Nginx container is running"
    else
        print_error "✗ Nginx container is not running"
    fi
    
    # Test HTTP access
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|301\|302"; then
        print_success "✓ HTTP access working (port 80)"
    else
        print_warning "✗ HTTP access failed (port 80)"
    fi
    
    # Test HTTPS access
    if curl -s -k -o /dev/null -w "%{http_code}" https://localhost:443 | grep -q "200\|301\|302"; then
        print_success "✓ HTTPS access working (port 443)"
    else
        print_warning "✗ HTTPS access failed (port 443)"
    fi
    
    # Check SSL certificates
    if [ -f "ssl/app.soject.com.crt" ] && [ -f "ssl/app.soject.com.key" ]; then
        print_success "✓ SSL certificates exist"
    else
        print_warning "✗ SSL certificates missing"
    fi
    
    # Check configuration files
    required_files=(
        "config/nginx.conf"
        "config/conf.d/default.conf"
        "config/conf.d/app.soject.com.conf"
        "config/conf.d/admin.soject.com.conf"
        "config/conf.d/docker.soject.com.conf"
        "config/conf.d/gitlab.soject.com.conf"
        "config/conf.d/mail.soject.com.conf"
    )
    
    echo ""
    print_status "Configuration files:"
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "✓ $file"
        else
            print_error "✗ $file"
        fi
    done
}

backup_config() {
    print_status "Creating backup of current configuration..."
    BACKUP_FILE="nginx-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$BACKUP_FILE" config/ ssl/ docker-compose.yml generate_ssl.sh
    print_success "Backup created: $BACKUP_FILE"
}

cleanup_old() {
    print_status "Cleaning up old configurations..."
    if [ -f "cleanup_old_configs.sh" ]; then
        chmod +x cleanup_old_configs.sh
        ./cleanup_old_configs.sh
        print_success "Cleanup completed"
    else
        print_warning "cleanup_old_configs.sh not found"
    fi
}

# Main script logic
case "${1:-help}" in
    start)
        start_nginx
        ;;
    stop)
        stop_nginx
        ;;
    restart)
        restart_nginx
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    logs-tail)
        show_logs_tail
        ;;
    test)
        test_config
        ;;
    ssl)
        regenerate_ssl
        ;;
    health)
        check_health
        ;;
    backup)
        backup_config
        ;;
    cleanup)
        cleanup_old
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 