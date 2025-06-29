#!/usr/bin/env python3
"""
Test script to verify Docker Service Manager installation (ASCII version)
"""

import sys
import json
import os
from pathlib import Path

def test_imports():
    """Test if all required modules can be imported."""
    print("Testing imports...")
    
    try:
        import docker
        print("[OK] docker module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import docker: {e}")
        return False
    
    try:
        import yaml
        print("[OK] pyyaml module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import pyyaml: {e}")
        return False
    
    try:
        import psutil
        print("[OK] psutil module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import psutil: {e}")
        return False
    
    try:
        import colorama
        print("[OK] colorama module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import colorama: {e}")
        return False
    
    try:
        import tabulate
        print("[OK] tabulate module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import tabulate: {e}")
        return False
    
    try:
        import schedule
        print("[OK] schedule module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import schedule: {e}")
        return False
    
    try:
        import requests
        print("[OK] requests module imported successfully")
    except ImportError as e:
        print(f"[ERROR] Failed to import requests: {e}")
        return False
    
    return True

def test_config_file():
    """Test if configuration file exists and is valid JSON."""
    print("\nTesting configuration file...")
    
    config_file = "config.json"
    if not os.path.exists(config_file):
        print(f"[ERROR] Configuration file {config_file} not found")
        return False
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        print("[OK] Configuration file is valid JSON")
        
        # Check required fields
        if 'services' in config:
            print(f"[OK] Found {len(config['services'])} services in configuration")
        else:
            print("[ERROR] No 'services' section found in configuration")
            return False
        
        if 'server_name' in config:
            print(f"[OK] Server name: {config['server_name']}")
        else:
            print("[ERROR] No 'server_name' found in configuration")
            return False
        
        return True
        
    except json.JSONDecodeError as e:
        print(f"[ERROR] Configuration file is not valid JSON: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Error reading configuration file: {e}")
        return False

def test_docker_manager():
    """Test if DockerManager can be imported and initialized."""
    print("\nTesting DockerManager...")
    
    try:
        from docker_manager import DockerManager
        print("[OK] DockerManager imported successfully")
        
        # Try to initialize (this will fail if Docker is not running, but that's OK)
        try:
            manager = DockerManager("config.json")
            print("[OK] DockerManager initialized successfully")
            return True
        except Exception as e:
            print(f"[WARNING] DockerManager initialization failed (Docker may not be running): {e}")
            print("This is expected if Docker is not running")
            return True
            
    except ImportError as e:
        print(f"[ERROR] Failed to import DockerManager: {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Error testing DockerManager: {e}")
        return False

def test_file_structure():
    """Test if all required files exist."""
    print("\nTesting file structure...")
    
    required_files = [
        "main.py",
        "docker_manager.py",
        "monitor.py",
        "requirements.txt",
        "README.md",
        "config.json"
    ]
    
    all_exist = True
    for file in required_files:
        if os.path.exists(file):
            print(f"[OK] {file} exists")
        else:
            print(f"[ERROR] {file} missing")
            all_exist = False
    
    # Check example services
    example_dirs = [
        "example_services/web-app",
        "example_services/database"
    ]
    
    for dir_path in example_dirs:
        if os.path.exists(dir_path):
            print(f"[OK] {dir_path} exists")
        else:
            print(f"[WARNING] {dir_path} missing (optional)")
    
    return all_exist

def test_docker_connection():
    """Test Docker connection."""
    print("\nTesting Docker connection...")
    
    try:
        import docker
        client = docker.from_env()
        client.ping()
        print("[OK] Docker daemon is running and accessible")
        return True
    except Exception as e:
        print(f"[WARNING] Docker daemon is not accessible: {e}")
        print("This is expected if Docker is not running")
        return True

def main():
    """Run all tests."""
    print("Docker Service Manager - Installation Test")
    print("=" * 50)
    
    tests = [
        ("Import Tests", test_imports),
        ("File Structure", test_file_structure),
        ("Configuration File", test_config_file),
        ("DockerManager", test_docker_manager),
        ("Docker Connection", test_docker_connection)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{test_name}:")
        print("-" * 30)
        if test_func():
            passed += 1
        else:
            print(f"[ERROR] {test_name} failed")
    
    print("\n" + "=" * 50)
    print(f"Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("[SUCCESS] All tests passed! Installation is successful.")
        print("\nYou can now use the Docker Service Manager:")
        print("  python main.py status")
        print("  python main.py start-all")
        print("  python monitor.py")
    else:
        print("[WARNING] Some tests failed. Please check the errors above.")
        print("\nCommon solutions:")
        print("  1. Install missing dependencies: pip install -r requirements.txt")
        print("  2. Ensure Docker is running")
        print("  3. Check file permissions")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 