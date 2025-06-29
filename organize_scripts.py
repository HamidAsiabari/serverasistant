#!/usr/bin/env python3
"""
Script to organize all shell and batch files into a proper directory structure
"""

import os
import shutil
from pathlib import Path

def create_directory_structure():
    """Create the scripts directory structure"""
    directories = [
        "scripts/startup",
        "scripts/maintenance", 
        "scripts/testing",
        "scripts/backup",
        "scripts/setup",
        "scripts/windows",
        "scripts/linux"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"Created directory: {directory}")

def categorize_scripts():
    """Categorize and move scripts to appropriate directories"""
    
    # Script categorization mapping
    script_categories = {
        # Startup scripts
        "start.sh": "scripts/startup/",
        "start.bat": "scripts/startup/",
        "start_organized.sh": "scripts/startup/",
        "quick_start_organized.sh": "scripts/startup/",
        "launch_serverassistant.sh": "scripts/startup/",
        "run.sh": "scripts/startup/",
        "run_serverassistant.sh": "scripts/startup/",
        "run_serverassistant.bat": "scripts/startup/",
        "activate_env.sh": "scripts/startup/",
        
        # Maintenance scripts
        "fix_permissions.sh": "scripts/maintenance/",
        "fix_line_endings.sh": "scripts/maintenance/",
        "fix_line_endings.bat": "scripts/maintenance/",
        "fix_line_endings.ps1": "scripts/maintenance/",
        "restart_services.sh": "scripts/maintenance/",
        
        # Testing scripts
        "quick_test.sh": "scripts/testing/",
        "quick_test_ubuntu22.sh": "scripts/testing/",
        "test_ubuntu22.sh": "scripts/testing/",
        "check_mysql.sh": "scripts/testing/",
        
        # Backup scripts
        "backup_system.sh": "scripts/backup/",
        "backup_system.bat": "scripts/backup/",
        
        # Setup scripts
        "setup_ubuntu.sh": "scripts/setup/",
        "setup.py": "scripts/setup/",
        "install_dependencies.sh": "scripts/setup/",
        "install_requirements.sh": "scripts/setup/",
        "install_requirements.ps1": "scripts/setup/",
        "prepare_for_linux.sh": "scripts/setup/",
        
        # Windows scripts
        "fix_line_endings.bat": "scripts/windows/",
        "fix_line_endings.ps1": "scripts/windows/",
        "install_requirements.ps1": "scripts/windows/",
        "backup_system.bat": "scripts/windows/",
        "run_serverassistant.bat": "scripts/windows/",
        
        # Linux scripts
        "setup_ubuntu.sh": "scripts/linux/",
        "install_dependencies.sh": "scripts/linux/",
        "install_requirements.sh": "scripts/linux/",
        "prepare_for_linux.sh": "scripts/linux/",
        "fix_permissions.sh": "scripts/linux/",
        "restart_services.sh": "scripts/linux/",
        "check_mysql.sh": "scripts/linux/",
        "add_to_hosts.sh": "scripts/linux/",
    }
    
    moved_count = 0
    skipped_count = 0
    
    for script_name, target_dir in script_categories.items():
        if os.path.exists(script_name):
            target_path = os.path.join(target_dir, script_name)
            
            # Handle duplicate names by adding platform suffix
            if os.path.exists(target_path):
                base_name = Path(script_name).stem
                extension = Path(script_name).suffix
                
                if "windows" in target_dir:
                    new_name = f"{base_name}_windows{extension}"
                elif "linux" in target_dir:
                    new_name = f"{base_name}_linux{extension}"
                else:
                    new_name = f"{base_name}_main{extension}"
                
                target_path = os.path.join(target_dir, new_name)
            
            try:
                shutil.move(script_name, target_path)
                print(f"Moved: {script_name} -> {target_path}")
                moved_count += 1
            except Exception as e:
                print(f"Error moving {script_name}: {e}")
                skipped_count += 1
        else:
            skipped_count += 1
    
    return moved_count, skipped_count

def create_symlinks():
    """Create symlinks for commonly used scripts in the root directory"""
    
    # Common scripts that should be easily accessible from root
    common_scripts = {
        "scripts/startup/start.sh": "start.sh",
        "scripts/startup/start.bat": "start.bat",
        "scripts/startup/quick_start_organized.sh": "quick_start.sh",
    }
    
    for source, link_name in common_scripts.items():
        if os.path.exists(source):
            try:
                # Create a simple wrapper script instead of symlink for cross-platform compatibility
                if link_name.endswith('.sh'):
                    wrapper_content = f"""#!/bin/bash
# Wrapper script for {source}
SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
cd "$SCRIPT_DIR"
exec "$SCRIPT_DIR/{source}" "$@"
"""
                    with open(link_name, 'w') as f:
                        f.write(wrapper_content)
                    os.chmod(link_name, 0o755)
                elif link_name.endswith('.bat'):
                    wrapper_content = f"""@echo off
REM Wrapper script for {source}
cd /d "%~dp0"
call "{source}" %*
"""
                    with open(link_name, 'w') as f:
                        f.write(wrapper_content)
                
                print(f"Created wrapper: {link_name} -> {source}")
            except Exception as e:
                print(f"Error creating wrapper {link_name}: {e}")

def update_script_paths():
    """Update script paths in moved files to work from new locations"""
    
    # Scripts that need path updates
    path_updates = {
        "scripts/startup/start.sh": {
            "old_paths": ["../..", "../../"],
            "new_paths": ["../..", "../../"]
        },
        "scripts/startup/start.bat": {
            "old_paths": ["..\\..", "..\\..\\"],
            "new_paths": ["..\\..", "..\\..\\"]
        }
    }
    
    for script_path, updates in path_updates.items():
        if os.path.exists(script_path):
            try:
                with open(script_path, 'r') as f:
                    content = f.read()
                
                # Update paths if needed
                modified = False
                for old_path, new_path in zip(updates["old_paths"], updates["new_paths"]):
                    if old_path in content:
                        content = content.replace(old_path, new_path)
                        modified = True
                
                if modified:
                    with open(script_path, 'w') as f:
                        f.write(content)
                    print(f"Updated paths in: {script_path}")
            except Exception as e:
                print(f"Error updating paths in {script_path}: {e}")

def create_script_index():
    """Create an index of all scripts for easy reference"""
    
    index_content = """# Scripts Index

This file provides an index of all available scripts organized by category.

## Startup Scripts
- `scripts/startup/start.sh` - Main Linux startup script
- `scripts/startup/start.bat` - Main Windows startup script
- `scripts/startup/quick_start_organized.sh` - Quick start for organized version
- `scripts/startup/launch_serverassistant.sh` - Launch ServerAssistant
- `scripts/startup/run.sh` - Simple run script
- `scripts/startup/run_serverassistant.sh` - Run ServerAssistant (Linux)
- `scripts/startup/run_serverassistant.bat` - Run ServerAssistant (Windows)
- `scripts/startup/activate_env.sh` - Activate virtual environment

## Maintenance Scripts
- `scripts/maintenance/fix_permissions.sh` - Fix file permissions
- `scripts/maintenance/fix_line_endings.sh` - Fix line endings (Linux)
- `scripts/maintenance/fix_line_endings.bat` - Fix line endings (Windows)
- `scripts/maintenance/fix_line_endings.ps1` - Fix line endings (PowerShell)
- `scripts/maintenance/restart_services.sh` - Restart all services

## Testing Scripts
- `scripts/testing/quick_test.sh` - Quick system test
- `scripts/testing/quick_test_ubuntu22.sh` - Ubuntu 22.04 quick test
- `scripts/testing/test_ubuntu22.sh` - Ubuntu 22.04 comprehensive test
- `scripts/testing/check_mysql.sh` - Check MySQL connection

## Backup Scripts
- `scripts/backup/backup_system.sh` - Full system backup (Linux)
- `scripts/backup/backup_system.bat` - Full system backup (Windows)

## Setup Scripts
- `scripts/setup/setup_ubuntu.sh` - Ubuntu system setup
- `scripts/setup/setup.py` - Python setup script
- `scripts/setup/install_dependencies.sh` - Install system dependencies
- `scripts/setup/install_requirements.sh` - Install requirements (Linux)
- `scripts/setup/install_requirements.ps1` - Install requirements (PowerShell)
- `scripts/setup/prepare_for_linux.sh` - Prepare system for Linux

## Windows Scripts
- `scripts/windows/fix_line_endings.bat` - Fix line endings (Windows)
- `scripts/windows/fix_line_endings.ps1` - Fix line endings (PowerShell)
- `scripts/windows/install_requirements.ps1` - Install requirements (PowerShell)
- `scripts/windows/backup_system.bat` - System backup (Windows)
- `scripts/windows/run_serverassistant.bat` - Run ServerAssistant (Windows)

## Linux Scripts
- `scripts/linux/setup_ubuntu.sh` - Ubuntu setup
- `scripts/linux/install_dependencies.sh` - Install dependencies
- `scripts/linux/install_requirements.sh` - Install requirements
- `scripts/linux/prepare_for_linux.sh` - Prepare for Linux
- `scripts/linux/fix_permissions.sh` - Fix permissions
- `scripts/linux/restart_services.sh` - Restart services
- `scripts/linux/check_mysql.sh` - Check MySQL
- `scripts/linux/add_to_hosts.sh` - Add entries to hosts file

## Usage

### From Project Root
```bash
# Run startup script
./scripts/startup/start.sh

# Run maintenance script
./scripts/maintenance/fix_permissions.sh

# Run testing script
./scripts/testing/quick_test.sh
```

### From Scripts Directory
```bash
cd scripts/startup
./start.sh
```

### Using Wrapper Scripts
```bash
# Use wrapper scripts in root directory
./start.sh
./start.bat
./quick_start.sh
```

## Making Scripts Executable
```bash
# Make all scripts executable
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Make specific script executable
chmod +x scripts/startup/start.sh
```
"""
    
    with open("scripts/SCRIPT_INDEX.md", 'w') as f:
        f.write(index_content)
    print("Created script index: scripts/SCRIPT_INDEX.md")

def main():
    """Main function to organize all scripts"""
    print("Organizing ServerAssistant scripts...")
    print("=" * 50)
    
    # Create directory structure
    print("\n1. Creating directory structure...")
    create_directory_structure()
    
    # Categorize and move scripts
    print("\n2. Categorizing and moving scripts...")
    moved, skipped = categorize_scripts()
    print(f"Moved {moved} scripts, skipped {skipped} (not found)")
    
    # Create symlinks/wrappers
    print("\n3. Creating wrapper scripts...")
    create_symlinks()
    
    # Update script paths
    print("\n4. Updating script paths...")
    update_script_paths()
    
    # Create script index
    print("\n5. Creating script index...")
    create_script_index()
    
    print("\n" + "=" * 50)
    print("Script organization complete!")
    print("\nNext steps:")
    print("1. Test the wrapper scripts: ./start.sh or ./start.bat")
    print("2. Review the script index: scripts/SCRIPT_INDEX.md")
    print("3. Make scripts executable: find scripts/ -name '*.sh' -exec chmod +x {} \\;")
    print("4. Remove old script files if everything works correctly")

if __name__ == "__main__":
    main() 