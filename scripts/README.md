# Scripts Directory

This directory contains all shell scripts, batch files, and PowerShell scripts for ServerAssistant, organized by category.

## Directory Structure

```
scripts/
├── startup/           # Startup and initialization scripts
├── maintenance/       # Maintenance and utility scripts
├── testing/          # Testing and validation scripts
├── backup/           # Backup and restore scripts
├── setup/            # Setup and installation scripts
├── windows/          # Windows-specific scripts
└── linux/            # Linux-specific scripts
```

## Categories

### Startup Scripts (`startup/`)
- Main startup scripts for different platforms
- Environment initialization
- Application launching

### Maintenance Scripts (`maintenance/`)
- System maintenance tasks
- Cleanup operations
- Health checks

### Testing Scripts (`testing/`)
- Test execution scripts
- Validation scripts
- Performance testing

### Backup Scripts (`backup/`)
- Backup creation and management
- Restore operations
- Backup scheduling

### Setup Scripts (`setup/`)
- Initial setup and installation
- Dependency installation
- Configuration setup

### Windows Scripts (`windows/`)
- Windows-specific batch files
- PowerShell scripts
- Windows automation

### Linux Scripts (`linux/`)
- Linux-specific shell scripts
- System administration
- Linux automation

## Usage

### Running Scripts
```bash
# From project root
./scripts/startup/start.sh

# Or navigate to scripts directory
cd scripts/startup
./start.sh
```

### Making Scripts Executable
```bash
# Make all scripts executable
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Make specific script executable
chmod +x scripts/startup/start.sh
```

## Script Naming Convention

- **Startup scripts**: `start.sh`, `start.bat`, `launch.sh`
- **Maintenance scripts**: `maintenance_*.sh`, `cleanup_*.sh`
- **Testing scripts**: `test_*.sh`, `validate_*.sh`
- **Backup scripts**: `backup_*.sh`, `restore_*.sh`
- **Setup scripts**: `setup_*.sh`, `install_*.sh`

## Platform-Specific Scripts

### Windows
- Use `.bat` or `.ps1` extensions
- Located in `windows/` subdirectory
- Use Windows-specific commands and paths

### Linux/Mac
- Use `.sh` extensions
- Located in `linux/` subdirectory
- Use Unix/Linux commands and paths

## Common Scripts

### Startup
- `start.sh` - Main Linux startup script
- `start.bat` - Main Windows startup script
- `quick_start.sh` - Quick start for organized version

### Maintenance
- `fix_permissions.sh` - Fix file permissions
- `fix_line_endings.sh` - Fix line endings
- `cleanup.sh` - Cleanup temporary files

### Testing
- `test_services.sh` - Test all services
- `test_installation.sh` - Test installation
- `quick_test.sh` - Quick system test

### Backup
- `backup_system.sh` - Full system backup
- `backup_system.bat` - Windows backup script

### Setup
- `setup_ubuntu.sh` - Ubuntu setup
- `install_requirements.sh` - Install dependencies
- `setup_nginx.sh` - Nginx setup

## Best Practices

1. **Always check prerequisites** before running scripts
2. **Use absolute paths** when possible
3. **Include error handling** in all scripts
4. **Add comments** explaining what each script does
5. **Test scripts** on target platforms
6. **Use consistent naming** conventions
7. **Include help/usage** information in scripts

## Troubleshooting

### Permission Denied
```bash
chmod +x scripts/startup/start.sh
```

### Script Not Found
```bash
# Check if script exists
ls -la scripts/startup/

# Check script path
which scripts/startup/start.sh
```

### Platform Issues
- Ensure you're using the correct script for your platform
- Check that required tools are installed
- Verify file paths are correct for your OS 