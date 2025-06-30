# SSL Certificates for app.soject.com

This directory should contain SSL certificates for the `app.soject.com` domain.

## Required Files

Place the following files in this directory:

- `app.soject.com.crt` - SSL certificate file
- `app.soject.com.key` - Private key file

## Getting SSL Certificates

### Option 1: Let's Encrypt (Recommended)
```bash
# Install certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d app.soject.com

# Copy certificates to this directory
sudo cp /etc/letsencrypt/live/app.soject.com/fullchain.pem ./app.soject.com.crt
sudo cp /etc/letsencrypt/live/app.soject.com/privkey.pem ./app.soject.com.key
```

### Option 2: Self-Signed Certificate (Development)
```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout app.soject.com.key \
    -out app.soject.com.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=app.soject.com"
```

### Option 3: Commercial Certificate
If you have a commercial SSL certificate, place the certificate and private key files here with the correct names.

## File Permissions
Ensure proper file permissions:
```bash
chmod 644 app.soject.com.crt
chmod 600 app.soject.com.key
```

## Auto-renewal (Let's Encrypt)
For Let's Encrypt certificates, set up auto-renewal:
```bash
# Add to crontab
0 12 * * * /usr/bin/certbot renew --quiet
```

## Testing
After placing certificates, test the configuration:
```bash
docker-compose exec nginx nginx -t
``` 