# ServerAssistant Startup Guide

This guide explains how to use the startup scripts to automatically set up and launch ServerAssistant.

## Quick Start

### Linux/macOS
```bash
# First time setup (creates virtual environment, installs dependencies)
./setup.sh

# Normal startup (after first-time setup)
./start.sh
```

### Windows
```cmd
# First time setup (creates virtual environment, installs dependencies)
setup.bat

# Normal startup (after first-time setup)
start.bat
```

### Alternative Startup Methods
```bash
# Direct Python launch
python serverassistant.py
# OR
python src/main.py

# CLI mode
python src/main.py --cli status
python src/main.py --cli start web-app
```

## What the Startup Scripts Do

### Setup Scripts (`setup.sh` / `setup.bat`)
The setup scripts automatically handle first-time environment preparation:

- ✅ Check Python installation (3.7+ required)
- ✅ **Create Python virtual environment** (handles externally managed environments)
- ✅ Check Docker installation
- ✅ Check Docker Compose installation
- ✅ Verify Docker daemon is running
- ✅ Install Python dependencies in virtual environment from `requirements.txt`
- ✅ Install system dependencies
- ✅ Fix line endings and permissions
- ✅ Setup persistent storage for GitLab and Mail Server
- ✅ Setup Nginx reverse proxy
- ✅ Generate SSL certificates
- ✅ Mark setup as complete

### Startup Scripts (`start.sh` / `start.bat`)
The startup scripts handle normal application launch:

- ✅ Skip installation steps (if setup is complete)
- ✅ Activate virtual environment
- ✅ Launch ServerAssistant directly

## Virtual Environment Management

The setup scripts automatically handle Python virtual environments to avoid conflicts with system Python packages:

### Automatic Virtual Environment Creation
- Creates `venv/` directory in project folder
- Installs `python3-venv` package if needed (Linux)
- Installs all Python dependencies in isolated environment
- Uses virtual environment Python for all operations

### Virtual Environment Benefits
- ✅ Avoids "externally-managed-environment" errors
- ✅ Prevents conflicts with system Python packages
- ✅ Isolated dependency management
- ✅ Consistent environment across different systems

## Prerequisites

Before running the startup scripts, ensure you have:

### Required Software
- **Python 3.7+** - [Download Python](https://www.python.org/downloads/)
- **Docker** - [Download Docker](https://www.docker.com/products/docker-desktop)
- **Docker Compose** - Usually included with Docker Desktop

### System Requirements
- **Linux**: Ubuntu 18.04+, CentOS 7+, or similar
- **Windows**: Windows 10/11 with WSL2 support
- **macOS**: macOS 10.15+ (Catalina or later)

## Startup Script Options

### 1. Setup Scripts (First-Time Setup)
- **`setup.sh`** - Linux/macOS setup script with virtual environment support
- **`setup.bat`** - Windows setup script with virtual environment support

### 2. Startup Scripts (Normal Launch)
- **`start.sh`** - Linux/macOS startup script (simple launch)
- **`start.bat`** - Windows startup script (simple launch)

### 3. Direct Python Launch
- **`serverassistant.py`** - Direct Python entry point
- **`src/main.py`** - Core application entry point

## First-Time Setup Process

When you run the setup script for the first time:

1. **Prerequisites Check**
   - Verifies Python, Docker, and Docker Compose are installed
   - Ensures Docker daemon is running

2. **Virtual Environment Setup**
   - Creates Python virtual environment in `venv/` directory
   - Installs `python3-venv` package if needed (Linux)
   - Activates virtual environment for all operations

3. **Dependencies Installation**
   - Installs Python packages in virtual environment from `requirements.txt`
   - Runs system-specific dependency installation

4. **Environment Setup**
   - Fixes line endings (Windows ↔ Linux compatibility)
   - Sets proper file permissions
   - Makes scripts executable

5. **Service Setup**
   - Creates persistent storage directories
   - Sets up Nginx reverse proxy
   - Generates SSL certificates

6. **Completion**
   - Creates `.first_time_setup_complete` marker file
   - Launches ServerAssistant using virtual environment Python

## Normal Startup Process

After first-time setup, use the startup scripts for quick launch:

1. **Check Setup Status**
   - Verifies first-time setup is complete
   - Activates virtual environment

2. **Launch Application**
   - Starts ServerAssistant directly
   - No environment setup required

## Troubleshooting

### Common Issues

#### Externally Managed Environment Error
```bash
# This is now handled automatically by virtual environments
# The setup scripts create isolated environments to avoid this error
```

#### Python Not Found
```bash
# Install Python 3.7+
sudo apt update && sudo apt install python3 python3-pip python3-venv  # Ubuntu/Debian
brew install python3  # macOS
```

#### Docker Not Found
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh  # Linux
# Download Docker Desktop for Windows/macOS
```

#### Permission Denied
```bash
# Fix permissions
chmod +x *.sh *.py
```

#### Docker Daemon Not Running
```bash
# Start Docker
sudo systemctl start docker  # Linux
# Start Docker Desktop on Windows/macOS
```

#### Virtual Environment Issues
```bash
# Remove and recreate virtual environment
rm -rf venv/
./setup.sh  # This will recreate the virtual environment
```

### Reset First-Time Setup

To force re-run the first-time setup:

```bash
# Remove the completion marker and virtual environment
rm .first_time_setup_complete
rm -rf venv/

# Run setup script again
./setup.sh  # or setup.bat
```

### Manual Setup

If automatic setup fails, you can run steps manually:

1. **Create Virtual Environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/macOS
   # OR
   venv\Scripts\activate.bat  # Windows
   ```

2. **Install Dependencies**
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. **Fix Environment**
   ```bash
   chmod +x scripts/maintenance/fix_line_endings.sh scripts/maintenance/fix_permissions.sh
   ./scripts/maintenance/fix_line_endings.sh
   ./scripts/maintenance/fix_permissions.sh
   ```

4. **Setup Services**
   ```bash
   cd docker_services/gitlab && ./setup_persistent_storage.sh
   cd ../mail-server && ./setup_persistent_storage.sh
   cd ../nginx && ./setup_nginx.sh && ./generate_ssl.sh
   ```

5. **Launch ServerAssistant**
   ```bash
   python serverassistant.py
   ```

## Configuration Files

The startup scripts work with these configuration files:

- **`config.json`** - Main configuration
- **`test_config_ubuntu22.json`** - Test configuration
- **`requirements.txt`** - Python dependencies (installed in virtual environment)

## Virtual Environment Details

### Directory Structure
```
serverasistant/
├── venv/                    # Virtual environment directory
│   ├── bin/                 # Linux/macOS executables
│   │   ├── python          # Virtual environment Python
│   │   ├── pip             # Virtual environment pip
│   │   └── activate        # Activation script
│   └── Scripts/            # Windows executables
│       ├── python.exe      # Virtual environment Python
│       ├── pip.exe         # Virtual environment pip
│       └── activate.bat    # Activation script
├── serverassistant.py      # Main application
├── requirements.txt        # Python dependencies
├── setup.sh               # Setup script
└── start.sh               # Startup script
```

### Virtual Environment Benefits
- **Isolation**: Dependencies don't conflict with system packages
- **Reproducibility**: Same environment across different systems
- **Cleanup**: Easy to remove by deleting `venv/` directory
- **Security**: No system-wide package modifications

## Logs and Debugging

### Enable Verbose Output
```bash
# Linux/macOS
bash -x setup.sh
bash -x start.sh

# Windows
cmd /c setup.bat
cmd /c start.bat
```

### Check Setup Status
```bash
# Check if setup is complete
ls -la .first_time_setup_complete

# Check virtual environment
ls -la venv/

# View setup log
cat .first_time_setup_complete
```

### Virtual Environment Verification
```bash
# Check if virtual environment is working
source venv/bin/activate
python --version
pip list
```

## Next Steps

After successful startup:

1. **Access ServerAssistant** - Use the terminal interface
2. **Configure Services** - Edit `config.json` as needed
3. **Start Services** - Use ServerAssistant menu options
4. **Test Services** - Run validation tests
5. **Monitor** - Use monitoring features

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Check system logs for errors
4. Try resetting first-time setup
5. Run manual setup steps
6. Check virtual environment status

## Security Notes

- The setup scripts create persistent storage with appropriate permissions
- SSL certificates are generated for local development
- For production, replace self-signed certificates with proper ones
- Review and customize configurations before deployment
- Virtual environments provide isolation from system packages 