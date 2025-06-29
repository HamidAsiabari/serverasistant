# Using ServerAssistant (Organized Version)

## Quick Start

The ServerAssistant has been reorganized into a modular structure for better development and debugging. Here's how to use it:

### Option 1: First-Time Setup (Recommended for New Users)

```bash
# First time setup (creates virtual environment, installs dependencies)
./setup.sh    # Linux/Mac
setup.bat     # Windows

# Normal startup (after first-time setup)
./start.sh    # Linux/Mac
start.bat     # Windows
```

### Option 2: Direct Python Launch

```bash
# Run the organized version directly
python src/main.py

# Or use the refactored entry point
python serverassistant.py
```

### Option 3: CLI Mode

```bash
# Show service status
python src/main.py --cli status

# Start a specific service
python src/main.py --cli start web-app

# Start all services
python src/main.py --cli start-all

# Stop all services
python src/main.py --cli stop-all

# View service logs
python src/main.py --cli logs web-app
```

## What Changed

### Before (Old Structure)
- Everything was in one large file (`serverassistant.py` - 1102 lines)
- Hard to find specific functionality
- Difficult to debug and maintain
- Mixed concerns (UI, business logic, utilities)

### After (Organized Structure)
- **`src/core/`** - Core business logic
  - `server_assistant.py` - Main orchestrator
  - `config_manager.py` - Configuration management
  - `docker_manager.py` - Docker operations
- **`src/ui/`** - User interface
  - `display_utils.py` - Display formatting
  - `menu_system.py` - Menu system
- **`src/utils/`** - Utilities
  - `file_utils.py` - File operations
  - `system_utils.py` - System operations
  - `validation_utils.py` - Data validation

## Benefits

### For Users
- **Better error messages** - More informative and helpful
- **Consistent UI** - Unified display formatting
- **More reliable** - Better validation and error handling
- **Easier to use** - Improved menu system
- **Clear startup options** - Setup vs Start scripts

### For Developers
- **Easier to debug** - Focused modules make issues easier to find
- **Easier to test** - Individual components can be tested
- **Easier to extend** - Add new features without affecting existing code
- **Better IDE support** - Type hints and clear imports

## Installation

### Dependencies
The organized structure requires additional dependencies:

```bash
pip install tabulate psutil colorama
```

### First Time Setup
The setup scripts will automatically install these dependencies:

```bash
# Linux/Mac
./setup.sh

# Windows
setup.bat
```

## Configuration

Your existing `config.json` file works without any changes. The new structure provides better validation and error handling.

## Startup Scripts Overview

### Setup Scripts (`setup.sh` / `setup.bat`)
- **Purpose**: First-time environment setup
- **What they do**: Create virtual environment, install dependencies, setup services
- **When to use**: First time installation or when resetting environment

### Startup Scripts (`start.sh` / `start.bat`)
- **Purpose**: Normal application launch
- **What they do**: Activate virtual environment, launch application
- **When to use**: Daily usage after initial setup

### Direct Python Launch
- **Purpose**: Direct application access
- **What they do**: Launch application directly
- **When to use**: Development, testing, or when you want direct control

## Troubleshooting

### Import Errors
If you see import errors, make sure:
1. You're running from the project root directory
2. The `src/` directory exists
3. Dependencies are installed: `pip install tabulate psutil colorama`

### Missing Dependencies
```bash
# Install required dependencies
pip install tabulate psutil colorama

# Or use the setup script which installs them automatically
./setup.sh
```

### Virtual Environment Issues
```bash
# Remove and recreate virtual environment
rm -rf venv/
./setup.sh  # This will recreate the virtual environment
```

### Fallback to Direct Launch
If you encounter issues with the startup scripts, you can always use direct Python launch:

```bash
python serverassistant.py
# OR
python src/main.py
```

## Migration

### Automatic Migration
The setup scripts handle migration automatically:
```bash
# Run the setup script
./setup.sh  # or setup.bat
```

### Manual Migration
1. Use the new startup scripts: `./setup.sh` or `setup.bat` for first-time setup
2. Use `./start.sh` or `start.bat` for normal startup
3. Or run directly: `python src/main.py`
4. Your existing configuration will work without changes

## Development

### Adding New Features
1. Add core logic to `src/core/`
2. Add UI components to `src/ui/`
3. Add utilities to `src/utils/`
4. Update `src/main.py` if needed

### Testing
```python
# Test individual components
from src.core.config_manager import ConfigManager
from src.core.docker_manager import DockerManager
from src.ui.display_utils import DisplayUtils
```

### Project Structure
```
serverasistant/
├── src/                    # Source code
│   ├── core/              # Core business logic
│   ├── ui/                # User interface
│   └── utils/             # Utilities
├── scripts/               # Utility scripts
│   ├── startup/          # Startup scripts
│   ├── setup/            # Setup scripts
│   ├── maintenance/      # Maintenance scripts
│   └── testing/          # Testing scripts
├── docker_services/       # Docker service definitions
├── setup.sh              # First-time setup (Linux)
├── setup.bat             # First-time setup (Windows)
├── start.sh              # Normal startup (Linux)
├── start.bat             # Normal startup (Windows)
└── serverassistant.py    # Direct Python entry point
```

## Support

- **Documentation**: See `docs/index.md` for comprehensive documentation
- **Development Guide**: See `docs/development/development-guide.md` for development guidelines
- **Startup Guide**: See `docs/setup/startup-guide.md` for startup instructions

The organized structure provides a solid foundation for future development while maintaining all existing functionality and improving the overall user experience. 