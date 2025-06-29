#!/bin/bash
# Script to check MySQL container status and logs

echo "=== MySQL Container Status ==="
docker ps -a | grep mysql

echo ""
echo "=== MySQL Container Logs ==="
docker logs mysql

echo ""
echo "=== MySQL Container Details ==="
docker inspect mysql | grep -A 10 -B 5 "State"

echo ""
echo "=== Checking MySQL Compose File ==="
if [[ -f "docker_services/mysql/docker-compose.yml" ]]; then
    cat docker_services/mysql/docker-compose.yml
else
    echo "MySQL compose file not found!"
fi

# MySQL Connectivity Check Script
# This script checks MySQL connectivity and configuration

echo "🗄️ Checking MySQL connectivity..."

# Check if MySQL service directory exists
if [[ -f "docker_services/mysql/docker-compose.yml" ]]; then
    echo "✅ MySQL service configuration found"
    echo "📋 MySQL Docker Compose configuration:"
    cat docker_services/mysql/docker-compose.yml
else
    echo "❌ MySQL service configuration not found"
    exit 1
fi

# Check if MySQL container is running
if docker ps --format "table {{.Names}}" | grep -q "mysql"; then
    echo "✅ MySQL container is running"
else
    echo "⚠️ MySQL container is not running"
fi

# Check MySQL port
if netstat -tuln | grep -q ":3306"; then
    echo "✅ MySQL port 3306 is listening"
else
    echo "⚠️ MySQL port 3306 is not listening"
fi

echo "✅ MySQL connectivity check completed" 