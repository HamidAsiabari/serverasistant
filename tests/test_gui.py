#!/usr/bin/env python3
"""
Test script for ServerAssistant GUI
"""

import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

def test_imports():
    """Test if all required modules can be imported."""
    print("🧪 Testing imports...")
    
    try:
        # Test textual import
        import textual
        print("✅ Textual imported successfully")
    except ImportError as e:
        print(f"❌ Textual import failed: {e}")
        print("💡 Install with: pip install textual>=0.52.0")
        return False
    
    try:
        # Test our modules
        from src.core.server_assistant import ServerAssistant
        from src.core.docker_manager import ServiceStatus
        print("✅ ServerAssistant modules imported successfully")
    except ImportError as e:
        print(f"❌ ServerAssistant import failed: {e}")
        return False
    
    try:
        # Test GUI module
        from src.ui.simple_textual_app import run_simple_textual_app
        print("✅ GUI module imported successfully")
    except ImportError as e:
        print(f"❌ GUI module import failed: {e}")
        return False
    
    return True

def test_config():
    """Test if configuration file exists and is valid."""
    print("\n📋 Testing configuration...")
    
    config_path = Path("config.json")
    if not config_path.exists():
        print("❌ config.json not found")
        return False
    
    try:
        import json
        with open(config_path, 'r') as f:
            config = json.load(f)
        
        print(f"✅ Configuration loaded: {config.get('server_name', 'Unknown')}")
        print(f"📊 Services configured: {len(config.get('services', []))}")
        return True
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        return False

def test_docker():
    """Test Docker environment."""
    print("\n🐳 Testing Docker environment...")
    
    try:
        import subprocess
        result = subprocess.run(['docker', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✅ Docker available: {result.stdout.strip()}")
        
        result = subprocess.run(['docker-compose', '--version'], 
                              capture_output=True, text=True, check=True)
        print(f"✅ Docker Compose available: {result.stdout.strip()}")
        
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Docker command failed: {e}")
        return False
    except FileNotFoundError:
        print("❌ Docker not found in PATH")
        return False

def main():
    """Run all tests."""
    print("🚀 ServerAssistant GUI Test Suite")
    print("=" * 40)
    
    tests = [
        ("Imports", test_imports),
        ("Configuration", test_config),
        ("Docker Environment", test_docker),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
    
    print("\n📊 Test Results:")
    print("-" * 20)
    
    all_passed = True
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name}: {status}")
        if not result:
            all_passed = False
    
    print("\n" + "=" * 40)
    if all_passed:
        print("🎉 All tests passed! GUI should work correctly.")
        print("\n💡 To launch the GUI:")
        print("   python gui_main.py")
        print("   or")
        print("   ./scripts/startup/launch_gui.sh (Linux/macOS)")
        print("   scripts\\startup\\launch_gui.bat (Windows)")
    else:
        print("⚠️  Some tests failed. Please fix the issues above.")
        print("\n💡 Common solutions:")
        print("   - Install textual: pip install textual>=0.52.0")
        print("   - Ensure config.json exists")
        print("   - Install Docker and Docker Compose")
    
    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 