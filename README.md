# ServerAssistant

A comprehensive Python application for managing and running Docker services based on JSON configuration. This tool allows you to easily deploy, monitor, and manage Docker containers and Docker Compose services across different servers.

![Capture](https://github.com/user-attachments/assets/0fe44735-09fb-4ca4-bc74-28b9688cbd62)

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

in server if change happened in code: git reset --hard HEAD~1

chmod +x setup.sh
chmod +x scripts/startup/setup.sh
chmod +x scripts/startup/*.sh
chmod +x scripts/linux/*.sh
chmod +x scripts/maintenance/*.sh
chmod +x scripts/setup/*.sh


# First time setup (creates virtual environment, installs dependencies)
./setup.sh

# Normal startup (after first-time setup)
./start.sh
```

#### Windows Server
```powershell
# Clone the repository
git clone <repository-url>
cd serverasistant

# First time setup (creates virtual environment, installs dependencies)
.\setup.bat

# Normal startup (after first-time setup)
.\start.bat
```

### 🎨 Beautiful GUI Interface

ServerAssistant now includes a beautiful terminal-based GUI built with [Textual](https://textual.textualize.io/)!

#### Launch the GUI

```bash
# Install textual (if not already installed)
pip install textual>=0.52.0

# Launch GUI
python gui_main.py

# Or use the convenience scripts
./scripts/startup/launch_gui.sh    # Linux/macOS
scripts\startup\launch_gui.bat     # Windows
```

#### GUI Features
- 📊 **Dashboard**: Visual overview of all services with status indicators
- 🔧 **Service Management**: One-click start, stop, restart services
- 📋 **Logs Viewer**: Real-time log viewing with syntax highlighting
- ⚙️ **Settings**: Configuration overview and Docker environment status
- ⌨️ **Keyboard Shortcuts**: Quick navigation (1-4 for tabs, r for refresh, q to quit)
- 📱 **Responsive Design**: Adapts to different terminal sizes

For detailed GUI documentation, see [GUI README](docs/GUI_README.md).

#### Test the GUI Setup
```bash
python tests/test_gui.py
```

### Alternative Startup Methods

#### Direct Python Launch
```bash
# Launch directly with Python
python serverassistant.py
# OR
python src/main.py
```

#### CLI Mode
```bash
# Show service status
python src/main.py --cli status

# Start a specific service
python src/main.py --cli start web-app

# Start all services
python src/main.py --cli start-all

# Stop all services
python src/main.py --cli stop-all
```

## 📚 Documentation

For comprehensive documentation, guides, and tutorials, please visit our **[Documentation Hub](docs/index.md)** which includes:

- **[User Guides](docs/guides/)** - Usage guides and tutorials
- **[Setup Guides](docs/setup/)** - Installation and configuration guides  
- **[Development Docs](docs/development/)** - Development setup and guidelines
- **[Deployment Guides](docs/deployment/)** - Production deployment guides
- **[GUI Documentation](docs/GUI_README.md)** - Beautiful terminal GUI guide

### Quick Documentation Links
- **[Usage Guide](docs/guides/usage-guide.md)** - How to use ServerAssistant effectively
- **[Startup Guide](docs/setup/startup-guide.md)** - Complete startup and initialization
- **[Development Guide](docs/development/development-guide.md)** - Development setup and guidelines
- **[GUI Guide](docs/GUI_README.md)** - Beautiful terminal interface guide

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
- **🎨 Beautiful GUI**: Modern terminal-based interface with Textual
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
├── src/                    # 🐍 Source code (organized structure)
│   ├── core/              # Core application logic
│   │   ├── server_assistant.py
│   │   ├── config_manager.py
│   │   └── docker_manager.py
│   ├── ui/                # User interface components
│   │   ├── display_utils.py
│   │   └── menu_system.py
│   └── utils/             # Utility functions
│       ├── file_utils.py
│       ├── system_utils.py
│       └── validation_utils.py
├── scripts/               # 🔧 Utility scripts
│   ├── startup/          # Startup and setup scripts
│   ├── setup/            # Installation and setup scripts
│   ├── maintenance/      # Maintenance and cleanup scripts
│   ├── testing/          # Testing and validation scripts
│   ├── backup/           # Backup scripts
│   ├── windows/          # Windows-specific scripts
│   └── linux/            # Linux-specific scripts
├── docker_services/       # 📦 Docker service definitions
│   ├── nginx/            # Nginx reverse proxy setup
│   ├── mysql/            # MySQL database service
│   ├── gitlab/           # GitLab development platform
│   ├── mail-server/      # Complete email stack
│   ├── portainer/        # Portainer container management
│   └── web-app/          # Web application template
├── tests/                # 🧪 Test suite
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   ├── e2e/              # End-to-end tests
│   └── scripts/          # Test scripts
├── setup.sh              # 🔧 First-time setup script (Linux)
├── setup.bat             # 🔧 First-time setup script (Windows)
├── start.sh              # 🚀 Simple startup script (Linux)
├── start.bat             # 🚀 Simple startup script (Windows)
├── serverassistant.py    # 🐍 Direct Python entry point
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
