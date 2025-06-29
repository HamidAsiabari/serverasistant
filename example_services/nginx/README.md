# Nginx Reverse Proxy with Domain Configuration

This Nginx setup provides a reverse proxy with custom domains for all services in your Docker environment.

## Domain Configuration

| Service | Domain | Description |
|---------|--------|-------------|
| Web Application | `app.soject.com` | Main Flask web application |
| Database Admin | `admin.soject.com` | phpMyAdmin for MySQL management |
| Docker Management | `docker.soject.com` | Portainer for Docker container management |
| Git Repository | `gitlab.soject.com` | GitLab for source code management |
| Webmail | `mail.soject.com` | Roundcube webmail interface |

## Features

- **SSL/TLS Support**: HTTPS with modern cipher suites
- **Security Headers**: HSTS, XSS protection, content type options
- **Rate Limiting**: Protection against brute force attacks
- **WebSocket Support**: For real-time applications like Portainer
- **Large File Uploads**: Optimized for GitLab and file uploads
- **Health Checks**: Dedicated health check endpoints
- **Logging**: Comprehensive access and error logging

## Quick Start

### 1. Generate SSL Certificates

```bash
cd example_services/nginx
chmod +x generate_ssl.sh
./generate_ssl.sh
```

### 2. Update Hosts File (Development)

Add these entries to your `/etc/hosts` file (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
127.0.0.1 app.soject.com
127.0.0.1 admin.soject.com
127.0.0.1 docker.soject.com
127.0.0.1 gitlab.soject.com
127.0.0.1 mail.soject.com
```

### 3. Start Nginx

```bash
docker-compose up -d
```

## Configuration Details

### SSL/TLS Configuration

- **Protocols**: TLSv1.2 and TLSv1.3 only
- **Ciphers**: Modern, secure cipher suites
- **Session Cache**: 10-minute session timeout
- **HSTS**: Strict Transport Security enabled

### Security Features

- **Rate Limiting**: 
  - Login endpoints: 10 requests per minute
  - API endpoints: 30 requests per minute
- **Security Headers**: X-Frame-Options, XSS Protection, Content Type Options
- **File Access Control**: Blocks access to sensitive files

### Performance Optimizations

- **Gzip Compression**: Enabled for text-based content
- **Connection Pooling**: Optimized worker connections
- **Timeouts**: Configured for different service requirements
- **Client Body Size**: 100MB default, 500MB for GitLab

## Service-Specific Configurations

### Web Application (`app.soject.com`)
- WebSocket support for real-time features
- API rate limiting
- Health check endpoint

### phpMyAdmin (`admin.soject.com`)
- Enhanced login rate limiting
- Sensitive file access blocking
- Database management interface

### Portainer (`docker.soject.com`)
- WebSocket support for container management
- API rate limiting
- Docker socket access

### GitLab (`gitlab.soject.com`)
- Large file upload support (500MB)
- Extended timeouts for Git operations
- Git protocol support
- Repository access patterns

### Roundcube (`mail.soject.com`)
- Email web interface
- Login rate limiting
- Secure file access

## Production Deployment

### 1. Replace Self-Signed Certificates

For production, replace self-signed certificates with trusted certificates:

```bash
# Using Let's Encrypt with Certbot
certbot certonly --webroot -w /var/www/html -d app.soject.com
certbot certonly --webroot -w /var/www/html -d admin.soject.com
# ... repeat for all domains
```

### 2. Update Certificate Paths

Update the SSL certificate paths in each domain configuration file:

```nginx
ssl_certificate /etc/letsencrypt/live/app.soject.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/app.soject.com/privkey.pem;
```

### 3. DNS Configuration

Configure your DNS provider to point domains to your server's IP address:

```
A    app.soject.com    YOUR_SERVER_IP
A    admin.soject.com  YOUR_SERVER_IP
A    docker.soject.com YOUR_SERVER_IP
A    gitlab.soject.com YOUR_SERVER_IP
A    mail.soject.com   YOUR_SERVER_IP
```

### 4. Firewall Configuration

Ensure ports 80 and 443 are open:

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

## Monitoring and Logs

### Access Logs
- Location: `/var/log/nginx/access.log`
- Format: Combined log format with X-Forwarded-For

### Error Logs
- Location: `/var/log/nginx/error.log`
- Level: Warning and above

### Log Rotation
Configure log rotation in `/etc/logrotate.d/nginx`:

```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 nginx nginx
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
    endscript
}
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   - Ensure certificates are in the correct location
   - Check certificate permissions (readable by nginx)
   - Verify certificate validity dates

2. **Connection Refused**
   - Check if backend services are running
   - Verify network connectivity between containers
   - Check Docker network configuration

3. **Rate Limiting Issues**
   - Adjust rate limiting zones in nginx.conf
   - Check client IP forwarding configuration

4. **Large File Upload Failures**
   - Increase `client_max_body_size` in domain configs
   - Check backend service upload limits

### Debug Commands

```bash
# Check Nginx configuration
docker exec nginx-proxy nginx -t

# View Nginx logs
docker logs nginx-proxy

# Test domain resolution
curl -I https://app.soject.com

# Check SSL certificate
openssl s_client -connect app.soject.com:443 -servername app.soject.com
```

## Customization

### Adding New Domains

1. Create a new configuration file in `config/conf.d/`
2. Generate SSL certificate for the domain
3. Update the main nginx.conf with upstream definition
4. Restart Nginx container

### Modifying Rate Limits

Edit the rate limiting zones in `nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=custom:10m rate=20r/m;
```

### Custom Security Headers

Add custom headers in domain configurations:

```nginx
add_header Custom-Header "value" always;
```

## Integration with Docker Manager

The Nginx service is integrated with the Docker Manager system:

- **Service Name**: `nginx`
- **Ports**: 80, 443
- **Dependencies**: All other services
- **Networks**: Connected to all service networks

Update your `config.json` to include Nginx:

```json
{
  "services": {
    "nginx": {
      "enabled": true,
      "domain": "nginx.example.com"
    }
  }
}
```

## Next Steps

1. **Load Balancing**: Add multiple backend instances
2. **Caching**: Implement Redis-based caching
3. **CDN Integration**: Configure CDN for static assets
4. **Monitoring**: Add Prometheus/Grafana monitoring
5. **Backup**: Implement SSL certificate backup strategy 