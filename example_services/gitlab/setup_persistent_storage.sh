#!/bin/bash

# GitLab Persistent Storage Setup Script
# This script creates the necessary directories for persistent GitLab data

set -e

echo "=== GitLab Persistent Storage Setup ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Create GitLab data directories
print_status "Creating GitLab persistent storage directories..."

directories=(
    "gitlab/config"
    "gitlab/logs"
    "gitlab/data"
    "gitlab/backups"
    "gitlab/redis"
    "gitlab/postgres"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    else
        print_status "Directory already exists: $dir"
    fi
done

# Set proper permissions for GitLab
print_status "Setting proper permissions for GitLab directories..."

# GitLab requires specific ownership and permissions
# Note: These will be set by the container, but we ensure the directories exist

# Create a backup script
print_status "Creating backup script..."
cat > backup_gitlab.sh << 'EOF'
#!/bin/bash

# GitLab Backup Script
# This script creates a backup of all GitLab data

BACKUP_DIR="./gitlab/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="gitlab_backup_$DATE.tar.gz"

echo "Creating GitLab backup: $BACKUP_NAME"

# Stop GitLab container
echo "Stopping GitLab container..."
docker-compose stop gitlab

# Wait a moment for graceful shutdown
sleep 10

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    gitlab/config \
    gitlab/data \
    gitlab/postgres \
    gitlab/redis

# Start GitLab container
echo "Starting GitLab container..."
docker-compose start gitlab

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME"
echo "Backup size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
EOF

chmod +x backup_gitlab.sh

# Create a restore script
print_status "Creating restore script..."
cat > restore_gitlab.sh << 'EOF'
#!/bin/bash

# GitLab Restore Script
# Usage: ./restore_gitlab.sh <backup_file>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la gitlab/backups/
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring GitLab from backup: $BACKUP_FILE"

# Stop all containers
echo "Stopping all containers..."
docker-compose down

# Remove existing data (backup first)
echo "Creating backup of current data before restore..."
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "gitlab/backups/pre_restore_backup_$DATE.tar.gz" \
    gitlab/config \
    gitlab/data \
    gitlab/postgres \
    gitlab/redis

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE"

# Start containers
echo "Starting containers..."
docker-compose up -d

echo "Restore completed!"
echo "GitLab should be available in a few minutes."
EOF

chmod +x restore_gitlab.sh

# Create a data migration script for existing named volumes
print_status "Creating data migration script..."
cat > migrate_gitlab_data.sh << 'EOF'
#!/bin/bash

# GitLab Data Migration Script
# This script migrates data from Docker named volumes to host directories

echo "=== GitLab Data Migration ==="

# Check if GitLab is running
if docker ps | grep -q gitlab; then
    echo "Stopping GitLab containers..."
    docker-compose down
fi

# Check for existing named volumes
VOLUMES=("gitlab_config" "gitlab_logs" "gitlab_data" "gitlab_redis_data" "gitlab_postgres_data")

for volume in "${VOLUMES[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo "Found existing volume: $volume"
        echo "Creating temporary container to copy data..."
        
        # Create temporary container to copy data
        docker run --rm -v "$volume":/source -v "$(pwd)/gitlab":/dest alpine sh -c "
            case '$volume' in
                'gitlab_config')
                    cp -r /source/* /dest/config/ 2>/dev/null || true
                    ;;
                'gitlab_logs')
                    cp -r /source/* /dest/logs/ 2>/dev/null || true
                    ;;
                'gitlab_data')
                    cp -r /source/* /dest/data/ 2>/dev/null || true
                    ;;
                'gitlab_redis_data')
                    cp -r /source/* /dest/redis/ 2>/dev/null || true
                    ;;
                'gitlab_postgres_data')
                    cp -r /source/* /dest/postgres/ 2>/dev/null || true
                    ;;
            esac
        "
        
        echo "Data migrated from volume: $volume"
        
        # Ask if user wants to remove the old volume
        read -p "Remove old volume $volume? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker volume rm "$volume"
            echo "Removed volume: $volume"
        fi
    else
        echo "No existing volume found: $volume"
    fi
done

echo "Migration completed!"
echo "You can now start GitLab with: docker-compose up -d"
EOF

chmod +x migrate_gitlab_data.sh

# Create a monitoring script
print_status "Creating monitoring script..."
cat > monitor_gitlab.sh << 'EOF'
#!/bin/bash

# GitLab Monitoring Script

echo "=== GitLab Status ==="

# Check container status
echo "Container Status:"
docker-compose ps

echo ""
echo "Disk Usage:"
du -sh gitlab/*

echo ""
echo "Recent Logs:"
docker-compose logs --tail=20 gitlab

echo ""
echo "Health Check:"
if docker-compose exec -T gitlab /opt/gitlab/bin/gitlab-healthcheck --fail; then
    echo "✓ GitLab is healthy"
else
    echo "✗ GitLab health check failed"
fi
EOF

chmod +x monitor_gitlab.sh

print_status "GitLab persistent storage setup completed!"
echo ""
echo "Created scripts:"
echo "- backup_gitlab.sh - Create backups of GitLab data"
echo "- restore_gitlab.sh - Restore GitLab from backup"
echo "- migrate_gitlab_data.sh - Migrate from Docker volumes"
echo "- monitor_gitlab.sh - Monitor GitLab status"
echo ""
echo "Next steps:"
echo "1. If you have existing GitLab data in Docker volumes, run: ./migrate_gitlab_data.sh"
echo "2. Start GitLab: docker-compose up -d"
echo "3. Monitor status: ./monitor_gitlab.sh"
echo ""
echo "Backup schedule recommendation:"
echo "- Daily backups for active installations"
echo "- Weekly backups for development environments"
echo "- Store backups in a separate location" 