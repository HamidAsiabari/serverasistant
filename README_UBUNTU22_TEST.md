# Ubuntu 22.04 Test Guide

This guide provides step-by-step instructions for testing the Docker Service Manager on Ubuntu 22.04 server.

## Prerequisites

### System Requirements
- **OS**: Ubuntu 22.04 LTS
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Disk Space**: Minimum 10GB free space
- **Network**: Internet connectivity
- **User**: Non-root user with sudo privileges

### Network Requirements
- **Ports**: 22 (SSH), 8080 (Web App), 8082 (phpMyAdmin), 3306 (MySQL), 5432 (PostgreSQL), 6379 (Redis)
- **Firewall**: Ensure required ports are open

## Quick Start

### 1. Clone or Download the Project

```bash
# If using git
git clone <repository-url>
cd serverimp

# Or download and extract the project files
```

### 2. Run the Test Script

```bash
# Make the test script executable
chmod +x test_ubuntu22.sh

# Run the comprehensive test
./test_ubuntu22.sh
```

### 3. Quick Verification

```bash
# Make the quick test script executable
chmod +x quick_test_ubuntu22.sh

# Run quick verification
./quick_test_ubuntu22.sh
```

## Test Configuration

The test uses `test_config_ubuntu22.json` which includes:

### Enabled Services (for testing)
- ✅ **Web Application** (port 8080)
- ✅ **MySQL Database** (port 3306) + phpMyAdmin (port 8082)
- ✅ **PostgreSQL + Redis** (ports 5432, 6379)

### Disabled Services (for initial testing)
- ❌ **Mail Server** (complex setup, test separately)
- ❌ **GitLab** (resource intensive, test separately)
- ❌ **Monitoring** (optional, test separately)

## Test Process

### Phase 1: System Check
- ✅ Ubuntu 22.04 verification
- ✅ Memory and disk space check
- ✅ Internet connectivity test
- ✅ User permissions verification

### Phase 2: Installation
- ✅ System dependencies installation
- ✅ Docker installation and configuration
- ✅ Docker Compose installation
- ✅ Python environment setup
- ✅ Directory structure creation

### Phase 3: Testing
- ✅ Docker daemon test
- ✅ Configuration validation
- ✅ Service startup test
- ✅ Health check verification
- ✅ Connectivity testing

## Expected Results

### Successful Test Output
```
==========================================
Ubuntu 22.04 Docker Service Manager Test
==========================================
[SUCCESS] Ubuntu 22.04 detected
[SUCCESS] Memory: 8GB
[SUCCESS] Disk space: 50GB
[SUCCESS] Internet connectivity: OK
[SUCCESS] System dependencies installed
[SUCCESS] Docker installed successfully
[SUCCESS] Docker Compose installed successfully
[SUCCESS] Python environment setup complete
[SUCCESS] Docker daemon is running
[SUCCESS] Configuration file is valid JSON
[SUCCESS] Docker Manager test passed
[SUCCESS] MySQL database started
[SUCCESS] PostgreSQL/Redis started
[SUCCESS] Web application started
[SUCCESS] phpMyAdmin is accessible
[SUCCESS] Web application health check passed
```

### Service Status
```
Running Containers:
NAMES           STATUS              PORTS
mysql           Up 2 minutes        0.0.0.0:3306->3306/tcp
phpmyadmin      Up 2 minutes        0.0.0.0:8082->80/tcp
postgres        Up 2 minutes        0.0.0.0:5432->5432/tcp
redis           Up 2 minutes        0.0.0.0:6379->6379/tcp
web-app         Up 1 minute         0.0.0.0:8080->8080/tcp
```

## Access Points

### Web Interfaces
- **Web Application**: http://localhost:8080
- **phpMyAdmin**: http://localhost:8082

### Database Connections
- **MySQL**: localhost:3306
  - Root: root / root_password_secure
  - App: myapp_user / myapp_password
- **PostgreSQL**: localhost:5432
  - User: postgres / password
- **Redis**: localhost:6379

## Troubleshooting

### Common Issues

#### 1. Docker Permission Issues
```bash
# Error: Got permission denied while trying to connect to the Docker daemon
# Solution: Log out and log back in, or run:
newgrp docker
```

#### 2. Port Already in Use
```bash
# Check what's using the port
sudo netstat -tulpn | grep :8080

# Stop conflicting service
sudo systemctl stop conflicting-service
```

#### 3. Insufficient Memory
```bash
# Check available memory
free -h

# If less than 4GB, consider:
# - Close other applications
# - Add swap space
# - Use a machine with more RAM
```

#### 4. Docker Service Not Running
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check Docker status
sudo systemctl status docker
```

#### 5. Python Virtual Environment Issues
```bash
# Recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Debug Commands

#### Check Service Logs
```bash
# Docker Service Manager logs
tail -f logs/docker_manager_$(date +%Y%m%d).log

# Container logs
docker logs mysql
docker logs postgres
docker logs web-app
```

#### Check Service Status
```bash
# All services
python3 main.py status --config test_config_ubuntu22.json

# Specific service
python3 main.py status web-app --config test_config_ubuntu22.json
```

#### Test Connectivity
```bash
# Test web app
curl http://localhost:8080/health

# Test phpMyAdmin
curl http://localhost:8082

# Test databases
docker exec mysql mysqladmin ping -h localhost -u root -proot_password_secure
docker exec postgres pg_isready -U postgres
docker exec redis redis-cli ping
```

## Advanced Testing

### Enable Additional Services

#### Mail Server Test
```bash
# Edit test_config_ubuntu22.json
# Change "enabled": false to "enabled": true for mail-server

# Start mail server
python3 main.py start mail-server --config test_config_ubuntu22.json

# Test mail server
telnet localhost 25
curl http://localhost:8083  # Roundcube webmail
```

#### GitLab Test
```bash
# Edit test_config_ubuntu22.json
# Change "enabled": false to "enabled": true for gitlab

# Start GitLab (requires more resources)
python3 main.py start gitlab --config test_config_ubuntu22.json

# Wait for GitLab to initialize (5-10 minutes)
# Access: http://localhost:8081
```

### Performance Testing

#### Load Testing
```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test web app performance
ab -n 1000 -c 10 http://localhost:8080/

# Test database performance
docker exec mysql mysql -u root -proot_password_secure -e "SELECT COUNT(*) FROM myapp.users;"
```

#### Resource Monitoring
```bash
# Monitor system resources
htop

# Monitor Docker resources
docker stats

# Monitor disk usage
df -h
```

## Cleanup

### Stop All Services
```bash
python3 main.py stop-all --config test_config_ubuntu22.json
```

### Remove Test Data
```bash
# Remove containers
docker rm -f $(docker ps -aq)

# Remove volumes
docker volume rm $(docker volume ls -q)

# Remove images
docker rmi $(docker images -q)
```

### Reset Configuration
```bash
# Restore original config
cp config.json test_config_ubuntu22.json
```

## Next Steps

After successful testing:

1. **Production Setup**
   - Update configuration for production environment
   - Configure SSL certificates
   - Set up proper backup strategies
   - Configure monitoring and alerting

2. **Service Integration**
   - Enable mail server for email notifications
   - Enable GitLab for source code management
   - Configure monitoring stack

3. **Security Hardening**
   - Change default passwords
   - Configure firewall rules
   - Set up SSL/TLS certificates
   - Implement access controls

4. **Monitoring Setup**
   - Configure log aggregation
   - Set up health monitoring
   - Implement alerting
   - Create dashboards

## Support

For issues during testing:

1. **Check the logs**: `tail -f logs/docker_manager_*.log`
2. **Verify system requirements**: Ensure sufficient resources
3. **Check network connectivity**: Verify ports are accessible
4. **Review configuration**: Validate JSON syntax and settings

## Test Results Log

The test script creates a detailed log file: `test_ubuntu22_YYYYMMDD_HHMMSS.log`

This log contains:
- All test steps and results
- Error messages and warnings
- System information
- Configuration details
- Performance metrics

Use this log for troubleshooting and documentation. 