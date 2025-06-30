# Nginx Complete Setup Guide

This guide explains the complete nginx configuration setup for the server assistant project.

## Overview

The nginx configuration includes:
- **Reverse proxy** for multiple services
- **SSL/TLS termination** with self-signed certificates
- **Security headers** and rate limiting
- **Load balancing** for backend services
- **Logging** and monitoring

## Directory Structure

```
nginx/
├── config/
│   ├── nginx.conf              # Main nginx configuration
│   ├── mime.types              # MIME type definitions
│   └── conf.d/                 # Site-specific configurations
│       ├── default.conf        # Default server (fallback)
│       ├── app.soject.com.conf # Web application
│       ├── gitlab.soject.com.conf # GitLab instance
│       ├── docker.soject.com.conf # Portainer (Docker management)
│       ├── admin.soject.com.conf # phpMyAdmin
│       └── mail.soject.com.conf # Roundcube mail
├── ssl/                        # SSL certificates
├── logs/                       # Nginx logs
├── docker-compose.yml          # Docker configuration
├── generate_ssl.sh             # SSL certificate generation (Linux)
├── generate_ssl.bat            # SSL certificate generation (Windows)
├── setup_complete.sh           # Complete setup script (Linux)
├── setup_complete.bat          # Complete setup script (Windows)
└── README.md                   # This file
```

## Services Configuration

### Upstream Services

The nginx configuration proxies to these backend services:

| Service | Domain | Port | Description |
|---------|--------|------|-------------|
| Web App | app.soject.com | 8080 | Main web application |
| GitLab | gitlab.soject.com | 8081 | Git repository management |
| Portainer | docker.soject.com | 9000 | Docker container management |
| phpMyAdmin | admin.soject.com | 8082 | MySQL database management |
| Roundcube | mail.soject.com | 8083 | Webmail interface |

### SSL Configuration

- **Protocols**: TLS 1.2 and 1.3 only
- **Ciphers**: Strong encryption ciphers
- **Session cache**: 10 minutes
- **HSTS**: Enabled with 1-year max age

### Security Features

- **Rate limiting**: API endpoints (30 req/min), login (10 req/min)
- **Security headers**: XSS protection, content type options, frame options
- **CSP**: Content Security Policy headers
- **HTTP to HTTPS**: Automatic redirects

## Quick Setup

### Linux/macOS

1. **Run the complete setup script:**
   ```bash
   chmod +x setup_complete.sh
   ./setup_complete.sh
   ```

2. **Start nginx:**
   ```bash
   ./start_nginx.sh
   ```

### Windows

1. **Run the complete setup script:**
   ```cmd
   setup_complete.bat
   ```

2. **Start nginx:**
   ```cmd
   start_nginx.bat
   ```

## Manual Setup

If you prefer to set up manually:

### 1. Create Directories

```bash
mkdir -p logs ssl config/conf.d
```

### 2. Generate SSL Certificates

**Linux/macOS:**
```bash
chmod +x generate_ssl.sh
./generate_ssl.sh
```

**Windows:**
```cmd
generate_ssl.bat
```

### 3. Start Nginx

```bash
docker-compose up -d --build
```

## Configuration Details

### Main Configuration (`nginx.conf`)

- **Worker processes**: Auto-detected
- **Worker connections**: 1024 per worker
- **Client max body size**: 100MB
- **Gzip compression**: Enabled for text content
- **Logging**: Combined format with access and error logs

### Site Configurations

Each site configuration includes:
- HTTP to HTTPS redirect
- SSL certificate configuration
- Security headers
- Proxy settings with proper headers
- WebSocket support (where applicable)
- Timeout configurations

### SSL Certificates

**Self-signed certificates are generated for:**
- `default` (fallback for unknown domains)
- `app.soject.com`
- `gitlab.soject.com`
- `docker.soject.com`
- `admin.soject.com`
- `mail.soject.com`

**For production use:**
Replace self-signed certificates with proper certificates from a trusted CA.

## Management Commands

### Start Nginx
```bash
./start_nginx.sh          # Linux/macOS
start_nginx.bat           # Windows
```

### Stop Nginx
```bash
./stop_nginx.sh           # Linux/macOS
stop_nginx.bat            # Windows
```

### Restart Nginx
```bash
./restart_nginx.sh        # Linux/macOS
restart_nginx.bat         # Windows
```

### View Logs
```bash
docker-compose logs -f nginx
```

### Check Status
```bash
docker-compose ps
```

### Test Configuration
```bash
docker-compose exec nginx nginx -t
```

## Troubleshooting

### Common Issues

1. **Port 80/443 already in use:**
   ```bash
   sudo netstat -tulpn | grep :80
   sudo netstat -tulpn | grep :443
   ```

2. **SSL certificate errors:**
   - Check certificate files exist in `ssl/` directory
   - Verify certificate permissions (should be 600)
   - Regenerate certificates if needed

3. **Backend services not accessible:**
   - Verify backend services are running
   - Check upstream server addresses in `nginx.conf`
   - Test connectivity to backend ports

4. **Configuration errors:**
   ```bash
   docker-compose exec nginx nginx -t
   ```

### Log Analysis

**Access logs:**
```bash
docker-compose exec nginx tail -f /var/log/nginx/access.log
```

**Error logs:**
```bash
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

### SSL Certificate Issues

**Check certificate validity:**
```bash
openssl x509 -in ssl/app.soject.com.crt -text -noout
```

**Test SSL connection:**
```bash
openssl s_client -connect app.soject.com:443 -servername app.soject.com
```

## Development vs Production

### Development Setup
- Self-signed SSL certificates
- All services on localhost
- Debug logging enabled
- No external domain requirements

### Production Setup
- Proper SSL certificates from trusted CA
- Real domain names
- Optimized logging
- Security hardening
- Load balancing configuration

## Security Considerations

1. **SSL Certificates**: Use proper certificates in production
2. **Rate Limiting**: Adjust limits based on your needs
3. **Security Headers**: Review and customize as needed
4. **Access Control**: Consider adding IP restrictions
5. **Monitoring**: Set up log monitoring and alerting

## Performance Tuning

### Worker Processes
```nginx
worker_processes auto;  # Adjust based on CPU cores
```

### Worker Connections
```nginx
worker_connections 1024;  # Adjust based on memory
```

### Buffer Sizes
```nginx
client_body_buffer_size 128k;
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;
```

### Gzip Compression
Already configured for optimal compression of text content.

## Monitoring

### Health Check
```bash
curl -k https://app.soject.com/health
```

### Status Page
Consider adding nginx status page for monitoring:
```nginx
location /nginx_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
```

## Backup and Recovery

### Configuration Backup
```bash
tar -czf nginx-config-backup-$(date +%Y%m%d).tar.gz config/ ssl/ logs/
```

### Restore Configuration
```bash
tar -xzf nginx-config-backup-YYYYMMDD.tar.gz
docker-compose restart nginx
```

## Support

For issues and questions:
1. Check the logs first
2. Verify configuration syntax
3. Test connectivity to backend services
4. Review this documentation
5. Check Docker and nginx documentation 