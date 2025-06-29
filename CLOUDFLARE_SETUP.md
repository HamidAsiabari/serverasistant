# Cloudflare DNS Setup for soject.com Subdomains

This guide will help you configure your soject.com subdomains in Cloudflare to point to your server.

## Required DNS Records

Configure the following A records in your Cloudflare DNS settings:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | `app` | `YOUR_SERVER_IP` | Proxied (Orange Cloud) |
| A | `admin` | `YOUR_SERVER_IP` | Proxied (Orange Cloud) |
| A | `docker` | `YOUR_SERVER_IP` | Proxied (Orange Cloud) |
| A | `gitlab` | `YOUR_SERVER_IP` | Proxied (Orange Cloud) |
| A | `mail` | `YOUR_SERVER_IP` | Proxied (Orange Cloud) |

## Step-by-Step Setup

### 1. Access Cloudflare Dashboard

1. Log in to your Cloudflare account
2. Select your `soject.com` domain
3. Go to the **DNS** tab

### 2. Add DNS Records

For each subdomain, add an A record:

1. Click **Add record**
2. Set **Type** to `A`
3. Set **Name** to the subdomain (e.g., `app`, `admin`, `docker`, `gitlab`, `mail`)
4. Set **IPv4 address** to your server's IP address
5. Enable **Proxy status** (Orange cloud icon)
6. Click **Save**

### 3. SSL/TLS Configuration

1. Go to the **SSL/TLS** tab
2. Set **Encryption mode** to `Full (strict)`
3. Enable **Always Use HTTPS**
4. Enable **Minimum TLS Version** to `1.2`

### 4. Security Settings

1. Go to the **Security** tab
2. Set **Security Level** to `Medium`
3. Enable **Browser Integrity Check`
4. Configure **Rate Limiting** if needed

### 5. Page Rules (Optional)

Create page rules for additional security:

| URL Pattern | Settings |
|-------------|----------|
| `app.soject.com/*` | Security Level: High, Always Use HTTPS |
| `admin.soject.com/*` | Security Level: High, Always Use HTTPS |
| `docker.soject.com/*` | Security Level: High, Always Use HTTPS |
| `gitlab.soject.com/*` | Security Level: High, Always Use HTTPS |
| `mail.soject.com/*` | Security Level: High, Always Use HTTPS |

## Service URLs

Once configured, your services will be accessible at:

- **Web Application**: https://app.soject.com
- **Database Admin**: https://admin.soject.com
- **Docker Management**: https://docker.soject.com
- **GitLab**: https://gitlab.soject.com
- **Webmail**: https://mail.soject.com

## SSL Certificate Setup

### Option 1: Let's Encrypt (Recommended)

1. Install Certbot on your server:
```bash
sudo apt update
sudo apt install certbot
```

2. Generate certificates for each domain:
```bash
sudo certbot certonly --webroot -w /var/www/html -d app.soject.com
sudo certbot certonly --webroot -w /var/www/html -d admin.soject.com
sudo certbot certonly --webroot -w /var/www/html -d docker.soject.com
sudo certbot certonly --webroot -w /var/www/html -d gitlab.soject.com
sudo certbot certonly --webroot -w /var/www/html -d mail.soject.com
```

3. Update Nginx configuration files to use the new certificates:
```nginx
ssl_certificate /etc/letsencrypt/live/app.soject.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/app.soject.com/privkey.pem;
```

### Option 2: Cloudflare Origin Certificates

1. Go to **SSL/TLS** > **Origin Server**
2. Click **Create Certificate**
3. Set **Hostnames** to include all your subdomains
4. Download the certificate and private key
5. Place them in your Nginx SSL directory
6. Update Nginx configurations

## Testing Your Setup

### 1. DNS Propagation

Check if DNS records are propagated:
```bash
nslookup app.soject.com
nslookup admin.soject.com
nslookup docker.soject.com
nslookup gitlab.soject.com
nslookup mail.soject.com
```

### 2. SSL Certificate Verification

Test SSL certificates:
```bash
openssl s_client -connect app.soject.com:443 -servername app.soject.com
openssl s_client -connect admin.soject.com:443 -servername admin.soject.com
openssl s_client -connect docker.soject.com:443 -servername docker.soject.com
openssl s_client -connect gitlab.soject.com:443 -servername gitlab.soject.com
openssl s_client -connect mail.soject.com:443 -servername mail.soject.com
```

### 3. Service Accessibility

Test each service:
```bash
curl -I https://app.soject.com/health
curl -I https://admin.soject.com
curl -I https://docker.soject.com
curl -I https://gitlab.soject.com
curl -I https://mail.soject.com
```

## Troubleshooting

### Common Issues

1. **DNS Not Propagated**
   - Wait 5-10 minutes for DNS propagation
   - Check with `nslookup` or `dig`
   - Verify Cloudflare proxy is enabled (orange cloud)

2. **SSL Certificate Errors**
   - Ensure Cloudflare SSL/TLS is set to "Full (strict)"
   - Check if origin certificates are properly installed
   - Verify certificate paths in Nginx configuration

3. **Service Not Accessible**
   - Check if Nginx container is running
   - Verify backend services are started
   - Check Nginx logs: `docker logs nginx-proxy`

4. **Cloudflare 502/503 Errors**
   - Check if your server is accessible directly
   - Verify firewall allows ports 80 and 443
   - Check Nginx configuration syntax

### Debug Commands

```bash
# Check Nginx status
docker ps | grep nginx

# View Nginx logs
docker logs nginx-proxy

# Test Nginx configuration
docker exec nginx-proxy nginx -t

# Check SSL certificates
ls -la example_services/nginx/ssl/

# Test local connectivity
curl -I http://localhost
curl -I https://localhost
```

## Security Recommendations

1. **Enable Cloudflare Security Features**
   - WAF (Web Application Firewall)
   - Rate Limiting
   - DDoS Protection
   - Bot Management

2. **Configure Firewall Rules**
   - Allow only Cloudflare IPs to access your server
   - Block direct access to ports 80/443 from other sources

3. **Regular Maintenance**
   - Keep SSL certificates updated
   - Monitor Cloudflare analytics
   - Review security logs regularly

## Next Steps

1. Set up monitoring and alerting
2. Configure backup strategies
3. Implement logging and analytics
4. Set up CI/CD pipelines for deployment
5. Configure email services for notifications

## Support

If you encounter issues:

1. Check Cloudflare status page
2. Review Nginx and Docker logs
3. Test connectivity step by step
4. Verify all configuration files
5. Ensure all services are running properly 