#!/bin/bash

# Generate SSL certificates for all domains
# This script creates self-signed certificates for development/testing

SSL_DIR="./ssl"
mkdir -p $SSL_DIR

# List of domains
DOMAINS=("app.soject.com" "admin.soject.com" "docker.soject.com" "gitlab.soject.com" "mail.soject.com")

# Generate certificates for each domain
for domain in "${DOMAINS[@]}"; do
    echo "Generating SSL certificate for $domain..."
    
    # Generate private key
    openssl genrsa -out "$SSL_DIR/$domain.key" 2048
    
    # Generate certificate signing request
    openssl req -new -key "$SSL_DIR/$domain.key" -out "$SSL_DIR/$domain.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "$SSL_DIR/$domain.csr" -signkey "$SSL_DIR/$domain.key" -out "$SSL_DIR/$domain.crt"
    
    # Remove CSR file
    rm "$SSL_DIR/$domain.csr"
    
    echo "Certificate for $domain created successfully!"
done

# Generate default certificate for unknown domains
echo "Generating default SSL certificate..."
openssl genrsa -out "$SSL_DIR/default.key" 2048
openssl req -new -key "$SSL_DIR/default.key" -out "$SSL_DIR/default.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=default"
openssl x509 -req -days 365 -in "$SSL_DIR/default.csr" -signkey "$SSL_DIR/default.key" -out "$SSL_DIR/default.crt"
rm "$SSL_DIR/default.csr"

echo "All SSL certificates generated successfully!"
echo "Certificates are located in: $SSL_DIR" 