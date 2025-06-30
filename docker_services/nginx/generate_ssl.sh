#!/bin/bash

# Generate SSL certificates for nginx domains
# This script creates self-signed certificates for development purposes

SSL_DIR="./ssl"
DOMAINS=("default" "app.soject.com" "gitlab.soject.com" "docker.soject.com" "admin.soject.com" "mail.soject.com")

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Generate certificates for each domain
for domain in "${DOMAINS[@]}"; do
    echo "Generating SSL certificate for $domain..."
    
    if [ "$domain" = "default" ]; then
        # Default certificate for unknown domains
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/default.key" \
            -out "$SSL_DIR/default.crt" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=default"
    else
        # Domain-specific certificates
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$SSL_DIR/$domain.key" \
            -out "$SSL_DIR/$domain.crt" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    fi
    
    echo "Certificate for $domain created successfully"
done

echo "All SSL certificates generated successfully!"
echo "Note: These are self-signed certificates for development use only."
echo "For production, use proper SSL certificates from a trusted CA." 