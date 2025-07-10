# Nginx Reverse Proxy with Domain Routing

A comprehensive nginx reverse proxy configuration that routes multiple domains to their corresponding services.

## Domain Mappings

| Domain | Service | Description | Container |
|--------|---------|-------------|-----------|
| `app.soject.com` | Web Application | Main Flask web application | `web-app:8080` |
| `docker.soject.com` | Portainer | Docker container management | `portainer:9000` |
| `gitlab.soject.com` | GitLab | Git repository and CI/CD | `gitlab:80` |
| `admin.soject.com` | phpMyAdmin | MySQL database management | `phpmyadmin:80` |
| `mail.soject.com` | Roundcube | Webmail interface | `roundcube:80` |

## Quick Start

### 1. Setup All Domains
```bash
chmod +x setup_all_domains.sh
./setup_all_domains.sh
```

### 2. Fix Network Issues (if needed)
```bash
chmod +x fix_network_issue.sh
./fix_network_issue.sh
```

### 3. Test All Domains
```bash
chmod +x test_all_domains.sh
./test_all_domains.sh
```

### 4. Start Nginx
```bash
docker-compose up -d
```

## Configuration Files

- `docker-compose.yml` - Service definition
- `nginx.conf` - Main nginx configuration
- `conf.d/` - Domain-specific configurations:
  - `app.soject.com.conf` - Web application
  - `docker.soject.com.conf` - Portainer
  - `gitlab.soject.com.conf` - GitLab
  - `admin.soject.com.conf` - phpMyAdmin
  - `mail.soject.com.conf` - Roundcube

## Network Requirements

All services must be connected to the `web_network` for nginx to reach them:

```yaml
networks:
  web_network:
    external: true
    name: web_network
```

## Features

- **Domain-based routing** - Each domain routes to its specific service
- **WebSocket support** - For real-time applications like Portainer
- **Large file uploads** - Optimized for GitLab (500MB limit)
- **Health checks** - Dedicated health check endpoints
- **Security headers** - Proper proxy headers for security
- **SSL ready** - Configuration supports HTTPS (certificates needed)

## Troubleshooting

### Domain shows wrong service
1. Check if the service is running: `docker ps`
2. Verify nginx configuration: `docker-compose exec nginx nginx -t`
3. Check nginx logs: `docker-compose logs nginx`
4. Ensure service is connected to web_network: `docker network inspect web_network`

### Service not accessible
1. Run the network fix script: `./fix_network_issue.sh`
2. Restart the specific service
3. Check if the service is listening on the correct port
4. Verify network connectivity: `docker network ls`

### Nginx won't start
1. Check if web_network exists: `docker network ls | grep web_network`
2. Create network if missing: `docker network create web_network`
3. Check nginx configuration: `docker-compose config`
4. View nginx logs: `docker-compose logs nginx`

## Testing

Test each domain:
```bash
curl http://app.soject.com
curl http://docker.soject.com
curl http://gitlab.soject.com
curl http://admin.soject.com
curl http://mail.soject.com
```

## Maintenance

### Restart nginx
```bash
docker-compose restart nginx
```

### Reload configuration
```bash
docker-compose exec nginx nginx -s reload
```

### View logs
```bash
docker-compose logs nginx
```

### Update configuration
After modifying any `.conf` files, reload nginx:
```bash
docker-compose exec nginx nginx -s reload
``` 