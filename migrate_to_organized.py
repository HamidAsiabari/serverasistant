#!/usr/bin/env python3
"""
Migration script to transition from old ServerAssistant structure to new organized structure
"""

import os
import sys
import shutil
import json
from pathlib import Path
from typing import Dict, List, Any


class MigrationHelper:
    """Helper class for migration operations"""
    
    def __init__(self):
        self.base_path = Path(__file__).parent
        self.backup_path = self.base_path / "backup_old_structure"
        
    def print_status(self, message: str):
        """Print status message"""
        print(f"[INFO] {message}")
        
    def print_success(self, message: str):
        """Print success message"""
        print(f"[SUCCESS] {message}")
        
    def print_warning(self, message: str):
        """Print warning message"""
        print(f"[WARNING] {message}")
        
    def print_error(self, message: str):
        """Print error message"""
        print(f"[ERROR] {message}")
        
    def backup_old_structure(self) -> bool:
        """Create backup of old structure"""
        try:
            self.print_status("Creating backup of old structure...")
            
            # Create backup directory
            self.backup_path.mkdir(exist_ok=True)
            
            # Files to backup
            old_files = [
                "serverassistant.py",
                "main.py",
                "docker_manager.py",
                "monitor.py",
                "start.py",
                "start.sh",
                "start.bat"
            ]
            
            for file_name in old_files:
                file_path = self.base_path / file_name
                if file_path.exists():
                    backup_file = self.backup_path / file_name
                    shutil.copy2(file_path, backup_file)
                    self.print_success(f"Backed up {file_name}")
                    
            self.print_success("Backup completed successfully")
            return True
            
        except Exception as e:
            self.print_error(f"Backup failed: {e}")
            return False
            
    def check_new_structure(self) -> bool:
        """Check if new structure exists"""
        required_dirs = ["src", "src/core", "src/ui", "src/utils"]
        required_files = [
            "src/main.py",
            "src/core/__init__.py",
            "src/core/server_assistant.py",
            "src/core/config_manager.py",
            "src/core/docker_manager.py",
            "src/ui/__init__.py",
            "src/ui/display_utils.py",
            "src/ui/menu_system.py",
            "src/utils/__init__.py",
            "src/utils/file_utils.py",
            "src/utils/system_utils.py",
            "src/utils/validation_utils.py"
        ]
        
        # Check directories
        for dir_path in required_dirs:
            if not (self.base_path / dir_path).exists():
                self.print_error(f"Required directory missing: {dir_path}")
                return False
                
        # Check files
        for file_path in required_files:
            if not (self.base_path / file_path).exists():
                self.print_error(f"Required file missing: {file_path}")
                return False
                
        self.print_success("New structure check passed")
        return True
        
    def update_requirements(self) -> bool:
        """Update requirements.txt with new dependencies"""
        try:
            self.print_status("Updating requirements.txt...")
            
            requirements_file = self.base_path / "requirements.txt"
            new_dependencies = [
                "tabulate",
                "psutil",
                "colorama"
            ]
            
            if requirements_file.exists():
                with open(requirements_file, 'r') as f:
                    current_requirements = f.read().splitlines()
                    
                # Add new dependencies if not present
                updated_requirements = current_requirements.copy()
                for dep in new_dependencies:
                    if not any(dep in req for req in current_requirements):
                        updated_requirements.append(dep)
                        
                with open(requirements_file, 'w') as f:
                    f.write('\n'.join(updated_requirements))
                    
                self.print_success("Requirements.txt updated")
            else:
                self.print_warning("requirements.txt not found, creating new one")
                with open(requirements_file, 'w') as f:
                    f.write('\n'.join(new_dependencies))
                    
            return True
            
        except Exception as e:
            self.print_error(f"Failed to update requirements: {e}")
            return False
            
    def create_startup_aliases(self) -> bool:
        """Create startup script aliases"""
        try:
            self.print_status("Creating startup script aliases...")
            
            # Create alias for old start.sh
            if (self.base_path / "start.sh").exists():
                alias_content = f"""#!/bin/bash
# Alias for new organized structure
# This script redirects to the new startup script

SCRIPT_DIR="$(cd "$(dirname "${{BASH_SOURCE[0]}}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "start_organized.sh" ]; then
    echo "Redirecting to new organized startup script..."
    ./start_organized.sh "$@"
else
    echo "New startup script not found, using fallback..."
    if [ -f "serverassistant.py" ]; then
        python serverassistant.py "$@"
    else
        echo "No ServerAssistant found!"
        exit 1
    fi
fi
"""
                with open(self.base_path / "start_legacy.sh", 'w') as f:
                    f.write(alias_content)
                os.chmod(self.base_path / "start_legacy.sh", 0o755)
                self.print_success("Created start_legacy.sh alias")
                
            # Create alias for old start.bat
            if (self.base_path / "start.bat").exists():
                alias_content = f"""@echo off
REM Alias for new organized structure
REM This script redirects to the new startup script

cd /d "%~dp0"

if exist "start_organized.bat" (
    echo Redirecting to new organized startup script...
    call start_organized.bat %*
) else (
    echo New startup script not found, using fallback...
    if exist "serverassistant.py" (
        python serverassistant.py %*
    ) else (
        echo No ServerAssistant found!
        exit /b 1
    )
)
"""
                with open(self.base_path / "start_legacy.bat", 'w') as f:
                    f.write(alias_content)
                self.print_success("Created start_legacy.bat alias")
                
            return True
            
        except Exception as e:
            self.print_error(f"Failed to create startup aliases: {e}")
            return False
            
    def validate_configuration(self) -> bool:
        """Validate existing configuration"""
        try:
            self.print_status("Validating configuration...")
            
            config_file = self.base_path / "config.json"
            if not config_file.exists():
                self.print_warning("No configuration file found")
                return True
                
            with open(config_file, 'r') as f:
                config = json.load(f)
                
            # Basic validation
            required_fields = ["server_name", "environment", "services"]
            for field in required_fields:
                if field not in config:
                    self.print_error(f"Missing required field: {field}")
                    return False
                    
            # Validate services
            services = config.get("services", [])
            for i, service in enumerate(services):
                if not isinstance(service, dict):
                    self.print_error(f"Service {i} is not an object")
                    return False
                    
                service_required = ["name", "enabled", "path"]
                for field in service_required:
                    if field not in service:
                        self.print_error(f"Service {i} missing required field: {field}")
                        return False
                        
            self.print_success("Configuration validation passed")
            return True
            
        except json.JSONDecodeError as e:
            self.print_error(f"Invalid JSON in configuration: {e}")
            return False
        except Exception as e:
            self.print_error(f"Configuration validation failed: {e}")
            return False
            
    def create_migration_report(self) -> bool:
        """Create migration report"""
        try:
            self.print_status("Creating migration report...")
            
            report_file = self.base_path / "MIGRATION_REPORT.md"
            report_content = f"""# Migration Report

## Migration Summary
- **Date**: {Path(__file__).stat().st_mtime}
- **Old Structure**: Backed up to `backup_old_structure/`
- **New Structure**: Available in `src/`

## What Changed
1. **Modular Structure**: Code is now organized into logical modules
2. **Type Safety**: Added type hints throughout the codebase
3. **Better Error Handling**: Improved error messages and validation
4. **Consistent UI**: Unified display formatting and menu system
5. **Easier Development**: Clear separation of concerns

## How to Use the New Structure

### Interactive Mode
```bash
python src/main.py
```

### CLI Mode
```bash
python src/main.py --cli status
python src/main.py --cli start web-app
python src/main.py --cli stop-all
```

### Using New Startup Script
```bash
./start_organized.sh
```

## Rollback Instructions
If you need to rollback to the old structure:

1. Copy files from `backup_old_structure/` back to the root directory
2. Use the legacy startup scripts: `start_legacy.sh` or `start_legacy.bat`

## New Dependencies
The following dependencies were added:
- tabulate: For formatted table output
- psutil: For system monitoring
- colorama: For colored terminal output

## Configuration
Your existing configuration should work without changes. The new structure provides better validation and error handling.

## Support
For issues or questions about the new structure, refer to:
- README_REORGANIZED.md: Overview of the new structure
- DEVELOPMENT_GUIDE.md: Development guidelines
- src/main.py --help: Command-line help
"""
            
            with open(report_file, 'w') as f:
                f.write(report_content)
                
            self.print_success("Migration report created: MIGRATION_REPORT.md")
            return True
            
        except Exception as e:
            self.print_error(f"Failed to create migration report: {e}")
            return False
            
    def run_migration(self) -> bool:
        """Run the complete migration process"""
        print("=" * 60)
        print("ServerAssistant Structure Migration")
        print("=" * 60)
        print()
        
        # Step 1: Check new structure
        if not self.check_new_structure():
            self.print_error("New structure not found. Please ensure all new files are present.")
            return False
            
        # Step 2: Backup old structure
        if not self.backup_old_structure():
            self.print_error("Failed to backup old structure. Aborting migration.")
            return False
            
        # Step 3: Validate configuration
        if not self.validate_configuration():
            self.print_warning("Configuration validation failed. Please check your config.json file.")
            
        # Step 4: Update requirements
        if not self.update_requirements():
            self.print_warning("Failed to update requirements. You may need to install dependencies manually.")
            
        # Step 5: Create startup aliases
        if not self.create_startup_aliases():
            self.print_warning("Failed to create startup aliases.")
            
        # Step 6: Create migration report
        if not self.create_migration_report():
            self.print_warning("Failed to create migration report.")
            
        print()
        print("=" * 60)
        self.print_success("Migration completed successfully!")
        print("=" * 60)
        print()
        print("Next steps:")
        print("1. Test the new structure: python src/main.py")
        print("2. Review the migration report: MIGRATION_REPORT.md")
        print("3. Update any custom scripts to use the new structure")
        print("4. Remove old files when you're confident everything works")
        print()
        print("If you encounter issues, you can rollback using files in backup_old_structure/")
        
        return True


def main():
    """Main function"""
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("ServerAssistant Structure Migration")
        print()
        print("This script migrates from the old ServerAssistant structure to the new organized structure.")
        print()
        print("Usage:")
        print("  python migrate_to_organized.py")
        print()
        print("The script will:")
        print("1. Backup the old structure")
        print("2. Validate the new structure")
        print("3. Update requirements.txt")
        print("4. Create startup script aliases")
        print("5. Generate a migration report")
        print()
        print("No files will be deleted - everything is backed up first.")
        return
        
    migrator = MigrationHelper()
    success = migrator.run_migration()
    
    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main() 