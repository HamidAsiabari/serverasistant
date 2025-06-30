# Nginx Reverse Proxy Service

A production-ready nginx reverse proxy service configured for the `app.soject.com` domain with SSL support, security headers, and performance optimizations.

## Features

- ✅ **Latest nginx version** - Always up-to-date with security patches
- ✅ **SSL/HTTPS support** - Automatic HTTP to HTTPS redirect
- ✅ **Security headers** - HSTS, XSS protection, content type options
- ✅ **Rate limiting** - API protection against abuse
- ✅ **Gzip compression** - Optimized content delivery
- ✅ **WebSocket support** - Real-time application support
- ✅ **Static file caching** - Improved performance for assets
- ✅ **Health check endpoint** - Monitoring integration
- ✅ **Comprehensive logging** - Access and error logs

## Configuration Files

- `docker-compose.yml` - Service definition and networking
- `nginx.conf` - Main nginx configuration
- `conf.d/app.soject.com.conf` - Domain-specific server configuration
- `ssl/` - SSL certificates directory

## Quick Start

### 1. Add SSL Certificates
Place your SSL certificates in the `ssl/` directory:
- `app.soject.com.crt` - Certificate file
- `app.soject.com.key` - Private key file

### 2. Start the Service
```bash
cd docker_services/nginx
docker-compose up -d
```

### 3. Test Configuration
```bash
# Test nginx configuration
docker-compose exec nginx nginx -t

# Check service status
docker-compose ps

# View logs
docker-compose logs nginx
```

## Domain Configuration

The service is configured for `app.soject.com` with:

- **HTTP (Port 80)**: Redirects to HTTPS
- **HTTPS (Port 443)**: Main application serving
- **Proxy**: Forwards requests to `web-app:8080`

## Adding More Domains

To add additional domains, create new configuration files in `conf.d/`:

```bash
# Example: api.soject.com.conf
cp conf.d/app.soject.com.conf conf.d/api.soject.com.conf
```

Then edit the new file to update:
- `server_name` directive
- SSL certificate paths
- Log file names
- Proxy destination (if different)

## SSL Certificate Management

### Let's Encrypt (Recommended)
```bash
# Install certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d app.soject.com

# Copy to nginx ssl directory
sudo cp /etc/letsencrypt/live/app.soject.com/fullchain.pem ./ssl/app.soject.com.crt
sudo cp /etc/letsencrypt/live/app.soject.com/privkey.pem ./ssl/app.soject.com.key
```

### Self-Signed (Development)
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/app.soject.com.key \
    -out ssl/app.soject.com.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=app.soject.com"
```

## Monitoring

### Health Check
```bash
curl -k https://app.soject.com/health
```

### Log Monitoring
```bash
# Access logs
docker-compose exec nginx tail -f /var/log/nginx/app.soject.com.access.log

# Error logs
docker-compose exec nginx tail -f /var/log/nginx/app.soject.com.error.log
```

### SSL Certificate Expiry
```bash
# Check certificate expiry
openssl x509 -in ssl/app.soject.com.crt -text -noout | grep "Not After"
```

## Security Features

- **HSTS**: Strict Transport Security headers
- **XSS Protection**: Cross-site scripting protection
- **Content Type Options**: MIME type sniffing protection
- **Frame Options**: Clickjacking protection
- **Rate Limiting**: API abuse prevention
- **Hidden File Protection**: Blocks access to dot files

## Performance Optimizations

- **Gzip Compression**: Reduces bandwidth usage
- **Static File Caching**: Long-term caching for assets
- **Connection Pooling**: Efficient connection management
- **Sendfile**: Optimized file serving
- **HTTP/2**: Modern protocol support

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   - Ensure certificates are in the correct location
   - Check file permissions (644 for .crt, 600 for .key)
   - Verify certificate validity

2. **502 Bad Gateway**
   - Check if web-app service is running
   - Verify network connectivity between containers
   - Check web-app logs

3. **Permission Denied**
   - Ensure nginx can read configuration files
   - Check SSL certificate permissions

### Debug Commands
```bash
# Test nginx configuration
docker-compose exec nginx nginx -t

# Check nginx process
docker-compose exec nginx ps aux

# View nginx configuration
docker-compose exec nginx cat /etc/nginx/nginx.conf

# Check SSL certificate
docker-compose exec nginx openssl x509 -in /etc/nginx/ssl/app.soject.com.crt -text -noout
```

## Integration with ServerAssistant

This nginx service is integrated with the ServerAssistant configuration system. The service will be managed through the main application interface and can be started/stopped/monitored alongside other services. 