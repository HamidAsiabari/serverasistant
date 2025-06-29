# Persistent Storage Guide

This guide explains how to set up persistent storage for GitLab and mail server data to ensure your data survives container restarts and server reboots.

## Overview

The persistent storage system ensures that:
- **GitLab repositories, users, and configurations** are preserved
- **Mail server emails, databases, and configurations** are preserved
- **All data is easily backed up and restored**
- **Data survives Docker container restarts and server reboots**

## Directory Structure

### GitLab Persistent Storage
```
example_services/gitlab/
├── gitlab/
│   ├── config/          # GitLab configuration files
│   ├── logs/            # GitLab log files
│   ├── data/            # GitLab application data (repositories, uploads, etc.)
│   ├── backups/         # GitLab backup files
│   ├── redis/           # Redis data for GitLab
│   └── postgres/        # PostgreSQL database data
├── docker-compose.yml
├── setup_persistent_storage.sh
├── backup_gitlab.sh
├── restore_gitlab.sh
├── migrate_gitlab_data.sh
└── monitor_gitlab.sh
```

### Mail Server Persistent Storage
```
example_services/mail-server/
├── mail/
│   ├── data/            # Email data (mailboxes, messages)
│   ├── queue/           # Postfix mail queue
│   └── database/        # MySQL database for Roundcube
├── roundcube/
│   └── data/            # Roundcube temporary files
├── spamassassin/
│   └── data/            # SpamAssassin data and rules
├── docker-compose.yml
├── setup_persistent_storage.sh
├── backup_mail.sh
├── restore_mail.sh
├── migrate_mail_data.sh
├── monitor_mail.sh
└── test_mail.sh
```

## Quick Setup

### 1. Set Up GitLab Persistent Storage

```bash
cd example_services/gitlab
chmod +x setup_persistent_storage.sh
./setup_persistent_storage.sh
```

### 2. Set Up Mail Server Persistent Storage

```bash
cd example_services/mail-server
chmod +x setup_persistent_storage.sh
./setup_persistent_storage.sh
```

### 3. Migrate Existing Data (if any)

If you have existing data in Docker volumes:

```bash
# For GitLab
cd example_services/gitlab
./migrate_gitlab_data.sh

# For Mail Server
cd example_services/mail-server
./migrate_mail_data.sh
```

### 4. Start Services

```bash
# Start GitLab
cd example_services/gitlab
docker-compose up -d

# Start Mail Server
cd example_services/mail-server
docker-compose up -d
```

## Data Backup and Restore

### Automated Backup System

The comprehensive backup system creates backups of all persistent data:

```bash
# Create backup (Linux/Mac)
./backup_system.sh

# Create backup (Windows)
backup_system.bat

# List available backups
./backup_system.sh list

# Restore from backup
./backup_system.sh restore ./backups/server_backup_20231201_120000.tar.gz
```

### Individual Service Backups

#### GitLab Backups

```bash
cd example_services/gitlab

# Create backup
./backup_gitlab.sh

# Restore from backup
./restore_gitlab.sh gitlab/backups/gitlab_backup_20231201_120000.tar.gz

# Monitor GitLab status
./monitor_gitlab.sh
```

#### Mail Server Backups

```bash
cd example_services/mail-server

# Create backup
./backup_mail.sh

# Restore from backup
./restore_mail.sh mail/backups/mail_backup_20231201_120000.tar.gz

# Monitor mail server status
./monitor_mail.sh

# Test mail server functionality
./test_mail.sh
```

## Data Migration from Docker Volumes

If you have existing data in Docker named volumes, use the migration scripts:

### GitLab Migration

```bash
cd example_services/gitlab
./migrate_gitlab_data.sh
```

This script will:
1. Stop GitLab containers
2. Copy data from Docker volumes to host directories
3. Ask if you want to remove old volumes
4. Prepare for restart with persistent storage

### Mail Server Migration

```bash
cd example_services/mail-server
./migrate_mail_data.sh
```

This script will:
1. Stop mail server containers
2. Copy data from Docker volumes to host directories
3. Ask if you want to remove old volumes
4. Prepare for restart with persistent storage

## Monitoring and Maintenance

### GitLab Monitoring

```bash
cd example_services/gitlab
./monitor_gitlab.sh
```

This shows:
- Container status
- Disk usage
- Recent logs
- Health check results

### Mail Server Monitoring

```bash
cd example_services/mail-server
./monitor_mail.sh
```

This shows:
- Container status
- Disk usage
- Mail queue status
- Recent logs from all services

### Mail Server Testing

```bash
cd example_services/mail-server
./test_mail.sh
```

This tests:
- SMTP connections (ports 25, 587)
- IMAP connections (ports 143, 993)
- Roundcube web interface
- Overall mail server functionality

## Backup Strategies

### Recommended Backup Schedule

| Service | Frequency | Retention | Notes |
|---------|-----------|-----------|-------|
| **GitLab** | Daily | 30 days | Critical for code repositories |
| **Mail Server** | Daily | 30 days | Critical for email data |
| **Full System** | Weekly | 90 days | Complete server backup |
| **Configurations** | On change | 365 days | When configs are modified |

### Backup Storage Locations

1. **Local Storage**: `./backups/` directory
2. **External Storage**: Copy to external drives or cloud storage
3. **Off-site Backup**: Store in different physical location

### Automated Backups

Set up cron jobs for automated backups:

```bash
# Edit crontab
crontab -e

# Add these lines for daily backups at 2 AM
0 2 * * * cd /path/to/serverimp && ./backup_system.sh > /dev/null 2>&1

# Add these lines for weekly full backups on Sundays at 3 AM
0 3 * * 0 cd /path/to/serverimp && ./backup_system.sh > /dev/null 2>&1
```

## Troubleshooting

### Common Issues

#### 1. Permission Errors

If you encounter permission errors:

```bash
# Fix permissions for GitLab
sudo chown -R 998:998 example_services/gitlab/gitlab/
sudo chmod -R 755 example_services/gitlab/gitlab/

# Fix permissions for mail server
sudo chown -R 1000:1000 example_services/mail-server/mail/
sudo chmod -R 755 example_services/mail-server/mail/
```

#### 2. Data Not Persisting

Check if volumes are properly mounted:

```bash
# Check GitLab volumes
docker-compose -f example_services/gitlab/docker-compose.yml config

# Check mail server volumes
docker-compose -f example_services/mail-server/docker-compose.yml config
```

#### 3. Backup Failures

If backups fail:

```bash
# Check disk space
df -h

# Check if tar is available
which tar

# Check backup directory permissions
ls -la backups/
```

#### 4. Restore Issues

If restore fails:

```bash
# Verify backup file integrity
tar -tzf backup_file.tar.gz

# Check available space
df -h

# Ensure services are stopped before restore
docker-compose down
```

### Data Recovery

#### Emergency Recovery

If you need to recover data quickly:

1. **Stop all services**:
   ```bash
   docker-compose down
   ```

2. **Restore from latest backup**:
   ```bash
   ./backup_system.sh restore ./backups/latest_backup.tar.gz
   ```

3. **Start services**:
   ```bash
   docker-compose up -d
   ```

#### Partial Recovery

If you only need to recover specific data:

```bash
# Extract specific service data
tar -xzf backup_file.tar.gz --wildcards '*/gitlab/*'
tar -xzf backup_file.tar.gz --wildcards '*/mail/*'
```

## Performance Considerations

### Disk Space Management

Monitor disk usage regularly:

```bash
# Check disk usage
du -sh example_services/*/gitlab/
du -sh example_services/*/mail/

# Clean up old logs
find example_services -name "*.log" -mtime +30 -delete
```

### Backup Optimization

- Use compression for backups
- Exclude temporary files
- Use incremental backups for large datasets
- Schedule backups during low-usage periods

### Storage Recommendations

- Use SSD storage for better performance
- Ensure adequate disk space (at least 2x current usage)
- Consider RAID for redundancy
- Monitor I/O performance

## Security Considerations

### Data Protection

- Encrypt backup files
- Secure backup storage locations
- Use strong passwords for databases
- Regular security updates

### Access Control

- Limit access to backup directories
- Use dedicated backup user accounts
- Implement backup verification
- Log all backup operations

## Next Steps

1. **Set up monitoring**: Configure alerts for disk space and backup failures
2. **Test recovery**: Regularly test backup restoration procedures
3. **Document procedures**: Create runbooks for common operations
4. **Automate maintenance**: Set up automated cleanup and monitoring
5. **Plan for scaling**: Consider storage requirements as data grows

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review service logs: `docker-compose logs <service_name>`
3. Verify disk space and permissions
4. Test with a fresh installation if needed
5. Consult Docker and service-specific documentation 