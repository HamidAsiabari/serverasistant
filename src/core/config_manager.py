"""
Configuration management for ServerAssistant
"""

import json
import os
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass, asdict


@dataclass
class ServiceConfig:
    """Service configuration data class"""
    name: str
    enabled: bool
    path: str
    port: Optional[int] = None
    health_check: Optional[str] = None
    depends_on: Optional[list] = None


@dataclass
class ServerConfig:
    """Server configuration data class"""
    server_name: str
    environment: str
    services: list[ServiceConfig]
    backup_path: str
    log_level: str = "INFO"


class ConfigManager:
    """Manages application configuration"""
    
    def __init__(self, config_path: str = "config.json"):
        self.config_path = Path(config_path)
        self.config: Optional[ServerConfig] = None
        self.services: Dict[str, ServiceConfig] = {}
        
    def load_config(self) -> bool:
        """Load configuration from file"""
        try:
            if not self.config_path.exists():
                return False
                
            with open(self.config_path, 'r') as f:
                data = json.load(f)
                
            # Convert services to ServiceConfig objects
            services = []
            for service_data in data.get('services', []):
                service = ServiceConfig(**service_data)
                services.append(service)
                self.services[service.name] = service
                
            self.config = ServerConfig(
                server_name=data.get('server_name', 'Unknown'),
                environment=data.get('environment', 'production'),
                services=services,
                backup_path=data.get('backup_path', './backups'),
                log_level=data.get('log_level', 'INFO')
            )
            
            return True
            
        except Exception as e:
            print(f"Error loading configuration: {e}")
            return False
    
    def save_config(self) -> bool:
        """Save configuration to file"""
        try:
            if not self.config:
                return False
                
            data = asdict(self.config)
            with open(self.config_path, 'w') as f:
                json.dump(data, f, indent=2)
                
            return True
            
        except Exception as e:
            print(f"Error saving configuration: {e}")
            return False
    
    def get_service(self, name: str) -> Optional[ServiceConfig]:
        """Get service configuration by name"""
        return self.services.get(name)
    
    def get_all_services(self) -> Dict[str, ServiceConfig]:
        """Get all service configurations"""
        return self.services.copy()
    
    def get_enabled_services(self) -> Dict[str, ServiceConfig]:
        """Get only enabled services"""
        return {name: service for name, service in self.services.items() 
                if service.enabled}
    
    def update_service(self, name: str, **kwargs) -> bool:
        """Update service configuration"""
        if name not in self.services:
            return False
            
        service = self.services[name]
        for key, value in kwargs.items():
            if hasattr(service, key):
                setattr(service, key, value)
                
        return self.save_config()
    
    def validate_config(self) -> list[str]:
        """Validate configuration and return list of errors"""
        errors = []
        
        if not self.config:
            errors.append("No configuration loaded")
            return errors
            
        # Check required fields
        if not self.config.server_name:
            errors.append("Server name is required")
            
        if not self.config.services:
            errors.append("At least one service must be configured")
            
        # Check service configurations
        for service in self.config.services:
            if not service.name:
                errors.append(f"Service name is required")
            if not service.path:
                errors.append(f"Service path is required for {service.name}")
            if service.port and (service.port < 1 or service.port > 65535):
                errors.append(f"Invalid port {service.port} for service {service.name}")
                
        return errors 