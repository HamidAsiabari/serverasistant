#!/bin/bash

# Mail Server Persistent Storage Setup Script
# This script creates the necessary directories for persistent mail server data

set -e

echo "=== Mail Server Persistent Storage Setup ==="

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

# Create mail server data directories
print_status "Creating mail server persistent storage directories..."

directories=(
    "mail/data"
    "mail/queue"
    "mail/database"
    "roundcube/data"
    "spamassassin/data"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    else
        print_status "Directory already exists: $dir"
    fi
done

# Set proper permissions for mail data
print_status "Setting proper permissions for mail directories..."

# Mail data needs specific permissions for postfix and dovecot
chmod 755 mail/data
chmod 755 mail/queue
chmod 755 mail/database

print_status "Permissions set for mail directories"

# Create a backup script
print_status "Creating backup script..."
cat > backup_mail.sh << 'EOF'
#!/bin/bash

# Mail Server Backup Script
# This script creates a backup of all mail server data

BACKUP_DIR="./mail/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mail_backup_$DATE.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "Creating mail server backup: $BACKUP_NAME"

# Stop mail server containers
echo "Stopping mail server containers..."
docker-compose stop

# Wait a moment for graceful shutdown
sleep 10

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" \
    mail/data \
    mail/database \
    roundcube/data \
    spamassassin/data \
    postfix/config \
    dovecot/config \
    roundcube/config \
    spamassassin/config

# Start mail server containers
echo "Starting mail server containers..."
docker-compose up -d

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME"
echo "Backup size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
EOF

chmod +x backup_mail.sh

# Create a restore script
print_status "Creating restore script..."
cat > restore_mail.sh << 'EOF'
#!/bin/bash

# Mail Server Restore Script
# Usage: ./restore_mail.sh <backup_file>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup_file>"
    echo "Available backups:"
    ls -la mail/backups/ 2>/dev/null || echo "No backups directory found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Restoring mail server from backup: $BACKUP_FILE"

# Stop all containers
echo "Stopping all containers..."
docker-compose down

# Create backup directory if it doesn't exist
mkdir -p mail/backups

# Remove existing data (backup first)
echo "Creating backup of current data before restore..."
DATE=$(date +%Y%m%d_%H%M%S)
tar -czf "mail/backups/pre_restore_backup_$DATE.tar.gz" \
    mail/data \
    mail/database \
    roundcube/data \
    spamassassin/data \
    postfix/config \
    dovecot/config \
    roundcube/config \
    spamassassin/config

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE"

# Start containers
echo "Starting containers..."
docker-compose up -d

echo "Restore completed!"
echo "Mail server should be available in a few minutes."
EOF

chmod +x restore_mail.sh

# Create a data migration script for existing named volumes
print_status "Creating data migration script..."
cat > migrate_mail_data.sh << 'EOF'
#!/bin/bash

# Mail Server Data Migration Script
# This script migrates data from Docker named volumes to host directories

echo "=== Mail Server Data Migration ==="

# Check if mail server is running
if docker ps | grep -q postfix; then
    echo "Stopping mail server containers..."
    docker-compose down
fi

# Check for existing named volumes
VOLUMES=("mail_data" "mail_db_data")

for volume in "${VOLUMES[@]}"; do
    if docker volume ls | grep -q "$volume"; then
        echo "Found existing volume: $volume"
        echo "Creating temporary container to copy data..."
        
        # Create temporary container to copy data
        docker run --rm -v "$volume":/source -v "$(pwd)/mail":/dest alpine sh -c "
            case '$volume' in
                'mail_data')
                    cp -r /source/* /dest/data/ 2>/dev/null || true
                    ;;
                'mail_db_data')
                    cp -r /source/* /dest/database/ 2>/dev/null || true
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
echo "You can now start mail server with: docker-compose up -d"
EOF

chmod +x migrate_mail_data.sh

# Create a monitoring script
print_status "Creating monitoring script..."
cat > monitor_mail.sh << 'EOF'
#!/bin/bash

# Mail Server Monitoring Script

echo "=== Mail Server Status ==="

# Check container status
echo "Container Status:"
docker-compose ps

echo ""
echo "Disk Usage:"
du -sh mail/* 2>/dev/null || echo "No mail data directories found"
du -sh roundcube/data 2>/dev/null || echo "No Roundcube data found"
du -sh spamassassin/data 2>/dev/null || echo "No SpamAssassin data found"

echo ""
echo "Mail Queue Status:"
if [ -d "mail/queue" ]; then
    echo "Mail queue directory exists"
    ls -la mail/queue/ | head -10
else
    echo "Mail queue directory not found"
fi

echo ""
echo "Recent Logs:"
echo "Postfix logs:"
docker-compose logs --tail=10 postfix

echo ""
echo "Dovecot logs:"
docker-compose logs --tail=10 dovecot

echo ""
echo "Roundcube logs:"
docker-compose logs --tail=10 roundcube
EOF

chmod +x monitor_mail.sh

# Create an email test script
print_status "Creating email test script..."
cat > test_mail.sh << 'EOF'
#!/bin/bash

# Mail Server Test Script

echo "=== Testing Mail Server ==="

# Test SMTP connection
echo "Testing SMTP connection..."
if telnet localhost 25 < /dev/null 2>&1 | grep -q "Connected"; then
    echo "✓ SMTP (port 25) is accessible"
else
    echo "✗ SMTP (port 25) is not accessible"
fi

# Test SMTP submission
echo "Testing SMTP submission..."
if telnet localhost 587 < /dev/null 2>&1 | grep -q "Connected"; then
    echo "✓ SMTP submission (port 587) is accessible"
else
    echo "✗ SMTP submission (port 587) is not accessible"
fi

# Test IMAP connection
echo "Testing IMAP connection..."
if telnet localhost 143 < /dev/null 2>&1 | grep -q "Connected"; then
    echo "✓ IMAP (port 143) is accessible"
else
    echo "✗ IMAP (port 143) is not accessible"
fi

# Test IMAPS connection
echo "Testing IMAPS connection..."
if telnet localhost 993 < /dev/null 2>&1 | grep -q "Connected"; then
    echo "✓ IMAPS (port 993) is accessible"
else
    echo "✗ IMAPS (port 993) is not accessible"
fi

# Test Roundcube web interface
echo "Testing Roundcube web interface..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8083 | grep -q "200"; then
    echo "✓ Roundcube web interface is accessible"
else
    echo "✗ Roundcube web interface is not accessible"
fi

echo ""
echo "Mail server test completed!"
EOF

chmod +x test_mail.sh

print_status "Mail server persistent storage setup completed!"
echo ""
echo "Created scripts:"
echo "- backup_mail.sh - Create backups of mail server data"
echo "- restore_mail.sh - Restore mail server from backup"
echo "- migrate_mail_data.sh - Migrate from Docker volumes"
echo "- monitor_mail.sh - Monitor mail server status"
echo "- test_mail.sh - Test mail server functionality"
echo ""
echo "Next steps:"
echo "1. If you have existing mail data in Docker volumes, run: ./migrate_mail_data.sh"
echo "2. Start mail server: docker-compose up -d"
echo "3. Monitor status: ./monitor_mail.sh"
echo "4. Test functionality: ./test_mail.sh"
echo ""
echo "Backup schedule recommendation:"
echo "- Daily backups for active mail servers"
echo "- Weekly backups for development environments"
echo "- Store backups in a separate location"
echo ""
echo "Important notes:"
echo "- Mail data is now stored in ./mail/data"
echo "- Database is stored in ./mail/database"
echo "- All data will persist across container restarts and server reboots" 