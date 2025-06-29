# GitLab Docker Compose Service

This directory contains a production-ready Docker Compose setup for GitLab Community Edition (CE), including PostgreSQL and Redis for data and cache.

## Features
- 🐙 GitLab CE (latest)
- 🐘 PostgreSQL 15 (database)
- 🔴 Redis 7 (cache)
- Persistent storage for all data, logs, and configuration
- Health checks for all services
- Exposes HTTP (8081), HTTPS (443), and SSH (2224)

## Quick Start

### 1. Start GitLab
```bash
cd example_services/gitlab
docker-compose up -d
```

### 2. Access GitLab
- **Web UI**: http://your-server-ip:8081
- **SSH**: ssh -p 2224 git@your-server-ip

### 3. First Time Login
- The initial root password is printed in the container logs:
  ```bash
  docker logs gitlab 2>&1 | grep 'Password:'
  ```
- Or set your own by editing `/etc/gitlab/gitlab.rb` and running `gitlab-ctl reconfigure` inside the container.

## Data Persistence
- All data, configuration, and logs are stored in Docker volumes:
  - `gitlab_config` → `/etc/gitlab`
  - `gitlab_logs` → `/var/log/gitlab`
  - `gitlab_data` → `/var/opt/gitlab`
  - `gitlab_redis_data` → Redis data
  - `gitlab_postgres_data` → PostgreSQL data

## Ports
- **8081**: GitLab Web UI (HTTP)
- **443**: GitLab Web UI (HTTPS, optional)
- **2224**: GitLab SSH

## Stopping and Removing
```bash
docker-compose down
# To remove all data (CAUTION: this deletes everything!)
docker volume rm gitlab_config gitlab_logs gitlab_data gitlab_redis_data gitlab_postgres_data
```

## Troubleshooting
- **Check logs**: `docker logs gitlab`
- **Check health**: `docker inspect --format='{{json .State.Health}}' gitlab`
- **Reset root password**: [GitLab Docs](https://docs.gitlab.com/ee/security/reset_root_password.html)
- **Upgrade**: Update the image tag in `docker-compose.yml` and run `docker-compose up -d`

## Integration with Docker Service Manager

Add this service to your config:
```json
{
  "name": "gitlab",
  "type": "docker-compose",
  "enabled": true,
  "path": "./example_services/gitlab",
  "compose_file": "docker-compose.yml",
  "services": ["gitlab"],
  "restart_policy": "unless-stopped",
  "health_check": {
    "url": "http://localhost:8081/help",
    "interval": 60,
    "timeout": 30,
    "retries": 5
  }
}
```

## Resources
- [GitLab Docker Docs](https://docs.gitlab.com/ee/install/docker.html)
- [GitLab CE](https://about.gitlab.com/install/) 