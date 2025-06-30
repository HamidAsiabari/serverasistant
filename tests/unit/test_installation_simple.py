#!/usr/bin/env python3
"""
Test script to verify Docker Service Manager installation (ASCII version)
"""

import sys
import json
import os
from pathlib import Path

def test_imports():
    """Test that all required modules can be imported."""
    try:
        import docker
        print("✅ Docker module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import docker module: {e}")
        return False
    
    try:
        import yaml
        print("✅ YAML module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import yaml module: {e}")
        return False
    
    try:
        import requests
        print("✅ Requests module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import requests module: {e}")
        return False
    
    try:
        import psutil
        print("✅ psutil module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import psutil module: {e}")
        return False
    
    try:
        import schedule
        print("✅ Schedule module imported successfully")
    except ImportError as e:
        print(f"❌ Failed to import schedule module: {e}")
        return False
    
    return True

def test_config_file():
    """Test that the configuration file exists and is valid JSON."""
    config_file = Path("config.json")
    if not config_file.exists():
        print("❌ config.json file not found")
        return False
    
    try:
        import json
        with open(config_file, 'r') as f:
            config = json.load(f)
        print("✅ config.json is valid JSON")
        
        # Check for required fields
        required_fields = ['server_name', 'services']
        for field in required_fields:
            if field not in config:
                print(f"❌ Missing required field: {field}")
                return False
        
        print("✅ config.json contains required fields")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ config.json is not valid JSON: {e}")
        return False
    except Exception as e:
        print(f"❌ Error reading config.json: {e}")
        return False

def test_docker_manager():
    """Test that the DockerManager class can be instantiated."""
    try:
        # Add src to path for imports
        src_path = Path(__file__).parent.parent.parent / "src"
        sys.path.insert(0, str(src_path))
        
        from core.docker_manager import DockerManager
        manager = DockerManager()
        print("✅ DockerManager instantiated successfully")
        return True
        
    except ImportError as e:
        print(f"❌ Failed to import DockerManager: {e}")
        return False
    except Exception as e:
        print(f"❌ Error creating DockerManager: {e}")
        return False

def test_file_structure():
    """Test that required directories and files exist."""
    required_paths = [
        "src/",
        "src/core/",
        "src/ui/",
        "src/utils/",
        "scripts/",
        "scripts/setup/",
        "scripts/maintenance/",
        "scripts/startup/",
        "docker_services/",
        "docker_services/mysql/",
        "docker_services/database/",
        "docker_services/web-app/",
        "docker_services/portainer/",
        "docker_services/gitlab/",
        "docker_services/mail-server/"
    ]
    
    for path in required_paths:
        if not Path(path).exists():
            print(f"❌ Required path not found: {path}")
            return False
    
    print("✅ All required directories exist")
    return True

def test_docker_connection():
    """Test that Docker daemon is accessible."""
    try:
        import docker
        client = docker.from_env()
        client.ping()
        print("✅ Docker daemon is accessible")
        return True
    except Exception as e:
        print(f"❌ Cannot connect to Docker daemon: {e}")
        print("   Make sure Docker is running and you have permission to access it")
        return False

def main():
    """Run all installation tests."""
    print("🔧 Running Installation Tests...")
    print("=" * 50)
    
    tests = [
        ("Import Tests", test_imports),
        ("File Structure", test_file_structure),
        ("Configuration File", test_config_file),
        ("DockerManager", test_docker_manager),
        ("Docker Connection", test_docker_connection)
    ]
    
    all_passed = True
    for test_name, test_func in tests:
        print(f"\n{test_name}:")
        try:
            if test_func():
                print(f"✅ {test_name} passed")
            else:
                print(f"❌ {test_name} failed")
                all_passed = False
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All installation tests passed!")
        return True
    else:
        print("❌ Some installation tests failed!")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 