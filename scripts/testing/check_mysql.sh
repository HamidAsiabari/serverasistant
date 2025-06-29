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
if [[ -f "example_services/mysql/docker-compose.yml" ]]; then
    cat example_services/mysql/docker-compose.yml
else
    echo "MySQL compose file not found!"
fi 