#!/bin/bash

# DNS and domain testing script
# This script helps diagnose domain resolution issues

set -e

echo "🔍 Testing DNS and Domain Resolution..."

# Test local DNS resolution
echo "📡 Testing DNS resolution for app.soject.com..."
if nslookup app.soject.com > /dev/null 2>&1; then
    echo "✅ DNS resolution works for app.soject.com"
    nslookup app.soject.com
else
    echo "❌ DNS resolution failed for app.soject.com"
fi

echo ""
echo "📡 Testing DNS resolution for gitlab.soject.com..."
if nslookup gitlab.soject.com > /dev/null 2>&1; then
    echo "✅ DNS resolution works for gitlab.soject.com"
    nslookup gitlab.soject.com
else
    echo "❌ DNS resolution failed for gitlab.soject.com"
fi

echo ""
echo "🌐 Testing HTTP connections..."

# Test app.soject.com
echo "🔗 Testing app.soject.com..."
if curl -s --connect-timeout 5 http://app.soject.com > /dev/null 2>&1; then
    echo "✅ app.soject.com is accessible"
    echo "📄 Response: $(curl -s http://app.soject.com)"
else
    echo "❌ app.soject.com is not accessible"
fi

# Test gitlab.soject.com
echo "🔗 Testing gitlab.soject.com..."
if curl -s --connect-timeout 5 http://gitlab.soject.com > /dev/null 2>&1; then
    echo "✅ gitlab.soject.com is accessible"
    echo "📄 Response: $(curl -s http://gitlab.soject.com)"
else
    echo "❌ gitlab.soject.com is not accessible"
fi

# Test localhost
echo "🔗 Testing localhost:80..."
if curl -s --connect-timeout 5 http://localhost:80 > /dev/null 2>&1; then
    echo "✅ localhost:80 is accessible"
    echo "📄 Response: $(curl -s http://localhost:80)"
else
    echo "❌ localhost:80 is not accessible"
fi

echo ""
echo "🔧 Checking nginx configuration..."
if docker-compose exec nginx nginx -t > /dev/null 2>&1; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    docker-compose exec nginx nginx -t
fi

echo ""
echo "📋 Summary:"
echo "   - If app.soject.com DNS fails: Add to hosts file or configure DNS"
echo "   - If app.soject.com DNS works but HTTP fails: Check firewall/port 80"
echo "   - If localhost works but domain doesn't: DNS/hosts file issue" 