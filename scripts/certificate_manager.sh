#!/bin/bash

# GitLab Certificate Manager Script
# This script provides comprehensive SSL certificate management for gitlab.soject.com
# Can be used across different Ubuntu servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="gitlab.soject.com"
EMAIL="admin@soject.com"
NGINX_DIR="docker_services/nginx"
SSL_DIR="${NGINX_DIR}/ssl"
CONF_DIR="${NGINX_DIR}/conf.d"

# Function to print colored output
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                GitLab Certificate Manager                    ║"
    echo "║                    SSL Management Tool                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

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
        sudo pacman -S --noconfirm certbot
    else
        print_error "Unsupported operating system"
        print_info "Please install certbot manually:"
        print_info "  Debian/Ubuntu: sudo apt install certbot"
        print_info "  CentOS/RHEL: sudo yum install certbot"
        print_info "  Arch Linux: sudo pacman -S certbot"
        exit 1
    fi
    
    if check_certbot; then
        print_success "Certbot installed successfully"
    else
        print_error "Failed to install certbot"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    requirements_met=true
    
    # Check if domain resolves
    print_status "Checking if ${DOMAIN} resolves..."
    if nslookup ${DOMAIN} &> /dev/null; then
        print_success "Domain ${DOMAIN} resolves"
    else
        print_warning "Domain ${DOMAIN} does not resolve"
        requirements_met=false
    fi
    
    # Check if port 80 is available
    print_status "Checking if port 80 is available..."
    if netstat -tlnp 2>/dev/null | grep -q ":80 "; then
        print_warning "Port 80 is in use"
        requirements_met=false
    else
        print_success "Port 80 is available"
    fi
    
    # Check if port 443 is available
    print_status "Checking if port 443 is available..."
    if netstat -tlnp 2>/dev/null | grep -q ":443 "; then
        print_warning "Port 443 is in use"
    else
        print_success "Port 443 is available"
    fi
    
    # Check if nginx is running
    print_status "Checking if nginx is running..."
    if docker ps --format "{{.Names}}" | grep -q "^nginx$"; then
        print_success "Nginx container is running"
    else
        print_warning "Nginx container is not running"
    fi
    
    # Check if gitlab is running
    print_status "Checking if gitlab is running..."
    if docker ps --format "{{.Names}}" | grep -q "^gitlab$"; then
        print_success "GitLab container is running"
    else
        print_warning "GitLab container is not running"
    fi
    
    if [[ "$requirements_met" == "true" ]]; then
        print_success "All requirements met for SSL setup"
    else
        print_warning "Some requirements not met. SSL setup may fail."
        print_info "Please address the warnings above before proceeding."
    fi
}

# Start nginx if not running
start_nginx() {
    print_status "Starting nginx..."
    cd "${NGINX_DIR}"
    if docker-compose up -d nginx; then
        print_success "Nginx started successfully"
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
    print_status "Generating SSL certificate for ${DOMAIN}..."
    
    # Check if certbot is installed
    if ! check_certbot; then
        print_warning "Certbot is not installed. Installing certbot first..."
        install_certbot
    fi
    
    # Stop nginx temporarily to free up port 80
    print_status "Stopping nginx temporarily..."
    cd "${NGINX_DIR}"
    docker-compose stop nginx
    
    # Generate certificate
    certbot_cmd=(
        certbot certonly --standalone
        -d ${DOMAIN}
        --non-interactive
        --agree-tos
        --email ${EMAIL}
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
    mkdir -p ${SSL_DIR}
    
    # Copy certificates
    sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ${SSL_DIR}/${DOMAIN}.crt
    sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ${SSL_DIR}/${DOMAIN}.key
    
    # Set proper permissions
    sudo chmod 644 ${SSL_DIR}/${DOMAIN}.crt
    sudo chmod 600 ${SSL_DIR}/${DOMAIN}.key
    
    # Change ownership to current user
    sudo chown $(whoami):$(whoami) ${SSL_DIR}/${DOMAIN}.crt ${SSL_DIR}/${DOMAIN}.key
    
    print_success "Certificates copied successfully"
}

# Create HTTPS nginx configuration
create_https_config() {
    print_status "Creating HTTPS nginx configuration..."
    
    # Create HTTPS configuration
    cat > ${CONF_DIR}/${DOMAIN}.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/${DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/ssl/${DOMAIN}.key;
    
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
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # GitLab specific headers
        proxy_set_header X-GitLab-Event \$http_x_gitlab_event;
        proxy_set_header X-GitLab-Token \$http_x_gitlab_token;
        
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
    if curl -k -s -o /dev/null -w "%{http_code}" https://${DOMAIN} | grep -q "200\|301\|302"; then
        print_success "HTTPS connection test successful"
    else
        print_warning "HTTPS connection test failed (this might be normal if GitLab is not running)"
    fi
    
    # Test certificate
    if openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} < /dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
        print_success "SSL certificate test successful"
    else
        print_warning "SSL certificate test failed"
    fi
}

# Renew certificate
renew_certificate() {
    print_status "Renewing SSL certificate for ${DOMAIN}..."
    
    # Check if certbot is installed
    if ! check_certbot; then
        print_warning "Certbot is not installed. Installing certbot first..."
        install_certbot
    fi
    
    # Stop nginx temporarily
    cd "${NGINX_DIR}"
    docker-compose stop nginx
    
    # Renew certificate
    if sudo certbot renew --cert-name ${DOMAIN} --quiet; then
        print_success "Certificate renewed successfully!"
        
        # Copy renewed certificates
        copy_certificates
        
        # Start nginx
        docker-compose start nginx
        
        print_success "Nginx reloaded with renewed certificate!"
    else
        print_error "Failed to renew certificate"
        docker-compose start nginx
        exit 1
    fi
}

# View certificate status
view_certificate_status() {
    print_status "Checking certificate status..."
    
    # Check certificate expiration
    cert_path="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    if [[ ! -f "$cert_path" ]]; then
        print_warning "Certificate not found. Generate one first."
        return
    fi
    
    # Get certificate info
    cert_info=$(openssl x509 -in "$cert_path" -text -noout 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        # Extract expiration date
        expiry_date=$(echo "$cert_info" | grep "Not After" | sed 's/.*Not After : //')
        print_info "Certificate expires: $expiry_date"
        
        # Extract issuer
        issuer=$(echo "$cert_info" | grep "Issuer" | sed 's/.*Issuer: //')
        print_info "Issuer: $issuer"
        
        # Check if certificate is expired
        expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
        current_timestamp=$(date +%s)
        
        if [[ $expiry_timestamp -gt $current_timestamp ]]; then
            days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
            print_success "Certificate is valid (${days_left} days remaining)"
        else
            print_error "Certificate is expired!"
        fi
        
    else
        print_error "Failed to read certificate"
    fi
}

# Generate self-signed certificate
generate_self_signed() {
    print_status "Generating self-signed certificate for ${DOMAIN}..."
    
    # Create ssl directory
    mkdir -p ${SSL_DIR}
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ${SSL_DIR}/${DOMAIN}.key \
        -out ${SSL_DIR}/${DOMAIN}.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}"
    
    if [[ $? -eq 0 ]]; then
        # Set proper permissions
        chmod 644 ${SSL_DIR}/${DOMAIN}.crt
        chmod 600 ${SSL_DIR}/${DOMAIN}.key
        
        print_success "Self-signed certificate generated successfully!"
        print_info "Certificate files: ${SSL_DIR}/"
        
        # Configure HTTPS
        create_https_config
        
        # Reload nginx
        cd "${NGINX_DIR}"
        docker-compose restart nginx
        
        print_success "HTTPS configuration applied!"
    else
        print_error "Failed to generate self-signed certificate"
    fi
}

# Setup auto-renewal
setup_auto_renewal() {
    print_status "Setting up certificate auto-renewal..."
    
    # Create renewal script
    renewal_script_path="$(pwd)/scripts/renew_${DOMAIN}_cert.sh"
    mkdir -p scripts
    
    cat > "$renewal_script_path" << EOF
#!/bin/bash
# ${DOMAIN} certificate renewal script

cd "$(dirname "\$0")/../${NGINX_DIR}"

# Stop nginx
docker-compose stop nginx

# Renew certificate
certbot renew --cert-name ${DOMAIN} --quiet

# Copy renewed certificates
sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ssl/${DOMAIN}.crt
sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ssl/${DOMAIN}.key

# Set permissions
sudo chmod 644 ssl/${DOMAIN}.crt
sudo chmod 600 ssl/${DOMAIN}.key

# Start nginx
docker-compose start nginx

echo "\$(date): ${DOMAIN} certificate renewed" >> /var/log/gitlab-cert-renewal.log
EOF
    
    # Make script executable
    chmod +x "$renewal_script_path"
    
    # Add to crontab (run twice daily)
    cron_job="0 2,14 * * * $renewal_script_path"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$renewal_script_path"; then
        print_warning "Auto-renewal cron job already exists"
    else
        # Add new cron job
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        print_success "Auto-renewal cron job added"
    fi
    
    print_success "Auto-renewal setup complete!"
    print_info "Renewal script: $renewal_script_path"
    print_info "Will run twice daily at 2:00 AM and 2:00 PM"
}

# Complete SSL setup
complete_ssl_setup() {
    print_status "Running complete SSL setup for ${DOMAIN}..."
    
    # Step 1: Install certbot
    print_status "Step 1/7: Installing certbot..."
    if ! check_certbot; then
        install_certbot
    fi
    
    # Step 2: Check requirements
    print_status "Step 2/7: Checking system requirements..."
    check_requirements
    
    # Step 3: Start nginx if needed
    print_status "Step 3/7: Ensuring nginx is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "^nginx$"; then
        start_nginx
    fi
    
    # Step 4: Setup webroot
    print_status "Step 4/7: Setting up webroot..."
    setup_webroot
    
    # Step 5: Generate certificate
    print_status "Step 5/7: Generating SSL certificate..."
    generate_certificate
    
    # Step 6: Configure HTTPS
    print_status "Step 6/7: Configuring HTTPS..."
    copy_certificates
    create_https_config
    
    # Step 7: Setup auto-renewal
    print_status "Step 7/7: Setting up auto-renewal..."
    setup_auto_renewal
    
    # Reload nginx
    cd "${NGINX_DIR}"
    docker-compose restart nginx
    
    # Test SSL
    test_ssl
    
    print_success "🎉 Complete SSL setup finished!"
    print_info "🔗 Access GitLab at: https://${DOMAIN}"
}

# Show usage
show_usage() {
    print_banner
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  install-certbot     Install certbot for SSL certificate management"
    echo "  check-requirements  Check system requirements for SSL setup"
    echo "  generate-cert       Generate SSL certificate for ${DOMAIN}"
    echo "  configure-https     Configure nginx for HTTPS with HTTP to HTTPS redirect"
    echo "  test-ssl           Test SSL certificate and HTTPS configuration"
    echo "  renew-cert         Renew existing SSL certificate for ${DOMAIN}"
    echo "  view-status        View current certificate status and expiration"
    echo "  self-signed        Generate self-signed certificate for development/testing"
    echo "  auto-renewal       Setup automatic certificate renewal"
    echo "  complete-setup     Run complete SSL setup (install, generate, configure)"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 complete-setup    # Run complete SSL setup"
    echo "  $0 generate-cert     # Generate SSL certificate only"
    echo "  $0 test-ssl         # Test SSL configuration"
    echo ""
}

# Main function
main() {
    case "${1:-help}" in
        "install-certbot")
            check_root
            install_certbot
            ;;
        "check-requirements")
            check_root
            check_requirements
            ;;
        "generate-cert")
            check_root
            generate_certificate
            copy_certificates
            ;;
        "configure-https")
            check_root
            create_https_config
            cd "${NGINX_DIR}"
            docker-compose restart nginx
            ;;
        "test-ssl")
            test_ssl
            ;;
        "renew-cert")
            check_root
            renew_certificate
            ;;
        "view-status")
            view_certificate_status
            ;;
        "self-signed")
            generate_self_signed
            ;;
        "auto-renewal")
            check_root
            setup_auto_renewal
            ;;
        "complete-setup")
            check_root
            complete_ssl_setup
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run main function
main "$@" 