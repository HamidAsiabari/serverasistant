# Using ServerAssistant (Organized Version)

## Quick Start

The ServerAssistant has been reorganized into a modular structure for better development and debugging. Here's how to use it:

### Option 1: Use the Organized Structure (Recommended)

```bash
# Run the organized version directly
python src/main.py

# Or use the simple runner script
python run_organized.py

# Or use the updated startup script
./start.sh  # Linux/Mac
start.bat   # Windows
```

### Option 2: Use the Refactored Legacy File

```bash
# The old serverassistant.py has been refactored to use the organized structure
python serverassistant.py
```

### Option 3: Use CLI Mode

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
The startup scripts will automatically install these dependencies:

```bash
# Linux/Mac
./start.sh

# Windows
start.bat
```

## Configuration

Your existing `config.json` file works without any changes. The new structure provides better validation and error handling.

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

# Or use the startup script which installs them automatically
./start.sh
```

### Fallback to Old Structure
If you encounter issues with the organized structure, you can still use the refactored `serverassistant.py`:

```bash
python serverassistant.py
```

## Migration

### Automatic Migration
```bash
# Run the migration script
python migrate.py
```

### Manual Migration
1. Use the new startup scripts: `./start.sh` or `start.bat`
2. Or run directly: `python src/main.py`
3. Your existing configuration will work without changes

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

## Support

- **Documentation**: See `README_REORGANIZED.md` for detailed information
- **Development Guide**: See `DEVELOPMENT_GUIDE.md` for development guidelines
- **Migration Report**: See `MIGRATION_REPORT.md` for migration details

The organized structure provides a solid foundation for future development while maintaining all existing functionality and improving the overall user experience. 