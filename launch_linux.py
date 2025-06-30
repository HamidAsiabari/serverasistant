#!/usr/bin/env python3
"""
Linux launcher for ServerAssistant with proper path setup
"""

import sys
import os
from pathlib import Path

# Get the project root directory
project_root = Path(__file__).parent.absolute()

# Add the project root to Python path
sys.path.insert(0, str(project_root))

# Add src directory to path as well
src_path = project_root / "src"
sys.path.insert(0, str(src_path))

print(f"🚀 Starting ServerAssistant...")
print(f"📁 Project root: {project_root}")
print(f"🐍 Python path: {sys.path[:2]}")
print()

try:
    # Import and run the main application
    from src.main_enhanced import main
    main()
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 This might be due to missing dependencies.")
    print("🔧 Try running: pip install -r requirements.txt")
    sys.exit(1)
except KeyboardInterrupt:
    print("\n👋 ServerAssistant stopped by user")
except Exception as e:
    print(f"\n❌ Error: {e}")
    sys.exit(1) 