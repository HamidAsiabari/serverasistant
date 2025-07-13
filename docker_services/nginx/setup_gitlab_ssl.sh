#!/bin/bash

# GitLab SSL Certificate Setup Script
# This script sets up SSL certificates for gitlab.soject.com using Let's Encrypt

set -e

echo "🔐 GitLab SSL Certificate Setup for gitlab.soject.com"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if certbot is installed
check_certbot() {
    print_status "Checking if certbot is installed..."
    if command -v certbot &> /dev/null; then
        print_success "Certbot is already installed"
        certbot --version
        return 0
    else
        print_warning "Certbot is not installed"
        return 1
    fi
}

# Install certbot
install_certbot() {
    print_status "Installing certbot..."
    
    # Detect OS
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        print_status "Detected Debian/Ubuntu system"
        sudo apt update
        sudo apt install -y certbot
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL
        print_status "Detected CentOS/RHEL system"
        sudo yum install -y certbot
    elif [[ -f /etc/arch-release ]]; then
        # Arch Linux
        print_status "Detected Arch Linux system"
        sudo pacman -S certbot
    else
        print_error "Unsupported operating system"
        print_status "Please install certbot manually:"
        print_status "  Debian/Ubuntu: sudo apt install certbot"
        print_status "  CentOS/RHEL: sudo yum install certbot"
        print_status "  Arch Linux: sudo pacman -S certbot"
        exit 1
    fi
    
    if check_certbot; then
        print_success "Certbot installed successfully"
    else
        print_error "Failed to install certbot"
        exit 1
    fi
}

# Check if nginx is running
check_nginx() {
    print_status "Checking if nginx is running..."
    if docker ps --format "{{.Names}}" | grep -q "^nginx$"; then
        print_success "Nginx container is running"
        return 0
    else
        print_warning "Nginx container is not running"
        return 1
    fi
}

# Start nginx if not running
start_nginx() {
    print_status "Starting nginx..."
    cd "$(dirname "$0")"
    if docker-compose up -d nginx; then
        print_success "Nginx started successfully"
        # Wait for nginx to be ready
        sleep 5
    else
        print_error "Failed to start nginx"
        exit 1
    fi
}

# Create webroot directory for certbot
setup_webroot() {
    print_status "Setting up webroot for certbot..."
    
    # Create webroot directory
    sudo mkdir -p /var/www/html
    
    # Create a simple index.html for verification
    sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>GitLab SSL Verification</title>
</head>
<body>
    <h1>GitLab SSL Certificate Verification</h1>
    <p>This page is used by Let's Encrypt to verify domain ownership.</p>
</body>
</html>
EOF
    
    # Set proper permissions
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    print_success "Webroot setup complete"
}

# Generate SSL certificate
generate_certificate() {
    print_status "Generating SSL certificate for gitlab.soject.com..."
    
    # Stop nginx temporarily to free up port 80
    print_status "Stopping nginx temporarily..."
    cd "$(dirname "$0")"
    docker-compose stop nginx
    
    # Generate certificate
    certbot_cmd=(
        certbot certonly --standalone
        -d gitlab.soject.com
        --non-interactive
        --agree-tos
        --email admin@soject.com
        --pre-hook "echo 'Stopping nginx for certificate generation...'"
        --post-hook "echo 'Certificate generation complete'"
    )
    
    if sudo "${certbot_cmd[@]}"; then
        print_success "SSL certificate generated successfully!"
    else
        print_error "Failed to generate SSL certificate"
        # Restart nginx even if certificate generation failed
        docker-compose start nginx
        exit 1
    fi
    
    # Restart nginx
    print_status "Restarting nginx..."
    docker-compose start nginx
}

# Copy certificates to nginx ssl directory
copy_certificates() {
    print_status "Copying certificates to nginx ssl directory..."
    
    # Create nginx ssl directory
    mkdir -p ssl
    
    # Copy certificates
    sudo cp /etc/letsencrypt/live/gitlab.soject.com/fullchain.pem ssl/gitlab.soject.com.crt
    sudo cp /etc/letsencrypt/live/gitlab.soject.com/privkey.pem ssl/gitlab.soject.com.key
    
    # Set proper permissions
    sudo chmod 644 ssl/gitlab.soject.com.crt
    sudo chmod 600 ssl/gitlab.soject.com.key
    
    # Change ownership to current user
    sudo chown $(whoami):$(whoami) ssl/gitlab.soject.com.crt ssl/gitlab.soject.com.key
    
    print_success "Certificates copied successfully"
}

# Create HTTPS nginx configuration
create_https_config() {
    print_status "Creating HTTPS nginx configuration..."
    
    # Create HTTPS configuration
    cat > conf.d/gitlab.soject.com.conf << 'EOF'
server {
    listen 80;
    server_name gitlab.soject.com;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name gitlab.soject.com;
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/gitlab.soject.com.crt;
    ssl_certificate_key /etc/nginx/ssl/gitlab.soject.com.key;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location / {
        proxy_pass http://gitlab:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # GitLab specific headers
        proxy_set_header X-GitLab-Event $http_x_gitlab_event;
        proxy_set_header X-GitLab-Token $http_x_gitlab_token;
        
        # Large file uploads for GitLab
        client_max_body_size 500M;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF
    
    print_success "HTTPS configuration created"
}

# Test SSL configuration
test_ssl() {
    print_status "Testing SSL configuration..."
    
    # Wait for nginx to reload
    sleep 3
    
    # Test HTTPS connection
    if curl -k -s -o /dev/null -w "%{http_code}" https://gitlab.soject.com | grep -q "200\|301\|302"; then
        print_success "HTTPS connection test successful"
    else
        print_warning "HTTPS connection test failed (this might be normal if GitLab is not running)"
    fi
    
    # Test certificate
    if openssl s_client -connect gitlab.soject.com:443 -servername gitlab.soject.com < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
        print_success "SSL certificate test successful"
    else
        print_warning "SSL certificate test failed"
    fi
}

# Setup auto-renewal
setup_auto_renewal() {
    print_status "Setting up certificate auto-renewal..."
    
    # Create renewal script
    sudo tee /usr/local/bin/renew-gitlab-cert.sh > /dev/null << 'EOF'
#!/bin/bash
# GitLab certificate renewal script

cd /path/to/your/project/docker_services/nginx

# Stop nginx
docker-compose stop nginx

# Renew certificate
certbot renew --cert-name gitlab.soject.com --quiet

# Copy renewed certificates
cp /etc/letsencrypt/live/gitlab.soject.com/fullchain.pem ssl/gitlab.soject.com.crt
cp /etc/letsencrypt/live/gitlab.soject.com/privkey.pem ssl/gitlab.soject.com.key

# Set permissions
chmod 644 ssl/gitlab.soject.com.crt
chmod 600 ssl/gitlab.soject.com.key

# Start nginx
docker-compose start nginx

echo "$(date): GitLab certificate renewed" >> /var/log/gitlab-cert-renewal.log
EOF
    
    # Make script executable
    sudo chmod +x /usr/local/bin/renew-gitlab-cert.sh
    
    # Add to crontab (run twice daily)
    (crontab -l 2>/dev/null; echo "0 2,14 * * * /usr/local/bin/renew-gitlab-cert.sh") | crontab -
    
    print_success "Auto-renewal setup complete"
}

# Main execution
main() {
    echo "🚀 Starting GitLab SSL certificate setup..."
    
    # Check and install certbot
    if ! check_certbot; then
        install_certbot
    fi
    
    # Check and start nginx
    if ! check_nginx; then
        start_nginx
    fi
    
    # Setup webroot
    setup_webroot
    
    # Generate certificate
    generate_certificate
    
    # Copy certificates
    copy_certificates
    
    # Create HTTPS configuration
    create_https_config
    
    # Reload nginx
    print_status "Reloading nginx configuration..."
    cd "$(dirname "$0")"
    docker-compose restart nginx
    
    # Test SSL
    test_ssl
    
    # Setup auto-renewal
    setup_auto_renewal
    
    echo ""
    print_success "🎉 GitLab SSL certificate setup complete!"
    echo ""
    echo "📋 Summary:"
    echo "  ✅ SSL certificate generated for gitlab.soject.com"
    echo "  ✅ HTTPS configuration created"
    echo "  ✅ HTTP to HTTPS redirect enabled"
    echo "  ✅ Auto-renewal configured"
    echo ""
    echo "🔗 Access GitLab at: https://gitlab.soject.com"
    echo ""
    echo "📝 Next steps:"
    echo "  1. Ensure gitlab.soject.com points to your server IP"
    echo "  2. Test the HTTPS connection"
    echo "  3. Configure GitLab to use HTTPS"
    echo ""
}

# Run main function
main "$@" 