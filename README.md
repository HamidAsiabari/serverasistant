# Docker Service Manager

A Python application for managing and running Docker services based on JSON configuration. This tool allows you to easily deploy, monitor, and manage Docker containers and Docker Compose services across different servers.

## Features

- **JSON Configuration**: Define services in a simple JSON configuration file
- **Docker Support**: Run individual Docker containers from Dockerfiles
- **Docker Compose Support**: Manage multi-service applications with Docker Compose
- **Nginx Reverse Proxy**: Professional domain-based routing with SSL/TLS support
- **Health Monitoring**: Built-in health checks and monitoring
- **Cross-Server Compatibility**: Use the same configuration across different servers
- **Cross-Platform Support**: Works on Linux Ubuntu and Windows servers
- **Logging**: Comprehensive logging with configurable log levels
- **CLI Interface**: Easy-to-use command-line interface
- **Status Monitoring**: Real-time service status and resource usage
- **Notifications**: Email and webhook notifications for service issues
- **Automated Reports**: Daily status reports and log cleanup

## Services Overview

### Core Services

| Service | Type | Description | Port | Domain |
|---------|------|-------------|------|--------|
| **Web Application** | Flask | Main web application with health monitoring | 8080 | `app.soject.com` |
| **MySQL Database** | Database | MySQL with phpMyAdmin interface | 3306, 8080 | `admin.soject.com` |
| **PostgreSQL + Redis** | Database | PostgreSQL database with Redis cache | 5432, 6379 | - |
| **Portainer** | Management | Docker container management UI | 9000 | `docker.soject.com` |
| **GitLab** | Development | Git repository and CI/CD platform | 8081 | `gitlab.soject.com` |
| **Mail Server** | Communication | Complete email stack with webmail | 25, 587, 993 | `mail.soject.com` |
| **Nginx** | Reverse Proxy | Domain-based routing with SSL/TLS | 80, 443 | All domains |

### Nginx Reverse Proxy

The Nginx reverse proxy provides professional domain-based routing for all services:

#### Domain Configuration
- **Web App**: `https://app.soject.com` - Main Flask application
- **Database Admin**: `https://admin.soject.com` - phpMyAdmin interface
- **Docker Management**: `https://docker.soject.com` - Portainer UI
- **Git Repository**: `https://gitlab.soject.com` - GitLab platform
- **Webmail**: `https://mail.soject.com` - Roundcube email interface

#### Features
- **SSL/TLS Support**: HTTPS with modern cipher suites
- **Security Headers**: HSTS, XSS protection, content type options
- **Rate Limiting**: Protection against brute force attacks
- **WebSocket Support**: For real-time applications
- **Large File Uploads**: Optimized for GitLab and file uploads
- **Health Checks**: Dedicated health check endpoints
- **Logging**: Comprehensive access and error logging

#### Quick Setup

1. **Generate SSL Certificates:**
```bash
cd example_services/nginx
chmod +x setup_nginx.sh
./setup_nginx.sh
```

2. **Add Domains to Hosts File:**
```bash
# Linux/Mac
sudo ./add_to_hosts.sh

# Windows (Run as Administrator)
add_to_hosts.bat
```

3. **Start Nginx:**
```bash
./start_nginx.sh
```

4. **Access Services:**
- Web App: https://app.soject.com
- Database Admin: https://admin.soject.com
- Docker Management: https://docker.soject.com
- GitLab: https://gitlab.soject.com
- Webmail: https://mail.soject.com

#### Production Deployment

For production use, replace self-signed certificates with trusted certificates:

```bash
# Using Let's Encrypt
certbot certonly --webroot -w /var/www/html -d app.soject.com
certbot certonly --webroot -w /var/www/html -d admin.soject.com
# ... repeat for all domains
```

Update certificate paths in domain configuration files and configure DNS records to point to your server IP.

## Installation

### Prerequisites

- Python 3.7 or higher
- Docker and Docker Compose installed
- Docker daemon running

### Quick Installation

#### Linux Ubuntu

1. **Automatic Installation (Recommended):**
```bash
# Make the installation script executable
chmod +x install_requirements.sh

# Run the installation script
./install_requirements.sh
```

2. **Manual Installation:**
```bash
# Update package list
sudo apt update

# Install system dependencies
sudo apt install -y python3 python3-pip python3-venv curl wget git

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Python dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Windows Server

1. **Automatic Installation (Recommended):**
```powershell
# Run PowerShell as Administrator
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Run the installation script
.\install_requirements.ps1
```

2. **Manual Installation:**
```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Python and Docker Desktop
choco install python docker-desktop -y

# Create virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Post-Installation Steps

#### Linux Ubuntu
1. **Log out and log back in** (for docker group changes to take effect)
2. **Test the installation:**
```bash
./test_installation.py
```
3. **Start using the manager:**
```bash
./start.sh status
./start.sh start-all
./start_monitor.sh
```

#### Windows Server
1. **Restart your computer** (if Docker Desktop was installed)
2. **Start Docker Desktop manually**
3. **Test the installation:**
```cmd
.\test_install.bat
```
4. **Start using the manager:**
```cmd
.\start.bat status
.\start.bat start-all
.\start_monitor.bat
```

## Configuration

The application uses a JSON configuration file (`config.json`) to define services and settings:

### Basic Configuration Structure

```json
{
  "server_name": "production-server-01",
  "environment": "production",
  "log_level": "INFO",
  "platform": "auto",
  "services": [
    {
      "name": "web-app",
      "type": "dockerfile",
      "enabled": true,
      "path": "./services/web-app",
      "dockerfile": "Dockerfile",
      "ports": ["8080:8080"],
      "environment": {
        "NODE_ENV": "production"
      },
      "volumes": ["./logs:/app/logs"],
      "restart_policy": "unless-stopped",
      "health_check": {
        "url": "http://localhost:8080/health",
        "interval": 30,
        "timeout": 10,
        "retries": 3
      }
    }
  ],
  "global_settings": {
    "docker_socket": "auto",
    "docker_host": "auto",
    "log_retention_days": 30,
    "backup_enabled": true,
    "platform_specific": {
      "linux": {
        "docker_socket": "/var/run/docker.sock",
        "docker_host": "unix:///var/run/docker.sock",
        "log_path": "./logs",
        "compose_command": "docker-compose",
        "file_permissions": "755"
      },
      "windows": {
        "docker_socket": "npipe:////./pipe/docker_engine",
        "docker_host": "npipe:////./pipe/docker_engine",
        "log_path": ".\\logs",
        "compose_command": "docker-compose.exe",
        "file_permissions": "644"
      }
    },
    "notification": {
      "email": "admin@example.com",
      "webhook": "https://hooks.slack.com/services/xxx/yyy/zzz"
    }
  }
}
```

### Platform-Specific Configuration

The application automatically detects your platform (Linux or Windows) and uses the appropriate settings:

#### Linux Ubuntu Settings
- **Docker Socket**: `/var/run/docker.sock`
- **Docker Host**: `unix:///var/run/docker.sock`
- **Log Path**: `./logs`
- **Compose Command**: `docker-compose`
- **File Permissions**: `755`

#### Windows Server Settings
- **Docker Socket**: `npipe:////./pipe/docker_engine`
- **Docker Host**: `npipe:////./pipe/docker_engine`
- **Log Path**: `.\logs`
- **Compose Command**: `docker-compose.exe`
- **File Permissions**: `644`

### Service Configuration Options

#### Dockerfile Services
- `name`: Service name (required)
- `type`: Must be "dockerfile" (required)
- `enabled`: Whether the service should be managed (default: true)
- `path`: Path to the directory containing the Dockerfile (required)
- `dockerfile`: Name of the Dockerfile (default: "Dockerfile")
- `ports`: List of port mappings (e.g., ["8080:8080"])
- `environment`: Environment variables for the container
- `volumes`: List of volume mappings
- `restart_policy`: Docker restart policy (default: "unless-stopped")
- `health_check`: Health check configuration

#### Docker Compose Services
- `name`: Service name (required)
- `type`: Must be "docker-compose" (required)
- `enabled`: Whether the service should be managed (default: true)
- `path`: Path to the directory containing docker-compose.yml (required)
- `compose_file`: Name of the compose file (default: "docker-compose.yml")
- `services`: List of services to manage (optional, manages all if not specified)
- `restart_policy`: Docker restart policy
- `health_check`: Health check configuration

#### Health Check Configuration
- `url`: HTTP endpoint for health checks
- `command`: Command to run for health checks
- `interval`: Check interval in seconds
- `timeout`: Timeout for health checks
- `retries`: Number of retries before marking unhealthy

### Nginx Reverse Proxy Configuration

The Nginx reverse proxy provides professional domain-based routing for all services:

#### Domain Configuration
```json
{
  "name": "nginx",
  "type": "docker-compose",
  "enabled": true,
  "path": "./example_services/nginx",
  "compose_file": "docker-compose.yml",
  "services": ["nginx"],
  "restart_policy": "unless-stopped",
  "domains": {
    "app.soject.com": "web-app",
    "admin.soject.com": "phpmyadmin",
    "docker.soject.com": "portainer",
    "gitlab.soject.com": "gitlab",
    "mail.soject.com": "roundcube"
  },
  "ports": ["80:80", "443:443"],
  "health_check": {
    "url": "http://localhost/health",
    "interval": 30,
    "timeout": 10,
    "retries": 3
  },
  "dependencies": ["web-app", "mysql-database", "postgres-redis", "portainer", "gitlab", "mail-server"]
}
```

#### Domain Mapping
| Domain | Service | Description |
|--------|---------|-------------|
| `app.soject.com` | Web Application | Main Flask web application |
| `admin.soject.com` | phpMyAdmin | MySQL database management |
| `docker.soject.com` | Portainer | Docker container management |
| `gitlab.soject.com` | GitLab | Git repository and CI/CD |
| `mail.soject.com` | Roundcube | Webmail interface |

#### Features
- **SSL/TLS Support**: HTTPS with modern cipher suites (TLSv1.2, TLSv1.3)
- **Security Headers**: HSTS, XSS protection, content type options
- **Rate Limiting**: Protection against brute force attacks
- **WebSocket Support**: For real-time applications like Portainer
- **Large File Uploads**: Optimized for GitLab (500MB limit)
- **Health Checks**: Dedicated health check endpoints
- **Logging**: Comprehensive access and error logging

#### Quick Setup

1. **Generate SSL Certificates:**
```bash
cd example_services/nginx
chmod +x setup_nginx.sh
./setup_nginx.sh
```

2. **Add Domains to Hosts File:**
```bash
# Linux/Mac
sudo ./add_to_hosts.sh

# Windows (Run as Administrator)
add_to_hosts.bat
```

3. **Start Nginx:**
```bash
./start_nginx.sh
```

4. **Access Services:**
- Web App: https://app.soject.com
- Database Admin: https://admin.soject.com
- Docker Management: https://docker.soject.com
- GitLab: https://gitlab.soject.com
- Webmail: https://mail.soject.com

#### Production Deployment

For production use, configure these domains in Cloudflare:

```
A    app.soject.com    YOUR_SERVER_IP
A    admin.soject.com  YOUR_SERVER_IP
A    docker.soject.com YOUR_SERVER_IP
A    gitlab.soject.com YOUR_SERVER_IP
A    mail.soject.com   YOUR_SERVER_IP
```

Then replace self-signed certificates with trusted certificates:

```bash
# Using Let's Encrypt
certbot certonly --webroot -w /var/www/html -d app.soject.com
certbot certonly --webroot -w /var/www/html -d admin.soject.com
# ... repeat for all domains
```

Update certificate paths in domain configuration files.

## Usage

### Basic Commands

Show status of all services:
```bash
# Linux
./start.sh status

# Windows
.\start.bat status
```

Start a specific service:
```bash
# Linux
./start.sh start web-app

# Windows
.\start.bat start web-app
```

Stop a specific service:
```bash
# Linux
./start.sh stop database

# Windows
.\start.bat stop database
```

Restart a specific service:
```bash
# Linux
./start.sh restart monitoring

# Windows
.\start.bat restart monitoring
```

Start all enabled services:
```bash
# Linux
./start.sh start-all

# Windows
.\start.bat start-all
```

Stop all services:
```bash
# Linux
./start.sh stop-all

# Windows
.\start.bat stop-all
```

### Monitoring

Start continuous monitoring:
```bash
# Linux
./start_monitor.sh

# Windows
.\start_monitor.bat
```

Show health summary:
```bash
# Linux
./start_monitor.sh --summary

# Windows
.\start_monitor.bat --summary
```

Monitor with custom interval:
```bash
# Linux
./start_monitor.sh --interval 30

# Windows
.\start_monitor.bat --interval 30
```

### Using Different Configuration Files

```bash
# Linux
./start.sh status --config production.json
./start_monitor.sh --config staging.json

# Windows
.\start.bat status --config production.json
.\start_monitor.bat --config staging.json
```

## Example Service Structures

### Dockerfile Service
```
services/
└── web-app/
    ├── Dockerfile
    ├── app.py
    └── requirements.txt
```

### Docker Compose Service
```
services/
└── database/
    ├── docker-compose.yml
    ├── postgres/
    │   └── init.sql
    └── redis/
        └── redis.conf
```

## Logging

Logs are stored in the `logs/` directory with the following structure:
- `docker_manager_YYYYMMDD.log`: Main application logs
- `reports/daily_report_YYYYMMDD.json`: Daily status reports

Log levels can be configured in the JSON config:
- `DEBUG`: Detailed debug information
- `INFO`: General information (default)
- `WARNING`: Warning messages
- `ERROR`: Error messages

## Monitoring and Notifications

The monitoring system provides:

1. **Health Checks**: Automatic health monitoring of services
2. **Resource Monitoring**: CPU and memory usage tracking
3. **Notifications**: Email and webhook alerts for issues
4. **Daily Reports**: Automated daily status reports
5. **Log Cleanup**: Automatic cleanup of old logs and reports

### Notification Configuration

Configure notifications in the `global_settings` section:

```json
{
  "global_settings": {
    "notification": {
      "email": "admin@example.com",
      "webhook": "https://hooks.slack.com/services/xxx/yyy/zzz"
    }
  }
}
```

## Cross-Server Deployment

To use this tool across different servers:

1. **Copy the application** to each server
2. **Customize the configuration** for each server's environment
3. **Use the same service definitions** but adjust paths and settings as needed
4. **Deploy using the same commands** on each server

### Example Multi-Server Setup

**Production Server (Linux Ubuntu):**
```json
{
  "server_name": "prod-server-01",
  "environment": "production",
  "platform": "linux",
  "services": [
    {
      "name": "web-app",
      "path": "/opt/services/web-app",
      "ports": ["80:8080"]
    }
  ]
}
```

**Staging Server (Windows):**
```json
{
  "server_name": "staging-server-01",
  "environment": "staging",
  "platform": "windows",
  "services": [
    {
      "name": "web-app",
      "path": "C:\\services\\web-app",
      "ports": ["8080:8080"]
    }
  ]
}
```

## System Integration

### Linux Ubuntu (systemd)

The installation script creates a systemd service for automatic startup:

```bash
# Enable the service
sudo systemctl enable docker-manager.service

# Start the service
sudo systemctl start docker-manager.service

# Check status
sudo systemctl status docker-manager.service

# View logs
sudo journalctl -u docker-manager.service -f
```

### Windows Server (Task Scheduler)

The installation script creates a Windows Task Scheduler entry for automatic startup:

```powershell
# Check task status
Get-ScheduledTask -TaskName "DockerServiceManager"

# Enable/disable task
Enable-ScheduledTask -TaskName "DockerServiceManager"
Disable-ScheduledTask -TaskName "DockerServiceManager"
```

## Troubleshooting

### Common Issues

1. **Docker daemon not running**
   - **Linux**: `sudo systemctl start docker`
   - **Windows**: Start Docker Desktop manually

2. **Permission denied errors**
   - **Linux**: Ensure user is in docker group and logged out/in
   - **Windows**: Run as Administrator

3. **Service not starting**
   - Check Dockerfile/Compose file syntax
   - Verify service paths exist
   - Check logs for specific errors

4. **Health checks failing**
   - Verify health check endpoints are accessible
   - Check service configuration
   - Review health check timeouts

5. **Platform detection issues**
   - Check `platform` setting in config.json
   - Verify platform-specific settings are correct

### Debug Mode

Enable debug logging by setting `"log_level": "DEBUG"` in your configuration.

### Platform-Specific Issues

#### Linux Ubuntu
- **Docker socket permissions**: `sudo chmod 666 /var/run/docker.sock`
- **User not in docker group**: `sudo usermod -aG docker $USER`
- **Service paths**: Use absolute paths for better reliability

#### Windows Server
- **Docker Desktop not running**: Start Docker Desktop manually
- **Path issues**: Use Windows-style paths in configuration
- **PowerShell execution policy**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs in the `logs/` directory
3. Create an issue in the repository 