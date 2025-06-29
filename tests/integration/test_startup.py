#!/usr/bin/env python3
"""
Test script to verify startup process and configuration
"""

import json
from pathlib import Path
import sys
import os

def test_config_loading():
    """Test that the configuration file can be loaded and parsed."""
    print("Testing configuration loading...")
    
    config_file = Path("config.json")
    if not config_file.exists():
        print("❌ config.json file not found")
        return False
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        print("✅ Configuration file loaded successfully")
        
        # Check for required sections
        if 'services' not in config:
            print("❌ No 'services' section found in configuration")
            return False
        
        if 'server_name' not in config:
            print("❌ No 'server_name' found in configuration")
            return False
        
        print(f"✅ Found {len(config['services'])} services in configuration")
        print(f"✅ Server name: {config['server_name']}")
        
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ Configuration file is not valid JSON: {e}")
        return False
    except Exception as e:
        print(f"❌ Error loading configuration: {e}")
        return False

def test_test_config():
    """Test the Ubuntu 22.04 test configuration."""
    print("Testing Ubuntu 22.04 test configuration...")
    
    test_config_file = Path("tests/config/test_config_ubuntu22.json")
    if test_config_file.exists():
        try:
            with open(test_config_file, 'r') as f:
                test_config = json.load(f)
            
            print("✅ Test configuration loaded successfully")
            
            # Check for required sections
            if 'services' not in test_config:
                print("❌ No 'services' section found in test configuration")
                return False
            
            print(f"✅ Found {len(test_config['services'])} services in test configuration")
            return True
            
        except json.JSONDecodeError as e:
            print(f"❌ Test configuration is not valid JSON: {e}")
            return False
        except Exception as e:
            print(f"❌ Error loading test configuration: {e}")
            return False
    else:
        print("⚠ Test configuration file not found")
        return True

def test_script_files():
    """Test that required script files exist."""
    print("Testing script files...")
    
    required_scripts = [
        "start.sh",
        "start.bat",
        "scripts/startup/start.sh",
        "scripts/startup/start.bat",
        "scripts/setup/install_dependencies.sh",
        "scripts/setup/install_requirements.ps1"
    ]
    
    all_exist = True
    for script in required_scripts:
        if Path(script).exists():
            print(f"✅ {script} exists")
        else:
            print(f"❌ {script} missing")
            all_exist = False
    
    return all_exist

def test_service_directories():
    """Test that service directories exist and contain required files."""
    print("Testing service directories...")
    
    service_dirs = [
        "docker_services/nginx",
        "docker_services/web-app",
        "docker_services/mysql",
        "docker_services/database",
        "docker_services/portainer",
        "docker_services/gitlab",
        "docker_services/mail-server"
    ]
    
    all_valid = True
    for service_dir in service_dirs:
        dir_path = Path(service_dir)
        if dir_path.exists():
            print(f"✅ {service_dir} exists")
            
            # Check for docker-compose.yml
            compose_file = dir_path / "docker-compose.yml"
            if compose_file.exists():
                print(f"  ✅ docker-compose.yml found")
            else:
                print(f"  ❌ docker-compose.yml missing")
                all_valid = False
                
            # Check for README.md
            readme_file = dir_path / "README.md"
            if readme_file.exists():
                print(f"  ✅ README.md found")
            else:
                print(f"  ⚠ README.md missing (optional)")
        else:
            print(f"❌ {service_dir} missing")
            all_valid = False
    
    return all_valid

def main():
    """Run all startup tests."""
    print("🚀 Running Startup Tests...")
    print("=" * 50)
    
    config_ok = test_config_loading()
    test_config_ok = test_test_config()
    scripts_ok = test_script_files()
    services_ok = test_service_directories()
    
    print("\n" + "=" * 50)
    print("Test Results:")
    print(f"Config Loading: {'✅ OK' if config_ok else '❌ FAILED'}")
    print(f"Test Config: {'✅ OK' if test_config_ok else '❌ FAILED'}")
    print(f"Script Files: {'✅ OK' if scripts_ok else '❌ FAILED'}")
    print(f"Service Directories: {'✅ OK' if services_ok else '❌ FAILED'}")
    
    if config_ok and test_config_ok and scripts_ok and services_ok:
        print("\n🎉 All startup tests passed!")
        print("The system is ready to start services.")
        return True
    else:
        print("\n❌ Some startup tests failed!")
        print("Please fix the issues before starting services.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 