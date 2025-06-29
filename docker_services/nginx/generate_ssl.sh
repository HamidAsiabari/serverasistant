#!/bin/bash

# Generate SSL certificates for all domains
# This script creates self-signed certificates for development/testing

set -e

SSL_DIR="./ssl"
CONFIG_DIR="./config"

# Create SSL directory
mkdir -p "$SSL_DIR"

# Function to generate certificate
generate_cert() {
    local domain=$1
    local cert_file="$SSL_DIR/${domain}.crt"
    local key_file="$SSL_DIR/${domain}.key"
    
    echo "Generating SSL certificate for $domain..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_file" \
        -out "$cert_file" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" \
        -addext "subjectAltName=DNS:$domain,DNS:www.$domain"
    
    echo "Certificate generated: $cert_file"
}

# Generate certificates for all domains
domains=(
    "app.soject.com"
    "admin.soject.com"
    "docker.soject.com"
    "gitlab.soject.com"
    "mail.soject.com"
)

for domain in "${domains[@]}"; do
    generate_cert "$domain"
done

# Generate default certificate
echo "Generating default SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$SSL_DIR/default.key" \
    -out "$SSL_DIR/default.crt" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=default" \
    -addext "subjectAltName=DNS:localhost,DNS:default"

echo "All SSL certificates generated successfully!"
echo "Note: These are self-signed certificates for development/testing."
echo "For production, use certificates from a trusted CA like Let's Encrypt." 