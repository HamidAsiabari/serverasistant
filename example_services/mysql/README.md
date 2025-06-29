# MySQL Database Service

This directory contains a MySQL database service with Docker Compose, including MySQL 8.0 and phpMyAdmin for database management.

## Overview

The MySQL service provides:

- **MySQL 8.0**: Reliable and feature-rich database server
- **phpMyAdmin**: Web-based database administration tool
- **Optimized Configuration**: Production-ready settings
- **Sample Data**: Pre-configured tables and data
- **Health Monitoring**: Built-in health checks

## Services

### MySQL 8.0
- **Port**: 3306
- **Container**: mysql
- **Database**: myapp (default)
- **Root Password**: root_password_secure
- **User**: myapp_user
- **User Password**: myapp_password

### phpMyAdmin
- **Port**: 8082
- **URL**: http://localhost:8082
- **Purpose**: Web-based database administration
- **Login**: root / root_password_secure

## Configuration

### Database Settings

The MySQL service is configured with the following settings:

- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci
- **Authentication**: mysql_native_password
- **Max Connections**: 200
- **Buffer Pool Size**: 1GB
- **Log File Size**: 256MB

### Environment Variables

```yaml
MYSQL_ROOT_PASSWORD: root_password_secure
MYSQL_DATABASE: myapp
MYSQL_USER: myapp_user
MYSQL_PASSWORD: myapp_password
MYSQL_ROOT_HOST: '%'
```

### Volumes

- **mysql_data**: Persistent database storage
- **./mysql/init**: Initialization scripts
- **./mysql/conf**: MySQL configuration files

## Usage

### Starting the Service

```bash
# Using Docker Service Manager
./start.sh start mysql-database

# Or directly with Docker Compose
cd example_services/mysql
docker-compose up -d
```

### Stopping the Service

```bash
# Using Docker Service Manager
./start.sh stop mysql-database

# Or directly with Docker Compose
cd example_services/mysql
docker-compose down
```

### Accessing MySQL

#### Command Line
```bash
# Connect to MySQL
docker exec -it mysql mysql -u root -p

# Connect as application user
docker exec -it mysql mysql -u myapp_user -p myapp
```

#### phpMyAdmin
- **URL**: http://localhost:8082
- **Server**: mysql
- **Username**: root
- **Password**: root_password_secure

### Database Operations

#### Create Database
```sql
CREATE DATABASE new_database;
```

#### Create User
```sql
CREATE USER 'new_user'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON database_name.* TO 'new_user'@'%';
FLUSH PRIVILEGES;
```

#### Backup Database
```bash
# Backup specific database
docker exec mysql mysqldump -u root -p myapp > myapp-backup.sql

# Backup all databases
docker exec mysql mysqldump -u root -p --all-databases > all-databases-backup.sql
```

#### Restore Database
```bash
# Restore database
docker exec -i mysql mysql -u root -p myapp < myapp-backup.sql
```

## Sample Data

The MySQL service comes with pre-configured sample data:

### Tables
- **users**: User accounts and authentication
- **products**: Product catalog
- **orders**: Order management
- **order_summary**: View for order analysis

### Sample Records
- **Users**: admin, john_doe, jane_smith
- **Products**: Laptop, Mouse, Keyboard, Monitor, Headphones
- **Orders**: Sample order data

### Views and Procedures
- **order_summary**: View for order analysis
- **GetUserOrders**: Stored procedure for user orders

## Performance Optimization

### Configuration Settings

The MySQL configuration is optimized for production use:

```ini
# Buffer Settings
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M

# Connection Settings
max_connections = 200
max_connect_errors = 100000

# Performance Settings
tmp_table_size = 64M
max_heap_table_size = 64M
table_open_cache = 2000
thread_cache_size = 16
```

### Monitoring

Monitor MySQL performance:

```bash
# Check MySQL status
docker exec mysql mysqladmin -u root -p status

# Check process list
docker exec mysql mysql -u root -p -e "SHOW PROCESSLIST;"

# Check slow queries
docker exec mysql mysql -u root -p -e "SHOW VARIABLES LIKE 'slow_query_log';"
```

## Security

### Access Control

- **Root Access**: Restricted to local connections
- **User Permissions**: Limited to specific databases
- **Network Access**: Controlled through Docker networks

### SSL/TLS

For production use, configure SSL:

```bash
# Generate SSL certificates
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout mysql-key.pem -out mysql-cert.pem

# Add to MySQL configuration
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
```

### Password Security

- **Strong Passwords**: Use complex passwords
- **Password Rotation**: Regular password updates
- **User Management**: Remove unused accounts

## Backup and Recovery

### Automated Backups

Create a backup script:

```bash
#!/bin/bash
# backup-mysql.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mysql"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup all databases
docker exec mysql mysqldump -u root -p --all-databases > $BACKUP_DIR/all-databases-$DATE.sql

# Backup specific database
docker exec mysql mysqldump -u root -p myapp > $BACKUP_DIR/myapp-$DATE.sql

# Compress backups
gzip $BACKUP_DIR/*.sql

# Remove old backups (keep 7 days)
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
```

### Recovery Procedures

#### Point-in-Time Recovery
```bash
# Restore from backup
docker exec -i mysql mysql -u root -p < backup.sql

# Apply binary logs for point-in-time recovery
mysqlbinlog --start-datetime="2023-01-01 10:00:00" \
  --stop-datetime="2023-01-01 11:00:00" \
  mysql-bin.000001 | mysql -u root -p
```

## Troubleshooting

### Common Issues

1. **Connection Refused**
   - Check if MySQL container is running
   - Verify port mapping
   - Check firewall settings

2. **Access Denied**
   - Verify username and password
   - Check user permissions
   - Ensure correct host access

3. **Performance Issues**
   - Monitor resource usage
   - Check slow query log
   - Optimize queries and indexes

4. **Disk Space Issues**
   - Check data directory size
   - Monitor log file growth
   - Clean up old backups

### Log Analysis

```bash
# View MySQL error log
docker logs mysql

# Check for specific errors
docker logs mysql | grep -i error

# Monitor real-time logs
docker logs -f mysql
```

### Performance Monitoring

```bash
# Check MySQL variables
docker exec mysql mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"

# Check MySQL status
docker exec mysql mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"

# Check table sizes
docker exec mysql mysql -u root -p -e "
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
GROUP BY table_schema;"
```

## Integration

### With Web Applications

The MySQL service is configured to work with web applications:

```python
# Python connection example
import mysql.connector

config = {
    'host': 'localhost',
    'port': 3306,
    'user': 'myapp_user',
    'password': 'myapp_password',
    'database': 'myapp'
}

connection = mysql.connector.connect(**config)
```

### With Other Services

- **Web App**: Connected via environment variables
- **Mail Server**: Roundcube database
- **GitLab**: Separate PostgreSQL instance
- **Monitoring**: Health check integration

## Maintenance

### Regular Tasks

1. **Backup Verification**: Test backup restoration
2. **Log Rotation**: Monitor log file sizes
3. **Performance Tuning**: Monitor and optimize queries
4. **Security Updates**: Keep MySQL updated

### Updates

To update MySQL:

```bash
# Stop services
docker-compose down

# Pull new image
docker-compose pull

# Start services
docker-compose up -d

# Monitor upgrade
docker logs -f mysql
```

## Support

For issues and questions:
1. Check MySQL error logs
2. Verify configuration settings
3. Test database connectivity
4. Review performance metrics 