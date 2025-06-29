#!/bin/bash

# Cleanup script to remove old example.com configurations
# and ensure soject.com configurations are in place

echo "=== Cleaning up old Nginx configurations ==="

# Remove old example.com configuration files
echo "Removing old example.com configuration files..."
rm -f config/conf.d/app.example.com.conf
rm -f config/conf.d/admin.example.com.conf
rm -f config/conf.d/docker.example.com.conf
rm -f config/conf.d/git.example.com.conf
rm -f config/conf.d/mail.example.com.conf

# Remove old SSL certificates
echo "Removing old example.com SSL certificates..."
rm -f ssl/app.example.com.crt
rm -f ssl/app.example.com.key
rm -f ssl/admin.example.com.crt
rm -f ssl/admin.example.com.key
rm -f ssl/docker.example.com.crt
rm -f ssl/docker.example.com.key
rm -f ssl/git.example.com.crt
rm -f ssl/git.example.com.key
rm -f ssl/mail.example.com.crt
rm -f ssl/mail.example.com.key

# Verify soject.com configurations exist
echo "Verifying soject.com configurations..."
required_files=(
    "config/conf.d/app.soject.com.conf"
    "config/conf.d/admin.soject.com.conf"
    "config/conf.d/docker.soject.com.conf"
    "config/conf.d/gitlab.soject.com.conf"
    "config/conf.d/mail.soject.com.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo "Cleanup completed!"
echo "Run setup_nginx.sh to generate new SSL certificates for soject.com domains" 