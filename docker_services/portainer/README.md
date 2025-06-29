# Portainer - Docker Management UI

Portainer is a lightweight Docker management UI that allows you to easily manage your Docker containers, images, volumes, networks, and more through a web interface.

## Features

- 🐳 **Container Management**: Start, stop, restart, and manage containers
- 📦 **Image Management**: Pull, build, and manage Docker images
- 🌐 **Network Management**: Create and manage Docker networks
- 💾 **Volume Management**: Manage Docker volumes
- 📊 **Resource Monitoring**: Monitor container resource usage
- 🔧 **Stack Management**: Deploy and manage Docker Compose stacks
- 👥 **User Management**: Multi-user support with role-based access
- 🔒 **Security**: Secure access with authentication

## Quick Start

### 1. Start Portainer
```bash
# Using Docker Service Manager
python3 main.py start portainer --config config.json

# Or manually with Docker Compose
cd example_services/portainer
docker-compose up -d
```

### 2. Access Portainer
- **URL**: http://your-server-ip:9000
- **First Time Setup**: Create an admin user when you first access Portainer

### 3. Connect to Docker Host
- Portainer will automatically detect the local Docker host
- No additional configuration needed

## Configuration

### Port
- **Default**: 9000
- **Change**: Modify the `ports` section in `docker-compose.yml`

### Data Persistence
- Portainer data is stored in a Docker volume: `portainer_data`
- This ensures your settings persist across container restarts

### Security
- Uses `no-new-privileges` security option
- Read-only access to Docker socket
- Timezone synchronization

## Usage

### Initial Setup
1. Open http://your-server-ip:9000 in your browser
2. Create an admin user account
3. Choose "Local Docker Environment"
4. Start managing your Docker containers!

### Key Features
- **Dashboard**: Overview of all containers and resources
- **Containers**: Detailed container management
- **Images**: Docker image management
- **Volumes**: Volume management
- **Networks**: Network configuration
- **Stacks**: Docker Compose stack management

### Container Management
- View running/stopped containers
- Start, stop, restart containers
- View container logs
- Access container console
- Monitor resource usage

### Stack Management
- Deploy Docker Compose files
- Manage multi-container applications
- Update and rollback stacks

## Security Considerations

1. **Access Control**: Set up proper authentication
2. **Network Security**: Consider using HTTPS in production
3. **Firewall**: Ensure port 9000 is accessible
4. **Backup**: Regularly backup the portainer_data volume

## Troubleshooting

### Portainer Won't Start
```bash
# Check container logs
docker logs portainer

# Check if port 9000 is available
netstat -tlnp | grep 9000
```

### Can't Access Web UI
```bash
# Check if container is running
docker ps | grep portainer

# Check port mapping
docker port portainer
```

### Reset Portainer
```bash
# Stop and remove container
docker stop portainer
docker rm portainer

# Remove data volume (WARNING: This will delete all Portainer data)
docker volume rm portainer_data

# Restart
docker-compose up -d
```

## Integration with Docker Service Manager

Portainer integrates seamlessly with the Docker Service Manager:

```bash
# Start Portainer
python3 main.py start portainer --config config.json

# Check status
python3 main.py status --config config.json

# Stop Portainer
python3 main.py stop portainer --config config.json
```

## Next Steps

1. **Secure Access**: Set up HTTPS with reverse proxy
2. **Backup Strategy**: Configure regular backups
3. **Monitoring**: Set up alerts and monitoring
4. **User Management**: Add additional users with appropriate roles

## Resources

- [Portainer Documentation](https://docs.portainer.io/)
- [Portainer Community Edition](https://www.portainer.io/community-edition)
- [Docker Documentation](https://docs.docker.com/) 