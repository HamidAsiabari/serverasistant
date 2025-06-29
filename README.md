# ServerAssistant

A comprehensive Python application for managing and running Docker services based on JSON configuration. This tool allows you to easily deploy, monitor, and manage Docker containers and Docker Compose services across different servers.

## 🚀 Quick Start

### Prerequisites
- Python 3.7 or higher
- Docker and Docker Compose installed
- Docker daemon running

### Installation

#### Linux Ubuntu
```bash
# Clone the repository
git clone <repository-url>
cd serverasistant

# Run installation script
chmod +x scripts/setup/install_dependencies.sh
./scripts/setup/install_dependencies.sh

# Start the application
./start.sh
```

#### Windows Server
```powershell
# Clone the repository
git clone <repository-url>
cd serverasistant

# Run installation script (as Administrator)
.\scripts\setup\install_requirements.ps1

# Start the application
.\start.bat
```

## 📚 Documentation

For comprehensive documentation, guides, and tutorials, please visit our **[Documentation Hub](docs/index.md)** which includes:

- **[User Guides](docs/guides/)** - Usage guides and tutorials
- **[Setup Guides](docs/setup/)** - Installation and configuration guides  
- **[Development Docs](docs/development/)** - Development setup and guidelines
- **[Deployment Guides](docs/deployment/)** - Production deployment guides

### Quick Documentation Links
- **[Usage Guide](docs/guides/usage-guide.md)** - How to use ServerAssistant effectively
- **[Startup Guide](docs/setup/startup-guide.md)** - Complete startup and initialization
- **[Development Guide](docs/development/development-guide.md)** - Development setup and guidelines

## 🎯 Key Features

- **JSON Configuration**: Define services in a simple JSON configuration file
- **Docker Support**: Run individual Docker containers from Dockerfiles
- **Docker Compose Support**: Manage multi-service applications with Docker Compose
- **Nginx Reverse Proxy**: Professional domain-based routing with SSL/TLS support
- **Health Monitoring**: Built-in health checks and monitoring
- **Cross-Server Compatibility**: Use the same configuration across different servers
- **Cross-Platform Support**: Works on Linux Ubuntu and Windows servers
- **Logging**: Comprehensive logging with configurable log levels
- **CLI Interface**: Easy-to-use command-line interface
- **Status Monitoring**: Real-time service status and resource usage
- **Notifications**: Email and webhook notifications for service issues
- **Automated Reports**: Daily status reports and log cleanup

## 🏗️ Project Structure

```
serverasistant/
├── docs/                    # 📚 Organized documentation
│   ├── guides/             # User guides and tutorials
│   ├── setup/              # Setup and installation guides
│   ├── development/        # Development documentation
│   └── deployment/         # Deployment and production guides
├── src/                    # 🐍 Source code
│   ├── core/              # Core application logic
│   ├── ui/                # User interface components
│   └── utils/             # Utility functions
├── scripts/               # 🔧 Utility scripts
│   ├── setup/            # Installation and setup scripts
│   ├── maintenance/      # Maintenance and cleanup scripts
│   └── testing/          # Testing and validation scripts
├── docker_services/       # 📦 Docker service definitions
│   ├── nginx/            # Nginx reverse proxy setup
│   ├── mysql/            # MySQL database service
│   ├── gitlab/           # GitLab development platform
│   └── mail-server/      # Complete email stack
├── tests/                # 🧪 Test suite
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   ├── e2e/              # End-to-end tests
│   └── scripts/          # Test scripts
└── config.json           # ⚙️ Main configuration file
```

## 🔧 Configuration

The application uses a JSON configuration file (`config.json`) to define services and settings. See the [Configuration Guide](docs/setup/startup-guide.md#configuration) for detailed information.

## 🆘 Support

If you need help:
1. Check the [Documentation Hub](docs/index.md) for comprehensive guides
2. Review the [Usage Guide](docs/guides/usage-guide.md) for common tasks
3. Consult the [Development Guide](docs/development/development-guide.md) for technical details

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Development Guide](docs/development/development-guide.md) for details on how to contribute to this project. 