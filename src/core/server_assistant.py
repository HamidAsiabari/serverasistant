"""
Main ServerAssistant application class
"""

import os
import sys
from pathlib import Path
from typing import Dict, List, Optional
from .config_manager import ConfigManager, ServiceConfig
from .docker_manager import DockerManager, ServiceStatus


class ServerAssistant:
    """Main ServerAssistant application class"""
    
    def __init__(self, config_path: str = "config.json"):
        self.base_path = Path(__file__).parent.parent.parent
        self.config_manager = ConfigManager(config_path)
        self.docker_manager = DockerManager(self.base_path)
        self.running = True
        
        # Colors for terminal output
        self.colors = {
            'red': '\033[91m',
            'green': '\033[92m',
            'yellow': '\033[93m',
            'blue': '\033[94m',
            'purple': '\033[95m',
            'cyan': '\033[96m',
            'white': '\033[97m',
            'bold': '\033[1m',
            'underline': '\033[4m',
            'reset': '\033[0m'
        }
        
        # Initialize
        self._load_configuration()
        
    def _load_configuration(self):
        """Load and validate configuration"""
        if not self.config_manager.load_config():
            self.print_error("Failed to load configuration")
            return
            
        # Set services in Docker manager
        self.docker_manager.set_services(self.config_manager.get_all_services())
        
        # Validate configuration
        errors = self.config_manager.validate_config()
        if errors:
            self.print_error("Configuration validation failed:")
            for error in errors:
                self.print_error(f"  - {error}")
            return
            
        self.print_success(f"Configuration loaded: {self.config_manager.config.server_name}")
        
    def print_color(self, text: str, color: str = 'white', bold: bool = False):
        """Print colored text"""
        color_code = self.colors.get(color, '')
        bold_code = self.colors['bold'] if bold else ''
        print(f"{bold_code}{color_code}{text}{self.colors['reset']}")
        
    def print_header(self, text: str):
        """Print header with decoration"""
        print("\n" + "="*60)
        self.print_color(f"  {text}", 'cyan', bold=True)
        print("="*60)
        
    def print_success(self, text: str):
        """Print success message"""
        self.print_color(f"✓ {text}", 'green')
        
    def print_error(self, text: str):
        """Print error message"""
        self.print_color(f"✗ {text}", 'red')
        
    def print_warning(self, text: str):
        """Print warning message"""
        self.print_color(f"⚠ {text}", 'yellow')
        
    def print_info(self, text: str):
        """Print info message"""
        self.print_color(f"ℹ {text}", 'blue')
        
    def check_docker_environment(self) -> bool:
        """Check Docker environment"""
        self.print_info("Checking Docker environment...")
        
        if not self.docker_manager.check_docker_environment():
            self.print_error("Docker environment check failed")
            return False
            
        self.print_success("Docker environment is ready")
        return True
        
    def start_service(self, service_name: str) -> bool:
        """Start a specific service"""
        self.print_info(f"Starting service: {service_name}")
        
        if not self.check_docker_environment():
            return False
            
        # Ensure required networks exist before starting service
        self.print_info("Ensuring required networks exist...")
        if not self.docker_manager.ensure_networks_exist():
            self.print_error("Failed to create required networks")
            return False
            
        if self.docker_manager.start_service(service_name):
            self.print_success(f"Service '{service_name}' started successfully")
            return True
        else:
            self.print_error(f"Failed to start service '{service_name}'")
            return False
            
    def stop_service(self, service_name: str) -> bool:
        """Stop a specific service"""
        self.print_info(f"Stopping service: {service_name}")
        
        if self.docker_manager.stop_service(service_name):
            self.print_success(f"Service '{service_name}' stopped successfully")
            return True
        else:
            self.print_error(f"Failed to stop service '{service_name}'")
            return False
            
    def restart_service(self, service_name: str) -> bool:
        """Restart a specific service"""
        self.print_info(f"Restarting service: {service_name}")
        
        if self.docker_manager.restart_service(service_name):
            self.print_success(f"Service '{service_name}' restarted successfully")
            return True
        else:
            self.print_error(f"Failed to restart service '{service_name}'")
            return False
            
    def get_service_status(self, service_name: str) -> Optional[ServiceStatus]:
        """Get status of a specific service"""
        return self.docker_manager.get_service_status(service_name)
        
    def get_all_service_status(self) -> List[ServiceStatus]:
        """Get status of all services"""
        return self.docker_manager.get_all_service_status()
        
    def start_all_services(self) -> Dict[str, bool]:
        """Start all enabled services"""
        self.print_info("Starting all enabled services...")
        
        if not self.check_docker_environment():
            return {}
            
        # Ensure required networks exist before starting services
        self.print_info("Ensuring required networks exist...")
        if not self.docker_manager.ensure_networks_exist():
            self.print_error("Failed to create required networks")
            return {}
            
        results = self.docker_manager.start_all_services()
        
        self.print_info("Results:")
        for service_name, success in results.items():
            if success:
                self.print_success(f"  {service_name}: Started")
            else:
                self.print_error(f"  {service_name}: Failed")
                
        return results
        
    def stop_all_services(self) -> Dict[str, bool]:
        """Stop all services"""
        self.print_info("Stopping all services...")
        
        results = self.docker_manager.stop_all_services()
        
        self.print_info("Results:")
        for service_name, success in results.items():
            if success:
                self.print_success(f"  {service_name}: Stopped")
            else:
                self.print_error(f"  {service_name}: Failed")
                
        return results
        
    def get_service_logs(self, service_name: str, follow: bool = False) -> str:
        """Get logs for a specific service"""
        return self.docker_manager.get_service_logs(service_name, follow)
        
    def health_check_service(self, service_name: str) -> bool:
        """Perform health check on a service"""
        self.print_info(f"Performing health check on {service_name}")
        
        if self.docker_manager.health_check_service(service_name):
            self.print_success(f"Health check passed for {service_name}")
            return True
        else:
            self.print_error(f"Health check failed for {service_name}")
            return False
            
    def get_configuration(self):
        """Get current configuration"""
        return self.config_manager.config
        
    def get_services(self) -> Dict[str, ServiceConfig]:
        """Get all services"""
        return self.config_manager.get_all_services()
        
    def get_enabled_services(self) -> Dict[str, ServiceConfig]:
        """Get enabled services only"""
        return self.config_manager.get_enabled_services()
        
    def update_service_config(self, service_name: str, **kwargs) -> bool:
        """Update service configuration"""
        if self.config_manager.update_service(service_name, **kwargs):
            self.print_success(f"Service '{service_name}' configuration updated")
            # Reload services in Docker manager
            self.docker_manager.set_services(self.config_manager.get_all_services())
            return True
        else:
            self.print_error(f"Failed to update service '{service_name}' configuration")
            return False 