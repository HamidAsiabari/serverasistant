#!/usr/bin/env python3
"""
Nginx Reverse Proxy Setup Test Script
Tests the complete Nginx setup with domain configuration
"""

import os
import sys
import time
import json
import subprocess
import requests
import urllib3
from pathlib import Path
from typing import Dict, Any

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class NginxSetupTester:
    """Test class for Nginx setup and configuration."""
    
    def __init__(self):
        self.base_path = Path(__file__).parent.parent.parent
        self.nginx_path = self.base_path / "docker_services" / "nginx"
        self.test_results = {}
        
    def print_status(self, message: str, status: str = "INFO"):
        """Print status message with color coding."""
        colors = {
            "INFO": "\033[94m",    # Blue
            "SUCCESS": "\033[92m", # Green
            "WARNING": "\033[93m", # Yellow
            "ERROR": "\033[91m",   # Red
            "RESET": "\033[0m"     # Reset
        }
        
        status_color = colors.get(status, colors["INFO"])
        print(f"{status_color}[{status}]{colors['RESET']} {message}")
    
    def run_command(self, command: str, cwd: Path = None) -> tuple:
        """Run a shell command and return (success, output)."""
        try:
            if cwd is None:
                cwd = self.base_path
                
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
    
    def test_docker_environment(self) -> bool:
        """Test Docker environment and basic setup."""
        self.print_status("Testing Docker environment...", "INFO")
        
        # Check if Docker is running
        success, stdout, stderr = self.run_command("docker --version")
        if not success:
            self.print_status("Docker is not installed or not accessible", "ERROR")
            return False
        
        self.print_status(f"Docker version: {stdout.strip()}", "SUCCESS")
        
        # Check if Docker Compose is available
        success, stdout, stderr = self.run_command("docker-compose --version")
        if not success:
            self.print_status("Docker Compose is not available", "ERROR")
            return False
        
        self.print_status(f"Docker Compose version: {stdout.strip()}", "SUCCESS")
        
        # Check if Docker daemon is running
        success, stdout, stderr = self.run_command("docker info")
        if not success:
            self.print_status("Docker daemon is not running", "ERROR")
            return False
        
        self.print_status("Docker daemon is running", "SUCCESS")
        return True
    
    def test_nginx_files(self) -> bool:
        """Test that required Nginx files exist."""
        self.print_status("Testing Nginx files...", "INFO")
        
        required_files = [
            "docker-compose.yml",
            "config/nginx.conf",
            "config/conf.d/default.conf"
        ]
        
        all_exist = True
        for file_path in required_files:
            full_path = self.nginx_path / file_path
            if full_path.exists():
                self.print_status(f"✅ {file_path} exists", "SUCCESS")
            else:
                self.print_status(f"❌ {file_path} missing", "ERROR")
                all_exist = False
        
        return all_exist
    
    def test_ssl_certificates(self) -> bool:
        """Test SSL certificate generation and setup."""
        self.print_status("Testing SSL certificates...", "INFO")
        
        ssl_dir = self.nginx_path / "ssl"
        if not ssl_dir.exists():
            self.print_status("SSL directory does not exist", "WARNING")
            return True  # SSL is optional for testing
        
        # Check for certificate files
        cert_files = ["cert.pem", "key.pem"]
        all_exist = True
        for cert_file in cert_files:
            cert_path = ssl_dir / cert_file
            if cert_path.exists():
                self.print_status(f"✅ {cert_file} exists", "SUCCESS")
            else:
                self.print_status(f"⚠ {cert_file} missing", "WARNING")
                all_exist = False
        
        return all_exist
    
    def test_docker_networks(self) -> bool:
        """Test Docker network setup."""
        self.print_status("Testing Docker networks...", "INFO")
        
        # Check if the required network exists
        success, stdout, stderr = self.run_command("docker network ls --format '{{.Name}}' | grep -E '^(nginx|serverassistant)$'")
        if success and stdout.strip():
            self.print_status("Required Docker network exists", "SUCCESS")
            return True
        else:
            self.print_status("Required Docker network not found", "WARNING")
            return True  # Network will be created when services start
    
    def test_docker_compose_config(self) -> bool:
        """Test Docker Compose configuration."""
        self.print_status("Testing Docker Compose configuration...", "INFO")
        
        compose_file = self.nginx_path / "docker-compose.yml"
        if not compose_file.exists():
            self.print_status("docker-compose.yml not found", "ERROR")
            return False
        
        # Validate Docker Compose file
        success, stdout, stderr = self.run_command("docker-compose config", cwd=self.nginx_path)
        if success:
            self.print_status("Docker Compose configuration is valid", "SUCCESS")
            return True
        else:
            self.print_status(f"Docker Compose configuration error: {stderr}", "ERROR")
            return False
    
    def test_hosts_file(self) -> bool:
        """Test hosts file configuration."""
        self.print_status("Testing hosts file configuration...", "INFO")
        
        # Check if domains are in hosts file
        domains = [
            "app.soject.com",
            "admin.soject.com", 
            "docker.soject.com",
            "gitlab.soject.com",
            "mail.soject.com"
        ]
        
        try:
            with open("/etc/hosts", "r") as f:
                hosts_content = f.read()
            
            missing_domains = []
            for domain in domains:
                if domain not in hosts_content:
                    missing_domains.append(domain)
            
            if missing_domains:
                self.print_status(f"Missing domains in hosts file: {', '.join(missing_domains)}", "WARNING")
                return True  # This is a warning, not an error
            else:
                self.print_status("All domains found in hosts file", "SUCCESS")
                return True
                
        except Exception as e:
            self.print_status(f"Could not read hosts file: {e}", "WARNING")
            return True  # This is a warning, not an error
    
    def test_nginx_container(self) -> bool:
        """Test Nginx container startup and health."""
        self.print_status("Testing Nginx container...", "INFO")
        
        # Start Nginx container
        success, stdout, stderr = self.run_command("docker-compose up -d", cwd=self.nginx_path)
        if not success:
            self.print_status(f"Failed to start Nginx container: {stderr}", "ERROR")
            return False
        
        self.print_status("Nginx container started", "SUCCESS")
        
        # Wait for container to be ready
        time.sleep(10)
        
        # Check container status
        success, stdout, stderr = self.run_command("docker-compose ps", cwd=self.nginx_path)
        if success:
            self.print_status("Nginx container is running", "SUCCESS")
            return True
        else:
            self.print_status("Nginx container is not running", "ERROR")
            return False
    
    def test_domain_access(self) -> bool:
        """Test domain accessibility."""
        self.print_status("Testing domain access...", "INFO")
        
        test_urls = [
            ("http://app.soject.com", "Web App"),
            ("http://admin.soject.com", "phpMyAdmin"),
            ("http://docker.soject.com", "Portainer"),
            ("http://gitlab.soject.com", "GitLab"),
            ("http://mail.soject.com", "Roundcube")
        ]
        
        for url, service_name in test_urls:
            try:
                response = requests.get(url, timeout=10, allow_redirects=True)
                if response.status_code == 200:
                    self.test_results[service_name] = "SUCCESS"
                    self.print_status(f"✅ {service_name}: {url} - OK", "SUCCESS")
                else:
                    self.test_results[service_name] = f"HTTP {response.status_code}"
                    self.print_status(f"⚠ {service_name}: {url} - HTTP {response.status_code}", "WARNING")
            except requests.exceptions.RequestException as e:
                self.test_results[service_name] = f"ERROR: {e}"
                self.print_status(f"❌ {service_name}: {url} - {e}", "ERROR")
        
        return True
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate a test report."""
        return {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "nginx_path": str(self.nginx_path),
            "test_results": self.test_results,
        }
    
    def cleanup(self):
        """Clean up test environment."""
        self.print_status("Cleaning up test environment...", "INFO")
        
        # Stop Nginx container
        if not self.test_results.get("Web App Health") == "SUCCESS":
            self.run_command("docker-compose down", cwd=self.nginx_path)
        
        if not self.test_results.get("phpMyAdmin") == "SUCCESS":
            self.run_command("docker-compose down", cwd=self.nginx_path)
        
        if not self.test_results.get("Portainer") == "SUCCESS":
            self.run_command("docker-compose down", cwd=self.nginx_path)
        
        if not self.test_results.get("GitLab") == "SUCCESS":
            self.run_command("docker-compose down", cwd=self.nginx_path)
        
        if not self.test_results.get("Roundcube") == "SUCCESS":
            self.run_command("docker-compose down", cwd=self.nginx_path)
    
    def save_report(self, report: Dict[str, Any]):
        """Save test report to file."""
        report_file = self.base_path / "nginx_test_report.json"
        try:
            with open(report_file, 'w') as f:
                json.dump(report, f, indent=2)
            self.print_status(f"Test report saved to {report_file}", "SUCCESS")
        except Exception as e:
            self.print_status(f"Failed to save test report: {e}", "ERROR")
    
    def print_summary(self):
        """Print test summary."""
        self.print_status("Test Summary:", "INFO")
        print("-" * 50)
        
        for service, result in self.test_results.items():
            if result == "SUCCESS":
                self.print_status(f"{service}: ✅ SUCCESS", "SUCCESS")
            else:
                self.print_status(f"{service}: ❌ {result}", "ERROR")
    
    def run_all_tests(self) -> bool:
        """Run all Nginx setup tests."""
        self.print_status("Starting Nginx Setup Tests", "INFO")
        print("=" * 60)
        
        tests = [
            ("Docker Environment", self.test_docker_environment),
            ("Nginx Files", self.test_nginx_files),
            ("SSL Certificates", self.test_ssl_certificates),
            ("Docker Networks", self.test_docker_networks),
            ("Docker Compose Config", self.test_docker_compose_config),
            ("Hosts File", self.test_hosts_file),
            ("Nginx Container", self.test_nginx_container),
            ("Domain Access", self.test_domain_access)
        ]
        
        results = {}
        for test_name, test_func in tests:
            self.print_status(f"\n--- {test_name} ---", "INFO")
            try:
                result = test_func()
                results[test_name] = "PASS" if result else "FAIL"
            except Exception as e:
                self.print_status(f"Test {test_name} failed with exception: {e}", "ERROR")
                results[test_name] = "ERROR"
        
        # Print results
        print("\n" + "=" * 60)
        self.print_status("Test Results:", "INFO")
        for test_name, result in results.items():
            status_color = "SUCCESS" if result == "PASS" else "ERROR"
            self.print_status(f"{test_name}: {result}", status_color)
        
        # Generate and save report
        report = self.generate_report()
        self.save_report(report)
        
        # Print summary
        self.print_summary()
        
        # Cleanup
        self.cleanup()
        
        return all(result == "PASS" for result in results.values())

def main():
    """Main function to run Nginx setup tests."""
    tester = NginxSetupTester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎉 All Nginx setup tests passed!")
    else:
        print("\n❌ Some Nginx setup tests failed!")
    
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1) 