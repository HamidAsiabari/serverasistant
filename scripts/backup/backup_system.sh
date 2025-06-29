#!/bin/bash

# Comprehensive Backup System for Docker Services
# This script creates backups of all persistent data across all services

set -e

echo "=== Comprehensive Backup System ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[HEADER]${NC} $1"
}

# Configuration
BACKUP_ROOT="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="server_backup_$DATE"
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_NAME"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

print_header "Starting comprehensive backup: $BACKUP_NAME"

# Function to backup a service
backup_service() {
    local service_name=$1
    local service_path=$2
    local description=$3
    
    print_status "Backing up $description..."
    
    if [ -d "$service_path" ]; then
        # Create service backup directory
        local service_backup_dir="$BACKUP_DIR/$service_name"
        mkdir -p "$service_backup_dir"
        
        # Create tar archive
        tar -czf "$service_backup_dir/data.tar.gz" -C "$(dirname "$service_path")" "$(basename "$service_path")"
        
        # Create metadata
        cat > "$service_backup_dir/metadata.txt" << EOF
Service: $service_name
Description: $description
Backup Date: $(date)
Source Path: $service_path
Backup Size: $(du -h "$service_backup_dir/data.tar.gz" | cut -f1)
EOF
        
        print_status "✓ $description backed up successfully"
    else
        print_warning "Service directory not found: $service_path"
    fi
}

# Function to backup configuration files
backup_configs() {
    print_status "Backing up configuration files..."
    
    local config_backup_dir="$BACKUP_DIR/configs"
    mkdir -p "$config_backup_dir"
    
    # Backup main configuration files
    cp config.json "$config_backup_dir/" 2>/dev/null || true
    cp test_config_ubuntu22.json "$config_backup_dir/" 2>/dev/null || true
    
    # Backup Nginx configurations
    if [ -d "example_services/nginx" ]; then
        mkdir -p "$config_backup_dir/nginx"
        cp -r example_services/nginx/config "$config_backup_dir/nginx/" 2>/dev/null || true
        cp example_services/nginx/docker-compose.yml "$config_backup_dir/nginx/" 2>/dev/null || true
    fi
    
    # Backup SSL certificates
    if [ -d "example_services/nginx/ssl" ]; then
        mkdir -p "$config_backup_dir/ssl"
        cp -r example_services/nginx/ssl "$config_backup_dir/" 2>/dev/null || true
    fi
    
    print_status "✓ Configuration files backed up"
}

# Function to backup Docker volumes (if any still exist)
backup_volumes() {
    print_status "Checking for Docker volumes..."
    
    local volumes_backup_dir="$BACKUP_DIR/volumes"
    mkdir -p "$volumes_backup_dir"
    
    # List all volumes
    docker volume ls --format "{{.Name}}" | while read volume; do
        if [ -n "$volume" ]; then
            print_status "Backing up volume: $volume"
            
            # Create temporary container to backup volume
            docker run --rm -v "$volume":/source -v "$(pwd)/$volumes_backup_dir":/backup alpine sh -c "
                tar -czf /backup/${volume}.tar.gz -C /source .
            "
            
            print_status "✓ Volume $volume backed up"
        fi
    done
}

# Function to create system information
create_system_info() {
    print_status "Creating system information..."
    
    local system_info_dir="$BACKUP_DIR/system_info"
    mkdir -p "$system_info_dir"
    
    # System information
    uname -a > "$system_info_dir/system.txt"
    docker --version >> "$system_info_dir/system.txt"
    docker-compose --version >> "$system_info_dir/system.txt"
    
    # Docker information
    docker info > "$system_info_dir/docker_info.txt"
    docker ps -a > "$system_info_dir/containers.txt"
    docker volume ls > "$system_info_dir/volumes.txt"
    docker network ls > "$system_info_dir/networks.txt"
    
    # Disk usage
    df -h > "$system_info_dir/disk_usage.txt"
    du -sh ./* > "$system_info_dir/directory_sizes.txt"
    
    print_status "✓ System information collected"
}

# Main backup process
main_backup() {
    print_header "Starting backup process..."
    
    # Stop services gracefully (optional - comment out if you want to backup while running)
    print_warning "Stopping services for consistent backup..."
    docker-compose -f example_services/gitlab/docker-compose.yml down 2>/dev/null || true
    docker-compose -f example_services/mail-server/docker-compose.yml down 2>/dev/null || true
    
    # Wait for graceful shutdown
    sleep 10
    
    # Backup services
    backup_service "gitlab" "example_services/gitlab/gitlab" "GitLab Data"
    backup_service "mail" "example_services/mail-server/mail" "Mail Server Data"
    backup_service "mysql" "example_services/mysql/mysql" "MySQL Data"
    backup_service "postgres" "example_services/database/postgres" "PostgreSQL Data"
    backup_service "redis" "example_services/database/redis" "Redis Data"
    
    # Backup configurations
    backup_configs
    
    # Backup volumes (if any)
    backup_volumes
    
    # Create system information
    create_system_info
    
    # Create backup manifest
    print_status "Creating backup manifest..."
    cat > "$BACKUP_DIR/manifest.txt" << EOF
Backup Information
==================

Backup Name: $BACKUP_NAME
Backup Date: $(date)
Backup Location: $BACKUP_DIR
Total Size: $(du -sh "$BACKUP_DIR" | cut -f1)

Services Backed Up:
- GitLab (repositories, users, configurations)
- Mail Server (emails, database, configurations)
- MySQL Database
- PostgreSQL Database
- Redis Cache
- Nginx Configurations
- SSL Certificates
- System Information

Restore Instructions:
1. Stop all services
2. Extract backup: tar -xzf $BACKUP_NAME.tar.gz
3. Restore data to appropriate directories
4. Start services: docker-compose up -d

Backup created by: $(whoami)
System: $(uname -a)
EOF
    
    # Restart services
    print_status "Restarting services..."
    docker-compose -f example_services/gitlab/docker-compose.yml up -d 2>/dev/null || true
    docker-compose -f example_services/mail-server/docker-compose.yml up -d 2>/dev/null || true
    
    # Create final archive
    print_status "Creating final backup archive..."
    cd "$BACKUP_ROOT"
    tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
    
    # Calculate final size
    FINAL_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
    
    print_status "✓ Backup completed successfully!"
    print_status "Backup location: $BACKUP_ROOT/${BACKUP_NAME}.tar.gz"
    print_status "Backup size: $FINAL_SIZE"
    
    # Cleanup old backups
    cleanup_old_backups
}

# Function to cleanup old backups
cleanup_old_backups() {
    print_status "Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    find "$BACKUP_ROOT" -name "server_backup_*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
    find "$BACKUP_ROOT" -name "server_backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
    
    print_status "✓ Old backups cleaned up"
}

# Function to list available backups
list_backups() {
    print_header "Available Backups:"
    
    if [ -d "$BACKUP_ROOT" ]; then
        ls -la "$BACKUP_ROOT" | grep "server_backup_" || echo "No backups found"
    else
        echo "Backup directory not found"
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file to restore"
        echo "Usage: $0 restore <backup_file>"
        echo "Available backups:"
        list_backups
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_header "Restoring from backup: $backup_file"
    
    # Create restore directory
    local restore_dir="./restore_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$restore_dir"
    
    # Extract backup
    print_status "Extracting backup..."
    tar -xzf "$backup_file" -C "$restore_dir"
    
    # Stop all services
    print_status "Stopping all services..."
    docker-compose -f example_services/gitlab/docker-compose.yml down 2>/dev/null || true
    docker-compose -f example_services/mail-server/docker-compose.yml down 2>/dev/null || true
    
    # Restore data
    print_status "Restoring data..."
    
    # Find the extracted backup directory
    local extracted_dir=$(find "$restore_dir" -name "server_backup_*" -type d | head -1)
    
    if [ -n "$extracted_dir" ]; then
        # Restore GitLab data
        if [ -f "$extracted_dir/gitlab/data.tar.gz" ]; then
            print_status "Restoring GitLab data..."
            tar -xzf "$extracted_dir/gitlab/data.tar.gz" -C "example_services/gitlab/"
        fi
        
        # Restore mail server data
        if [ -f "$extracted_dir/mail/data.tar.gz" ]; then
            print_status "Restoring mail server data..."
            tar -xzf "$extracted_dir/mail/data.tar.gz" -C "example_services/mail-server/"
        fi
        
        # Restore configurations
        if [ -d "$extracted_dir/configs" ]; then
            print_status "Restoring configurations..."
            cp -r "$extracted_dir/configs"/* . 2>/dev/null || true
        fi
        
        print_status "✓ Restore completed successfully!"
        print_status "You can now start your services"
    else
        print_error "Could not find extracted backup data"
        exit 1
    fi
    
    # Cleanup restore directory
    rm -rf "$restore_dir"
}

# Main script logic
case "${1:-backup}" in
    "backup")
        main_backup
        ;;
    "list")
        list_backups
        ;;
    "restore")
        restore_backup "$2"
        ;;
    "cleanup")
        cleanup_old_backups
        ;;
    *)
        echo "Usage: $0 [backup|list|restore <file>|cleanup]"
        echo ""
        echo "Commands:"
        echo "  backup   - Create a comprehensive backup (default)"
        echo "  list     - List available backups"
        echo "  restore  - Restore from backup file"
        echo "  cleanup  - Clean up old backups"
        echo ""
        echo "Examples:"
        echo "  $0 backup"
        echo "  $0 list"
        echo "  $0 restore ./backups/server_backup_20231201_120000.tar.gz"
        echo "  $0 cleanup"
        exit 1
        ;;
esac 