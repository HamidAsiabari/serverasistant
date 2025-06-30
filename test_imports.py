#!/usr/bin/env python3
"""
Test script to verify imports work correctly
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

print("🧪 Testing imports...")
print(f"📁 Project root: {project_root}")
print(f"🐍 Python path: {sys.path[:2]}")
print()

# Test imports
try:
    print("📦 Testing core imports...")
    from src.core.server_assistant import ServerAssistant
    print("✅ ServerAssistant imported successfully")
    
    from src.core.docker_manager import DockerManager
    print("✅ DockerManager imported successfully")
    
    from src.core.config_manager import ConfigManager
    print("✅ ConfigManager imported successfully")
    
    print("\n📦 Testing UI imports...")
    from src.ui.menu_system import MenuSystem, RealTimeEnhancedMenuSystem
    print("✅ MenuSystem imported successfully")
    
    from src.ui.display_utils import DisplayUtils, RealTimeLogPanel, BottomLogDisplay
    print("✅ DisplayUtils imported successfully")
    
    print("\n🎉 All imports successful!")
    print("🚀 ServerAssistant is ready to run!")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 This might be due to missing dependencies.")
    print("🔧 Try running: pip install -r requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"❌ Unexpected error: {e}")
    sys.exit(1) 