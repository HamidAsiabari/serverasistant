#!/usr/bin/env python3
"""
Test script to verify startup process and configuration
"""

import json
from pathlib import Path
import sys

def test_config_loading():
    """Test configuration loading"""
    print("🔍 Testing configuration loading...")
    
    # Test main config
    config_file = Path("config.json")
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            print(f"✅ Main config loaded: {config.get('server_name', 'Unknown')}")
            
            # Check service paths
            for service in config.get('services', []):
                service_name = service.get('name', 'unknown')
                service_path = service.get('path', '')
                service_type = service.get('type', 'unknown')
                
                if service_path.startswith('./'):
                    service_path = service_path[2:]
                
                full_path = Path(service_path)
                if full_path.exists():
                    print(f"  ✅ {service_name} ({service_type}): {service_path}")
                else:
                    print(f"  ❌ {service_name} ({service_type}): {service_path} - MISSING")
            
            return True
        except Exception as e:
            print(f"❌ Error loading main config: {e}")
            return False
    else:
        print("❌ Main config.json not found")
        return False

def test_test_config():
    """Test test configuration"""
    print("\n🔍 Testing test configuration...")
    
    test_config_file = Path("test_config_ubuntu22.json")
    if test_config_file.exists():
        try:
            with open(test_config_file, 'r') as f:
                config = json.load(f)
            print(f"✅ Test config loaded: {config.get('server_name', 'Unknown')}")
            
            # Check service paths
            for service in config.get('services', []):
                service_name = service.get('name', 'unknown')
                service_path = service.get('path', '')
                service_type = service.get('type', 'unknown')
                
                if service_path.startswith('./'):
                    service_path = service_path[2:]
                
                full_path = Path(service_path)
                if full_path.exists():
                    print(f"  ✅ {service_name} ({service_type}): {service_path}")
                else:
                    print(f"  ❌ {service_name} ({service_type}): {service_path} - MISSING")
            
            return True
        except Exception as e:
            print(f"❌ Error loading test config: {e}")
            return False
    else:
        print("❌ Test config not found")
        return False

def test_script_files():
    """Test that required script files exist"""
    print("\n🔍 Testing script files...")
    
    scripts = [
        "serverassistant.py",
        "start.sh",
        "start.py",
        "start.bat"
    ]
    
    all_exist = True
    for script in scripts:
        if Path(script).exists():
            print(f"✅ {script} - EXISTS")
        else:
            print(f"❌ {script} - MISSING")
            all_exist = False
    
    return all_exist

def test_service_directories():
    """Test that service directories exist"""
    print("\n🔍 Testing service directories...")
    
    services = [
        "example_services/nginx",
        "example_services/web-app",
        "example_services/mysql",
        "example_services/database",
        "example_services/portainer",
        "example_services/gitlab",
        "example_services/mail-server"
    ]
    
    all_exist = True
    for service in services:
        if Path(service).exists():
            print(f"✅ {service} - EXISTS")
        else:
            print(f"❌ {service} - MISSING")
            all_exist = False
    
    return all_exist

def main():
    """Main test function"""
    print("=" * 50)
    print("    Startup Test")
    print("=" * 50)
    
    # Test configuration loading
    config_ok = test_config_loading()
    test_config_ok = test_test_config()
    
    # Test script files
    scripts_ok = test_script_files()
    
    # Test service directories
    services_ok = test_service_directories()
    
    # Summary
    print("\n" + "=" * 50)
    print("    Test Summary")
    print("=" * 50)
    
    print(f"Configuration: {'✅ OK' if config_ok else '❌ FAILED'}")
    print(f"Test Config: {'✅ OK' if test_config_ok else '❌ FAILED'}")
    print(f"Script Files: {'✅ OK' if scripts_ok else '❌ FAILED'}")
    print(f"Service Directories: {'✅ OK' if services_ok else '❌ FAILED'}")
    
    if config_ok and test_config_ok and scripts_ok and services_ok:
        print("\n🎉 All tests passed! Ready to run ServerAssistant.")
        print("\nTo start ServerAssistant, run:")
        print("  ./start.sh")
        print("  OR")
        print("  python3 serverassistant.py")
    else:
        print("\n⚠️  Some tests failed. Please fix the issues above.")
    
    return config_ok and test_config_ok and scripts_ok and services_ok

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 