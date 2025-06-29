#!/usr/bin/env python3
"""
Test script to check service status and network connectivity
"""

import subprocess
import json
import requests
from pathlib import Path

def run_command(command):
    """Run a command and return result"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def check_docker_containers():
    """Check running Docker containers"""
    print("🔍 Checking Docker containers...")
    
    success, stdout, stderr = run_command("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}'")
    
    if success:
        print(stdout)
        return True
    else:
        print(f"❌ Error: {stderr}")
        return False

def check_docker_networks():
    """Check Docker networks"""
    print("\n🔍 Checking Docker networks...")
    
    success, stdout, stderr = run_command("docker network ls")
    
    if success:
        print(stdout)
        return True
    else:
        print(f"❌ Error: {stderr}")
        return False

def check_nginx_status():
    """Check Nginx status"""
    print("\n🔍 Checking Nginx status...")
    
    # Check if nginx container is running
    success, stdout, stderr = run_command("docker ps --filter name=nginx-proxy --format '{{.Names}}\t{{.Status}}'")
    
    if success and "nginx-proxy" in stdout:
        print("✅ Nginx container is running")
        
        # Check Nginx logs
        print("\n📋 Nginx logs (last 10 lines):")
        success, stdout, stderr = run_command("docker logs nginx-proxy --tail 10")
        if success:
            print(stdout)
        else:
            print(f"❌ Error getting logs: {stderr}")
        
        # Test Nginx configuration
        print("\n🔧 Testing Nginx configuration:")
        success, stdout, stderr = run_command("docker exec nginx-proxy nginx -t")
        if success:
            print("✅ Nginx configuration is valid")
        else:
            print(f"❌ Nginx configuration error: {stderr}")
        
        return True
    else:
        print("❌ Nginx container is not running")
        return False

def test_local_access():
    """Test local access to services"""
    print("\n🔍 Testing local access to services...")
    
    services = [
        ("HTTP (port 80)", "http://localhost:80"),
        ("HTTPS (port 443)", "https://localhost:443"),
        ("Web App (port 8080)", "http://localhost:8080"),
        ("Portainer (port 9000)", "http://localhost:9000"),
        ("Roundcube (port 8083)", "http://localhost:8083"),
    ]
    
    for service_name, url in services:
        try:
            response = requests.get(url, timeout=5, verify=False)
            print(f"✅ {service_name}: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"❌ {service_name}: {e}")

def test_subdomain_access():
    """Test subdomain access"""
    print("\n🔍 Testing subdomain access...")
    
    subdomains = [
        "app.soject.com",
        "admin.soject.com", 
        "portainer.soject.com",
        "gitlab.soject.com",
        "mail.soject.com"
    ]
    
    for subdomain in subdomains:
        try:
            response = requests.get(f"https://{subdomain}", timeout=5, verify=False)
            print(f"✅ {subdomain}: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"❌ {subdomain}: {e}")

def check_hosts_file():
    """Check if subdomains are in hosts file"""
    print("\n🔍 Checking hosts file...")
    
    try:
        with open("/etc/hosts", "r") as f:
            hosts_content = f.read()
        
        subdomains = ["app.soject.com", "admin.soject.com", "portainer.soject.com", "gitlab.soject.com", "mail.soject.com"]
        
        for subdomain in subdomains:
            if subdomain in hosts_content:
                print(f"✅ {subdomain} found in hosts file")
            else:
                print(f"❌ {subdomain} NOT found in hosts file")
                
    except Exception as e:
        print(f"❌ Error reading hosts file: {e}")

def main():
    """Main test function"""
    print("=" * 60)
    print("    Service Status Test")
    print("=" * 60)
    
    # Check Docker containers
    containers_ok = check_docker_containers()
    
    # Check Docker networks
    networks_ok = check_docker_networks()
    
    # Check Nginx status
    nginx_ok = check_nginx_status()
    
    # Test local access
    test_local_access()
    
    # Check hosts file
    check_hosts_file()
    
    # Test subdomain access
    test_subdomain_access()
    
    print("\n" + "=" * 60)
    print("    Summary")
    print("=" * 60)
    
    print(f"Containers: {'✅ OK' if containers_ok else '❌ ISSUES'}")
    print(f"Networks: {'✅ OK' if networks_ok else '❌ ISSUES'}")
    print(f"Nginx: {'✅ OK' if nginx_ok else '❌ ISSUES'}")
    
    print("\n💡 Troubleshooting tips:")
    print("1. If subdomains don't work, add them to /etc/hosts:")
    print("   127.0.0.1 app.soject.com admin.soject.com portainer.soject.com gitlab.soject.com mail.soject.com")
    print("2. If services aren't accessible, check if containers are on the same network")
    print("3. If Nginx has errors, check the configuration files")

if __name__ == "__main__":
    main() 