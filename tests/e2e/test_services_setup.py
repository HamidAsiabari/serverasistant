#!/usr/bin/env python3
"""
Services Setup Test Script
Tests the complete services setup and configuration
"""

import sys
import json
import subprocess
import time
from pathlib import Path
from typing import Tuple, Dict, Any

class ServicesSetupTester:
    """Test class for services setup and configuration."""
    
    def __init__(self):
        self.base_path = Path(__file__).parent.parent.parent
        self.test_results = {}
        
    def print_status(self, message: str, status: str = "INFO"):
        """Print status message with formatting."""
        status_colors = {
            "INFO": "\033[94m",    # Blue
            "SUCCESS": "\033[92m", # Green
            "WARNING": "\033[93m", # Yellow
            "ERROR": "\033[91m"    # Red
        }
        color = status_colors.get(status, "\033[0m")
        reset = "\033[0m"
        print(f"{color}[{status}]{reset} {message}")
    
    def run_command(self, command: str, cwd: Path = None) -> Tuple[bool, str, str]:
        """Run a command and return success, stdout, stderr."""
        try:
            if cwd:
                result = subprocess.run(
                    command, 
                    shell=True, 
                    capture_output=True, 
                    text=True, 
                    cwd=cwd
                )
            else:
                result = subprocess.run(
                    command, 
                    shell=True, 
                    capture_output=True, 
                    text=True
                )
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, "", str(e)
    
    def test_config_file(self) -> bool:
        """Test that the configuration file exists and is valid."""
        self.print_status("Testing configuration file...", "INFO")
        
        config_file = self.base_path / "config.json"
        if not config_file.exists():
            self.print_status("Configuration file not found", "ERROR")
            return False
        
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
            
            if 'services' not in config:
                self.print_status("No services section in configuration", "ERROR")
                return False
            
            self.print_status(f"Configuration loaded with {len(config['services'])} services", "SUCCESS")
            return True
            
        except json.JSONDecodeError as e:
            self.print_status(f"Invalid JSON in configuration: {e}", "ERROR")
            return False
        except Exception as e:
            self.print_status(f"Error reading configuration: {e}", "ERROR")
            return False
    
    def test_service_directories(self) -> bool:
        """Test that service directories exist."""
        self.print_status("Testing service directories...", "INFO")
        
        service_dirs = [
            "docker_services/web-app",
            "docker_services/mysql", 
            "docker_services/database",
            "docker_services/portainer",
            "docker_services/gitlab",
            "docker_services/mail-server"
        ]
        
        all_exist = True
        for service_dir in service_dirs:
            dir_path = self.base_path / service_dir
            if dir_path.exists():
                self.print_status(f"✅ {service_dir} exists", "SUCCESS")
                
                # Check for docker-compose.yml
                compose_file = dir_path / "docker-compose.yml"
                if compose_file.exists():
                    self.print_status(f"  ✅ docker-compose.yml found", "SUCCESS")
                else:
                    self.print_status(f"  ❌ docker-compose.yml missing", "ERROR")
                    all_exist = False
            else:
                self.print_status(f"❌ {service_dir} missing", "ERROR")
                all_exist = False
        
        return all_exist
    
    def test_docker_networks(self) -> bool:
        """Test Docker networks."""
        self.print_status("Testing Docker networks...", "INFO")
        
        # Check if required networks exist
        success, stdout, stderr = self.run_command("docker network ls --format '{{.Name}}' | grep -E '^(serverassistant|default)$'")
        
        if success and "serverassistant" in stdout:
            self.print_status("✅ ServerAssistant network exists", "SUCCESS")
            return True
        else:
            self.print_status("⚠ ServerAssistant network not found (will be created)", "WARNING")
            return True
    
    def test_docker_compose_configs(self) -> bool:
        """Test Docker Compose configurations."""
        self.print_status("Testing Docker Compose configurations...", "INFO")
        
        service_dirs = [
            "docker_services/web-app",
            "docker_services/mysql",
            "docker_services/database", 
            "docker_services/portainer",
            "docker_services/gitlab",
            "docker_services/mail-server"
        ]
        
        all_valid = True
        for service_dir in service_dirs:
            dir_path = self.base_path / service_dir
            compose_file = dir_path / "docker-compose.yml"
            
            if compose_file.exists():
                success, stdout, stderr = self.run_command("docker-compose config", cwd=dir_path)
                if success:
                    self.print_status(f"✅ {service_dir} config valid", "SUCCESS")
                else:
                    self.print_status(f"❌ {service_dir} config invalid: {stderr}", "ERROR")
                    all_valid = False
            else:
                self.print_status(f"⚠ {service_dir} no compose file", "WARNING")
        
        return all_valid
    
    def test_services_startup(self) -> bool:
        """Test services startup (without actually starting them)."""
        self.print_status("Testing services startup configuration...", "INFO")
        
        # Test that we can validate the configuration
        success, stdout, stderr = self.run_command("python -c \"import sys; sys.path.append('src'); from core.config_manager import ConfigManager; cm = ConfigManager(); print('Config loaded successfully')\"", cwd=self.base_path)
        
        if success:
            self.print_status("✅ Configuration manager loads successfully", "SUCCESS")
            return True
        else:
            self.print_status(f"❌ Configuration manager error: {stderr}", "ERROR")
            return False
    
    def cleanup_test_containers(self):
        """Clean up any test containers."""
        self.print_status("Cleaning up test containers...", "INFO")
        
        # Stop and remove any test containers
        services = ["web-app", "mysql", "postgres", "redis", "portainer", "gitlab", "mail-server"]
        
        for service in services:
            self.run_command(f"docker-compose down", cwd=self.base_path / f"docker_services/{service}")
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate test report."""
        report = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "base_path": str(self.base_path),
            "test_results": self.test_results,
            "summary": {
                "total_tests": len(self.test_results),
                "passed": sum(1 for result in self.test_results.values() if result),
                "failed": sum(1 for result in self.test_results.values() if not result)
            }
        }
        
        return report
    
    def save_report(self, report: Dict[str, Any]):
        """Save test report to file."""
        report_file = self.base_path / "services_test_report.json"
        try:
            with open(report_file, 'w') as f:
                json.dump(report, f, indent=2)
            self.print_status(f"Test report saved to {report_file}", "SUCCESS")
        except Exception as e:
            self.print_status(f"Failed to save report: {e}", "ERROR")
    
    def run_all_tests(self) -> bool:
        """Run all services setup tests."""
        self.print_status("Starting Services Setup Tests", "INFO")
        
        # Run tests
        tests = [
            ("Configuration File", self.test_config_file),
            ("Service Directories", self.test_service_directories),
            ("Docker Networks", self.test_docker_networks),
            ("Docker Compose Configs", self.test_docker_compose_configs),
            ("Services Startup", self.test_services_startup)
        ]
        
        all_passed = True
        for test_name, test_func in tests:
            self.print_status(f"\nRunning {test_name} test...", "INFO")
            try:
                result = test_func()
                self.test_results[test_name] = result
                if result:
                    self.print_status(f"✅ {test_name} passed", "SUCCESS")
                else:
                    self.print_status(f"❌ {test_name} failed", "ERROR")
                    all_passed = False
            except Exception as e:
                self.print_status(f"❌ {test_name} failed with exception: {e}", "ERROR")
                self.test_results[test_name] = False
                all_passed = False
        
        # Cleanup
        self.cleanup_test_containers()
        
        # Generate and save report
        report = self.generate_report()
        self.save_report(report)
        
        # Print summary
        self.print_status("\n" + "="*50, "INFO")
        self.print_status("Services Setup Test Summary", "INFO")
        self.print_status("="*50, "INFO")
        
        for test_name, result in self.test_results.items():
            status = "✅ PASSED" if result else "❌ FAILED"
            self.print_status(f"{test_name}: {status}", "SUCCESS" if result else "ERROR")
        
        self.print_status(f"\nTotal: {report['summary']['passed']}/{report['summary']['total_tests']} tests passed", "INFO")
        
        if all_passed:
            self.print_status("🎉 All services setup tests passed!", "SUCCESS")
        else:
            self.print_status("❌ Some services setup tests failed!", "ERROR")
        
        return all_passed

def main():
    """Main function to run services setup tests."""
    tester = ServicesSetupTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 