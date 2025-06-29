#!/usr/bin/env python3
"""
Simple migration script for ServerAssistant structure
"""

import os
import shutil
from pathlib import Path

def main():
    print("ServerAssistant Structure Migration")
    print("=" * 40)
    
    base_path = Path(__file__).parent
    
    # Check if new structure exists
    if not (base_path / "src").exists():
        print("ERROR: New structure not found. Please ensure src/ directory exists.")
        return False
        
    # Create backup
    backup_path = base_path / "backup_old"
    backup_path.mkdir(exist_ok=True)
    
    # Backup old files
    old_files = ["serverassistant.py", "main.py", "docker_manager.py"]
    for file_name in old_files:
        file_path = base_path / file_name
        if file_path.exists():
            shutil.copy2(file_path, backup_path / file_name)
            print(f"Backed up {file_name}")
    
    # Create legacy startup script
    legacy_script = """#!/bin/bash
# Legacy startup script - redirects to new structure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "src/main.py" ]; then
    python src/main.py "$@"
else
    echo "New structure not found!"
    exit 1
fi
"""
    
    with open(base_path / "start_legacy.sh", 'w') as f:
        f.write(legacy_script)
    os.chmod(base_path / "start_legacy.sh", 0o755)
    
    print("Migration completed!")
    print("Use: python src/main.py")
    return True

if __name__ == "__main__":
    main() 