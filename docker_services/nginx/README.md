# Nginx Reverse Proxy with SSL Support

A comprehensive nginx reverse proxy setup for managing multiple Docker services with SSL/TLS encryption, automatic HTTP to HTTPS redirects, and domain-based routing.

## 📑 Table of Contents

- [Features](#-features)
- [Supported Services](#-supported-services)
- [Quick Start](#-quick-start)
- [Management Scripts](#-management-scripts)
- [Domain Configuration](#-domain-configuration)
- [Configuration Files](#-configuration-files)
- [SSL/TLS Configuration](#-ssltls-configuration)
- [Management Commands](#️-management-commands)
- [Troubleshooting](#-troubleshooting)
- [Monitoring and Health Checks](#-monitoring-and-health-checks)
- [Advanced Configuration](#-advanced-configuration)
- [Updates and Maintenance](#-updates-and-maintenance)
- [Security Considerations](#-security-considerations)
- [Additional Resources](#-additional-resources)

## 🌟 Features

- **🔒 SSL/TLS Encryption** - Self-signed certificates for all domains
- **🔄 Automatic Redirects** - HTTP to HTTPS redirects for all domains
- **🌐 Domain Routing** - Separate domains for each service
- **🛡️ Security Headers** - HSTS, XSS protection, and other security headers
- **⚡ Performance** - Gzip compression, connection pooling, and caching
- **📊 Rate Limiting** - API endpoint protection
- **🔍 Health Checks** - Built-in health check endpoints
- **📱 WebSocket Support** - For real-time applications like Portainer
- **📝 Comprehensive Logging** - Access and error logs with custom formats
- **🔧 Easy Management** - Simple scripts for setup and maintenance
- **🧹 Organized Structure** - Clean, well-organized file structure

## 📋 Supported Services

| Domain | Service | Port | Description | Status |
|--------|---------|------|-------------|--------|
| `app.soject.com` | Web Application | 8080 | Main web application | ✅ Active |
| `admin.soject.com` | phpMyAdmin | 8082 | Database administration | ✅ Active |
| `docker.soject.com` | Portainer | 9000 | Docker container management | ✅ Active |
| `gitlab.soject.com` | GitLab | 8081 | Git repository management | ✅ Active |
| `mail.soject.com` | Roundcube | 8083 | Webmail interface | ✅ Active |
| `your-server-ip` | Default | 8080 | Default web application | ✅ Active |

## 🚀 Quick Start

### Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- Docker and Docker Compose installed
- Root or sudo access
- OpenSSL for certificate generation
- At least 1GB RAM and 10GB disk space

### 1. Clone and Navigate

```bash
cd docker_services/nginx
```

### 2. Run Setup Script

```bash
sudo ./setup_nginx.sh
```

This comprehensive script will:
- Install required packages
- Generate SSL certificates
- Set proper permissions
- Verify configuration files
- Start nginx services
- Test connectivity

### 3. Verify Installation

```bash
./manage_nginx.sh health
```

## 🛠️ Management Scripts

The nginx setup includes several management scripts for easy operation:

### Main Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup_nginx.sh` | Initial setup and installation | `sudo ./setup_nginx.sh` |
| `manage_nginx.sh` | Daily management operations | `./manage_nginx.sh [command]` |
| `generate_ssl.sh` | SSL certificate generation | `./generate_ssl.sh` |
| `cleanup_old_configs.sh` | Clean up old configurations | `./cleanup_old_configs.sh` |
| `organize_nginx.sh` | Organize folder structure | `./organize_nginx.sh` |

### Management Commands

```bash
# Start nginx
./manage_nginx.sh start

# Stop nginx
./manage_nginx.sh stop

# Restart nginx
./manage_nginx.sh restart

# Check status
./manage_nginx.sh status

# View logs
./manage_nginx.sh logs

# Test configuration
./manage_nginx.sh test

# Regenerate SSL certificates
./manage_nginx.sh ssl

# Health check
./manage_nginx.sh health

# Backup configuration
./manage_nginx.sh backup

# Clean up old files
./manage_nginx.sh cleanup

# Show help
./manage_nginx.sh help
```

### Windows Support

For Windows users, there's also a batch file:
- `setup_nginx.bat` - Windows setup script

## 🌐 Domain Configuration

### Local Development

Add these entries to your hosts file:

**Linux/Mac:**
```bash
sudo nano /etc/hosts
```

**Windows:**
```
C:\Windows\System32\drivers\etc\hosts
```

Add this line:
```
YOUR_SERVER_IP app.soject.com admin.soject.com docker.soject.com gitlab.soject.com mail.soject.com
```

### Production DNS

For production, configure your DNS provider to point these domains to your server:
- `app.soject.com` → `YOUR_SERVER_IP`
- `admin.soject.com` → `YOUR_SERVER_IP`
- `docker.soject.com` → `YOUR_SERVER_IP`
- `gitlab.soject.com` → `YOUR_SERVER_IP`
- `mail.soject.com` → `YOUR_SERVER_IP`

### DNS Propagation

After updating DNS records, allow 24-48 hours for full propagation:
```bash
# Check DNS propagation
dig app.soject.com
nslookup app.soject.com
```

## 🔧 Configuration Files

### Main Configuration
- `config/nginx.conf` - Main nginx configuration with upstream definitions
- `docker-compose.yml` - Docker Compose configuration
- `generate_ssl.sh` - SSL certificate generation script
- `setup_nginx.sh` - Complete setup script

### Domain Configurations
- `config/conf.d/default.conf` - Default server (handles server IP requests)
- `config/conf.d/app.soject.com.conf` - Web application
- `config/conf.d/admin.soject.com.conf` - phpMyAdmin
- `config/conf.d/docker.soject.com.conf` - Portainer
- `config/conf.d/gitlab.soject.com.conf` - GitLab
- `config/conf.d/mail.soject.com.conf` - Roundcube mail

### SSL Certificates
- `ssl/` - Directory containing all SSL certificates and keys

### Management Scripts
- `manage_nginx.sh` - Main management script
- `cleanup_old_configs.sh` - Cleanup utility
- `organize_nginx.sh` - Organization utility

## 🔒 SSL/TLS Configuration

### Self-Signed Certificates (Development)

The setup includes self-signed certificates for development and testing. These provide encryption but will show browser warnings.

**Browser Warnings**: Accept the security risk in your browser to proceed with self-signed certificates.

### Production Certificates

For production, replace self-signed certificates with real certificates:

1. **Let's Encrypt (Recommended)**
   ```bash
   # Install certbot
   sudo apt update
   sudo apt install certbot
   
   # Stop nginx temporarily
   ./manage_nginx.sh stop
   
   # Generate certificates
   sudo certbot certonly --standalone -d app.soject.com
   sudo certbot certonly --standalone -d admin.soject.com
   sudo certbot certonly --standalone -d docker.soject.com
   sudo certbot certonly --standalone -d gitlab.soject.com
   sudo certbot certonly --standalone -d mail.soject.com
   
   # Copy certificates
   sudo cp /etc/letsencrypt/live/app.soject.com/fullchain.pem ssl/app.soject.com.crt
   sudo cp /etc/letsencrypt/live/app.soject.com/privkey.pem ssl/app.soject.com.key
   # Repeat for other domains...
   
   # Set permissions
   chmod 600 ssl/*.key
   chmod 644 ssl/*.crt
   
   # Restart nginx
   ./manage_nginx.sh start
   ```

2. **Commercial Certificates**
   - Purchase certificates from a trusted CA
   - Place `.crt` and `.key` files in the `ssl/` directory
   - Update file names to match the configuration

### Certificate Renewal

For Let's Encrypt certificates, set up automatic renewal:
```bash
# Test renewal
sudo certbot renew --dry-run

# Add to crontab for automatic renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🛠️ Management Commands

### Using Management Script (Recommended)

```bash
# Start services
./manage_nginx.sh start

# Stop services
./manage_nginx.sh stop

# Restart services
./manage_nginx.sh restart

# View logs
./manage_nginx.sh logs

# Check status
./manage_nginx.sh status

# Test configuration
./manage_nginx.sh test
```

### Manual Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Specific service logs
docker logs nginx-proxy

# Last 100 lines
docker logs --tail 100 nginx-proxy

# Check status
docker-compose ps
docker ps | grep nginx

# Test configuration
docker exec nginx-proxy nginx -t

# Test SSL certificates
openssl s_client -connect app.soject.com:443 -servername app.soject.com

# Test HTTP to HTTPS redirect
curl -I http://app.soject.com
```

## 🔍 Troubleshooting

### Quick Diagnostics

```bash
# Comprehensive health check
./manage_nginx.sh health

# Check logs
./manage_nginx.sh logs-tail

# Test configuration
./manage_nginx.sh test
```

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using port 80/443
   sudo netstat -tlnp | grep :80
   sudo netstat -tlnp | grep :443
   sudo lsof -i :80
   sudo lsof -i :443
   
   # Stop conflicting services
   sudo systemctl stop apache2  # or nginx, or other web servers
   sudo systemctl disable apache2  # prevent auto-start
   ```

2. **SSL Certificate Errors**
   ```bash
   # Regenerate certificates
   ./manage_nginx.sh ssl
   
   # Check certificate validity
   openssl x509 -in ssl/app.soject.com.crt -text -noout
   
   # Check certificate dates
   openssl x509 -in ssl/app.soject.com.crt -noout -dates
   ```

3. **Domain Not Resolving**
   ```bash
   # Check DNS resolution
   nslookup app.soject.com
   dig app.soject.com
   
   # Check hosts file
   cat /etc/hosts | grep soject
   
   # Test with curl
   curl -v https://app.soject.com
   ```

4. **Service Not Accessible**
   ```bash
   # Check if backend services are running
   docker ps | grep web-app
   docker ps | grep phpmyadmin
   docker ps | grep portainer
   
   # Test direct access
   curl http://localhost:8080
   curl http://localhost:8082
   curl http://localhost:9000
   
   # Check service logs
   docker logs web-app
   docker logs phpmyadmin
   ```

5. **Nginx Configuration Errors**
   ```bash
   # Test configuration syntax
   ./manage_nginx.sh test
   
   # Check nginx error log
   docker exec nginx-proxy tail -f /var/log/nginx/error.log
   
   # Reload configuration
   docker exec nginx-proxy nginx -s reload
   ```

6. **Permission Issues**
   ```bash
   # Fix SSL certificate permissions
   chmod 600 ssl/*.key
   chmod 644 ssl/*.crt
   
   # Fix nginx log permissions
   sudo chown -R 101:101 logs/
   ```

### Log Analysis

```bash
# Access logs
docker exec nginx-proxy tail -f /var/log/nginx/access.log

# Error logs
docker exec nginx-proxy tail -f /var/log/nginx/error.log

# Real-time monitoring
docker exec nginx-proxy tail -f /var/log/nginx/*.log

# Search for specific errors
docker exec nginx-proxy grep -i error /var/log/nginx/error.log
```

### Network Diagnostics

```bash
# Check if ports are listening
netstat -tlnp | grep nginx
docker exec nginx-proxy netstat -tlnp

# Test connectivity
telnet localhost 80
telnet localhost 443

# Check firewall
sudo ufw status
sudo iptables -L
```

## 📊 Monitoring and Health Checks

### Health Check Endpoints

Each service has a health check endpoint:
- `https://app.soject.com/health`
- `https://admin.soject.com/`
- `https://docker.soject.com/`
- `https://gitlab.soject.com/help`
- `https://mail.soject.com/`

### Performance Monitoring

```bash
# Check nginx status
docker exec nginx-proxy nginx -V

# Monitor resource usage
docker stats nginx-proxy

# Check SSL certificate expiration
openssl x509 -in ssl/app.soject.com.crt -noout -dates

# Monitor connections
docker exec nginx-proxy ss -tuln
```

### Automated Health Checks

```bash
# Use the built-in health check
./manage_nginx.sh health

# Or create a custom health check script
cat > health_check.sh << 'EOF'
#!/bin/bash
domains=("app.soject.com" "admin.soject.com" "docker.soject.com" "gitlab.soject.com" "mail.soject.com")
for domain in "${domains[@]}"; do
    if curl -f -s -k "https://$domain" > /dev/null; then
        echo "✅ $domain is accessible"
    else
        echo "❌ $domain is not accessible"
    fi
done
EOF

chmod +x health_check.sh
./health_check.sh
```

## 🔧 Advanced Configuration

### Custom Upstream Servers

Edit `config/nginx.conf` to modify upstream definitions:

```nginx
upstream web_app {
    server 127.0.0.1:8080;
    # Add more servers for load balancing
    # server 127.0.0.1:8081;
    # server 127.0.0.1:8082;
}
```

### Rate Limiting

Modify rate limiting in `config/nginx.conf`:

```nginx
# Increase rate limits
limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

# Add to server blocks
limit_req zone=api burst=20 nodelay;
```

### Custom Headers

Add custom headers in domain configurations:

```nginx
add_header X-Custom-Header "value" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
```

### Load Balancing

Configure multiple backend servers:

```nginx
upstream web_app {
    server 127.0.0.1:8080 weight=3;
    server 127.0.0.1:8081 weight=2;
    server 127.0.0.1:8082 weight=1;
}
```

## 🔄 Updates and Maintenance

### Update Nginx

```bash
# Pull latest nginx image
docker-compose pull

# Restart with new image
docker-compose up -d

# Verify update
docker exec nginx-proxy nginx -v
```

### Renew SSL Certificates

```bash
# For Let's Encrypt certificates
sudo certbot renew

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/app.soject.com/fullchain.pem ssl/app.soject.com.crt
sudo cp /etc/letsencrypt/live/app.soject.com/privkey.pem ssl/app.soject.com.key

# Set permissions
chmod 600 ssl/*.key
chmod 644 ssl/*.crt

# Restart nginx
./manage_nginx.sh restart
```

### Backup Configuration

```bash
# Use the built-in backup command
./manage_nginx.sh backup

# Or create manual backup
tar -czf nginx-backup-$(date +%Y%m%d).tar.gz config/ ssl/ docker-compose.yml

# Restore from backup
tar -xzf nginx-backup-20231201.tar.gz
```

### Log Rotation

```bash
# Create log rotation configuration
sudo tee /etc/logrotate.d/nginx-docker << EOF
/var/lib/docker/containers/*/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
```

## 🛡️ Security Considerations

### SSL/TLS Security

- Use strong cipher suites
- Enable HSTS headers
- Regular certificate renewal
- Monitor certificate expiration

### Access Control

```bash
# Restrict access to admin interfaces
# Add to nginx configuration
allow 192.168.1.0/24;
deny all;
```

### Rate Limiting

```bash
# Configure rate limiting for API endpoints
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
```

### Security Headers

```nginx
# Add security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 22/tcp  # If using key-based SSH
```

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [SSL/TLS Best Practices](https://ssl-config.mozilla.org/)
- [Nginx Security Headers](https://securityheaders.com/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Create an issue with detailed information
4. Include relevant log output and error messages

### Getting Help

- **Documentation**: Check this README and inline comments
- **Logs**: Use `./manage_nginx.sh logs` for detailed error information
- **Health Check**: Use `./manage_nginx.sh health` for diagnostics
- **Community**: Create an issue with detailed problem description
- **Debugging**: Use the troubleshooting commands provided above

---

**Note**: This setup is designed for development and testing environments. For production use, ensure proper security measures, use real SSL certificates, and follow security best practices.

**⚠️ Security Warning**: Self-signed certificates are for development only. Always use trusted certificates in production environments. 