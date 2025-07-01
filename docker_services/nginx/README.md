# Simple Nginx Reverse Proxy

A minimal nginx reverse proxy configuration for `docker.soject.com` → port 9000.

## Quick Start

### 1. Setup Domain
```bash
chmod +x setup_docker_domain.sh
./setup_docker_domain.sh
```

### 2. Start Nginx
```bash
docker-compose up -d
```

### 3. Test
```bash
chmod +x test.sh
./test.sh
```

## Configuration

- **Domain**: `docker.soject.com`
- **Target**: `localhost:9000` (Portainer)
- **Port**: 80

## Files

- `docker-compose.yml` - Service definition
- `nginx.conf` - Main nginx configuration
- `conf.d/docker.soject.com.conf` - Domain configuration
- `setup_docker_domain.sh` - Domain setup script
- `test.sh` - Test script

## Test

```bash
curl http://docker.soject.com
```

This should show the Portainer interface if it's running on port 9000. 