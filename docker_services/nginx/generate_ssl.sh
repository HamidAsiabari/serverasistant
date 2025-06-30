#!/bin/bash

# Generate self-signed SSL certificate for app.soject.com
# This script creates a self-signed certificate for development/testing

set -e

echo "🔐 Generating self-signed SSL certificate for app.soject.com..."

# Create ssl directory if it doesn't exist
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/app.soject.com.key \
    -out ssl/app.soject.com.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=app.soject.com"

# Set proper permissions
chmod 644 ssl/app.soject.com.crt
chmod 600 ssl/app.soject.com.key

echo "✅ SSL certificate generated successfully!"
echo "📁 Certificate files:"
echo "   - ssl/app.soject.com.crt"
echo "   - ssl/app.soject.com.key"
echo ""
echo "⚠️  Note: This is a self-signed certificate for development only."
echo "   For production, use Let's Encrypt or a commercial certificate."
echo ""
echo "🔍 To verify the certificate:"
echo "   openssl x509 -in ssl/app.soject.com.crt -text -noout" 