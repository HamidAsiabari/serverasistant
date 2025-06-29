#!/usr/bin/env python3
"""
Test script to verify configuration paths are correct
"""

import json
from pathlib import Path

def test_config_paths():
    """Test that all service paths in config.json exist"""
    
    # Load configuration
    config_file = Path("config.json")
    if not config_file.exists():
        print("❌ config.json not found")
        return False
    
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    print("🔍 Testing configuration paths...")
    
    all_valid = True
    
    for service in config.get('services', []):
        service_name = service.get('name', 'unknown')
        service_path = service.get('path', '')
        
        # Convert relative path to absolute
        if service_path.startswith('./'):
            service_path = service_path[2:]  # Remove './'
        
        full_path = Path(service_path)
        
        if full_path.exists():
            print(f"✅ {service_name}: {service_path} - EXISTS")
        else:
            print(f"❌ {service_name}: {service_path} - MISSING")
            all_valid = False
    
    if all_valid:
        print("\n🎉 All service paths are valid!")
        return True
    else:
        print("\n⚠️  Some service paths are missing!")
        return False

def test_docker_compose_files():
    """Test that Docker Compose files exist for each service"""
    
    config_file = Path("config.json")
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    print("\n🔍 Testing Docker Compose files...")
    
    all_valid = True
    
    for service in config.get('services', []):
        service_name = service.get('name', 'unknown')
        service_path = service.get('path', '')
        service_type = service.get('type', 'unknown')
        
        if service_type == 'docker-compose':
            # Convert relative path to absolute
            if service_path.startswith('./'):
                service_path = service_path[2:]  # Remove './'
            
            compose_file = Path(service_path) / "docker-compose.yml"
            
            if compose_file.exists():
                print(f"✅ {service_name}: docker-compose.yml - EXISTS")
            else:
                print(f"❌ {service_name}: docker-compose.yml - MISSING")
                all_valid = False
    
    if all_valid:
        print("\n🎉 All Docker Compose files are present!")
        return True
    else:
        print("\n⚠️  Some Docker Compose files are missing!")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("    Configuration Test")
    print("=" * 50)
    
    paths_ok = test_config_paths()
    compose_ok = test_docker_compose_files()
    
    if paths_ok and compose_ok:
        print("\n✅ Configuration is ready!")
        print("You can now run: ./start.sh")
    else:
        print("\n❌ Configuration needs fixing!")
        print("Please check the missing paths and files above.") 