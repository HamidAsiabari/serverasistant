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

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class NginxTester:
    def __init__(self):
        self.base_path = Path(__file__).parent
        self.nginx_path = self.base_path / "example_services" / "nginx"
        self.domains = [
            "app.soject.com",
            "admin.soject.com", 
            "docker.soject.com",
            "gitlab.soject.com",
            "mail.soject.com"
        ]
        self.test_results = {}
        
    def print_status(self, message, status="INFO"):
        """Print colored status messages"""
        colors = {
            "INFO": "\033[94m",    # Blue
            "SUCCESS": "\033[92m", # Green
            "WARNING": "\033[93m", # Yellow
            "ERROR": "\033[91m",   # Red
            "RESET": "\033[0m"     # Reset
        }
        print(f"{colors.get(status, '')}[{status}]{colors['RESET']} {message}")
        
    def run_command(self, command, cwd=None, check=True):
        """Run a shell command and return result"""
        try:
            result = subprocess.run(
                command, 
                shell=True, 
                cwd=cwd or self.base_path,
                capture_output=True, 
                text=True, 
                check=check
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.CalledProcessError as e:
            return False, e.stdout, e.stderr
            
    def test_docker_environment(self):
        """Test Docker environment"""
        self.print_status("Testing Docker environment...")
        
        # Check Docker
        success, stdout, stderr = self.run_command("docker --version")
        if not success:
            self.print_status("Docker not found or not accessible", "ERROR")
            return False
        self.print_status(f"Docker found: {stdout.strip()}")
        
        # Check Docker Compose
        success, stdout, stderr = self.run_command("docker-compose --version")
        if not success:
            self.print_status("Docker Compose not found", "ERROR")
            return False
        self.print_status(f"Docker Compose found: {stdout.strip()}")
        
        # Check Docker daemon
        success, stdout, stderr = self.run_command("docker info")
        if not success:
            self.print_status("Docker daemon not running", "ERROR")
            return False
        self.print_status("Docker daemon is running")
        
        return True
        
    def test_nginx_files(self):
        """Test Nginx configuration files"""
        self.print_status("Testing Nginx configuration files...")
        
        required_files = [
            "docker-compose.yml",
            "config/nginx.conf",
            "config/conf.d/app.soject.com.conf",
            "config/conf.d/admin.soject.com.conf",
            "config/conf.d/docker.soject.com.conf",
            "config/conf.d/gitlab.soject.com.conf",
            "config/conf.d/mail.soject.com.conf",
            "config/conf.d/default.conf"
        ]
        
        missing_files = []
        for file_path in required_files:
            full_path = self.nginx_path / file_path
            if not full_path.exists():
                missing_files.append(file_path)
            else:
                self.print_status(f"✓ {file_path}")
                
        if missing_files:
            self.print_status(f"Missing files: {missing_files}", "ERROR")
            return False
            
        return True
        
    def test_ssl_certificates(self):
        """Test SSL certificates"""
        self.print_status("Testing SSL certificates...")
        
        ssl_dir = self.nginx_path / "ssl"
        if not ssl_dir.exists():
            self.print_status("SSL directory not found", "ERROR")
            return False
            
        required_certs = [
            "app.soject.com.crt",
            "app.soject.com.key",
            "admin.soject.com.crt", 
            "admin.soject.com.key",
            "docker.soject.com.crt",
            "docker.soject.com.key",
            "gitlab.soject.com.crt",
            "gitlab.soject.com.key",
            "mail.soject.com.crt",
            "mail.soject.com.key",
            "default.crt",
            "default.key"
        ]
        
        missing_certs = []
        for cert_file in required_certs:
            cert_path = ssl_dir / cert_file
            if not cert_path.exists():
                missing_certs.append(cert_file)
            else:
                self.print_status(f"✓ {cert_file}")
                
        if missing_certs:
            self.print_status(f"Missing certificates: {missing_certs}", "WARNING")
            self.print_status("Run setup_nginx.sh to generate certificates", "INFO")
            return False
            
        return True
        
    def test_docker_networks(self):
        """Test Docker networks"""
        self.print_status("Testing Docker networks...")
        
        required_networks = [
            "web_network",
            "mail_network", 
            "gitlab_network",
            "portainer_network"
        ]
        
        success, stdout, stderr = self.run_command("docker network ls --format '{{.Name}}'")
        if not success:
            self.print_status("Failed to list Docker networks", "ERROR")
            return False
            
        existing_networks = stdout.strip().split('\n')
        missing_networks = []
        
        for network in required_networks:
            if network in existing_networks:
                self.print_status(f"✓ Network {network} exists")
            else:
                missing_networks.append(network)
                
        if missing_networks:
            self.print_status(f"Missing networks: {missing_networks}", "WARNING")
            self.print_status("Networks will be created when starting services", "INFO")
            
        return True
        
    def test_docker_compose_config(self):
        """Test Docker Compose configuration"""
        self.print_status("Testing Docker Compose configuration...")
        
        success, stdout, stderr = self.run_command(
            "docker-compose config", 
            cwd=self.nginx_path
        )
        
        if not success:
            self.print_status("Docker Compose configuration is invalid", "ERROR")
            self.print_status(f"Error: {stderr}", "ERROR")
            return False
            
        self.print_status("Docker Compose configuration is valid")
        return True
        
    def test_hosts_file(self):
        """Test hosts file entries"""
        self.print_status("Testing hosts file entries...")
        
        if sys.platform == "win32":
            hosts_file = r"C:\Windows\System32\drivers\etc\hosts"
        else:
            hosts_file = "/etc/hosts"
            
        try:
            with open(hosts_file, 'r') as f:
                hosts_content = f.read()
                
            missing_domains = []
            for domain in self.domains:
                if domain in hosts_content:
                    self.print_status(f"✓ {domain} in hosts file")
                else:
                    missing_domains.append(domain)
                    
            if missing_domains:
                self.print_status(f"Missing domains in hosts file: {missing_domains}", "WARNING")
                self.print_status("Run add_to_hosts.sh to add domains", "INFO")
                return False
                
        except PermissionError:
            self.print_status("Cannot read hosts file (permission denied)", "WARNING")
            self.print_status("Run as administrator/sudo to check hosts file", "INFO")
            return False
        except FileNotFoundError:
            self.print_status("Hosts file not found", "ERROR")
            return False
            
        return True
        
    def test_nginx_container(self):
        """Test Nginx container"""
        self.print_status("Testing Nginx container...")
        
        # Check if container is running
        success, stdout, stderr = self.run_command(
            "docker ps --filter 'name=nginx-proxy' --format '{{.Names}}'",
            cwd=self.nginx_path
        )
        
        if not success or "nginx-proxy" not in stdout:
            self.print_status("Nginx container is not running", "WARNING")
            self.print_status("Start Nginx with: ./start_nginx.sh", "INFO")
            return False
            
        self.print_status("✓ Nginx container is running")
        
        # Test Nginx configuration
        success, stdout, stderr = self.run_command(
            "docker exec nginx-proxy nginx -t",
            cwd=self.nginx_path
        )
        
        if not success:
            self.print_status("Nginx configuration test failed", "ERROR")
            self.print_status(f"Error: {stderr}", "ERROR")
            return False
            
        self.print_status("✓ Nginx configuration is valid")
        return True
        
    def test_domain_access(self):
        """Test domain access"""
        self.print_status("Testing domain access...")
        
        # Wait for services to be ready
        time.sleep(5)
        
        test_urls = [
            ("https://app.soject.com/health", "Web App Health"),
            ("https://admin.soject.com", "phpMyAdmin"),
            ("https://docker.soject.com", "Portainer"),
            ("https://gitlab.soject.com", "GitLab"),
            ("https://mail.soject.com", "Roundcube")
        ]
        
        for url, service_name in test_urls:
            try:
                response = requests.get(url, verify=False, timeout=10)
                if response.status_code == 200:
                    self.print_status(f"✓ {service_name} accessible at {url}")
                    self.test_results[service_name] = "SUCCESS"
                else:
                    self.print_status(f"✗ {service_name} returned status {response.status_code}", "WARNING")
                    self.test_results[service_name] = f"HTTP {response.status_code}"
            except requests.exceptions.RequestException as e:
                self.print_status(f"✗ {service_name} not accessible: {e}", "WARNING")
                self.test_results[service_name] = f"ERROR: {e}"
                
        return True
        
    def generate_report(self):
        """Generate test report"""
        self.print_status("Generating test report...")
        
        report = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "platform": sys.platform,
            "test_results": self.test_results,
            "recommendations": []
        }
        
        # Analyze results and provide recommendations
        if not self.test_results.get("Web App Health") == "SUCCESS":
            report["recommendations"].append("Start web application service")
            
        if not self.test_results.get("phpMyAdmin") == "SUCCESS":
            report["recommendations"].append("Start MySQL database service")
            
        if not self.test_results.get("Portainer") == "SUCCESS":
            report["recommendations"].append("Start Portainer service")
            
        if not self.test_results.get("GitLab") == "SUCCESS":
            report["recommendations"].append("Start GitLab service")
            
        if not self.test_results.get("Roundcube") == "SUCCESS":
            report["recommendations"].append("Start mail server service")
            
        # Save report
        report_file = self.base_path / "nginx_test_report.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
            
        self.print_status(f"Test report saved to: {report_file}")
        
        # Print summary
        self.print_status("=== Test Summary ===", "INFO")
        for service, result in self.test_results.items():
            status_color = "SUCCESS" if result == "SUCCESS" else "WARNING"
            self.print_status(f"{service}: {result}", status_color)
            
        if report["recommendations"]:
            self.print_status("=== Recommendations ===", "INFO")
            for rec in report["recommendations"]:
                self.print_status(f"- {rec}", "INFO")
                
    def run_all_tests(self):
        """Run all tests"""
        self.print_status("Starting Nginx setup tests...", "INFO")
        
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
            try:
                self.print_status(f"\n--- {test_name} ---", "INFO")
                result = test_func()
                results[test_name] = "PASS" if result else "FAIL"
            except Exception as e:
                self.print_status(f"Test {test_name} failed with exception: {e}", "ERROR")
                results[test_name] = "ERROR"
                
        # Print final results
        self.print_status("\n=== Final Results ===", "INFO")
        for test_name, result in results.items():
            status_color = "SUCCESS" if result == "PASS" else "ERROR"
            self.print_status(f"{test_name}: {result}", status_color)
            
        # Generate report
        self.generate_report()
        
        return all(result == "PASS" for result in results.values())

def main():
    """Main function"""
    tester = NginxTester()
    
    try:
        success = tester.run_all_tests()
        if success:
            tester.print_status("\nAll tests passed! Nginx setup is working correctly.", "SUCCESS")
            sys.exit(0)
        else:
            tester.print_status("\nSome tests failed. Check the recommendations above.", "WARNING")
            sys.exit(1)
    except KeyboardInterrupt:
        tester.print_status("\nTests interrupted by user.", "WARNING")
        sys.exit(1)
    except Exception as e:
        tester.print_status(f"\nUnexpected error: {e}", "ERROR")
        sys.exit(1)

if __name__ == "__main__":
    main() 