"""
Docker management for ServerAssistant
"""

import subprocess
import json
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from .config_manager import ServiceConfig


@dataclass
class ServiceStatus:
    """Service status information"""
    name: str
    status: str
    container_id: Optional[str] = None
    port: Optional[str] = None
    health: Optional[str] = None
    uptime: Optional[str] = None
    memory_usage: Optional[str] = None
    cpu_usage: Optional[float] = None


class DockerManager:
    """Manages Docker services"""
    
    def __init__(self, base_path: Path):
        self.base_path = base_path
        self.services: Dict[str, ServiceConfig] = {}
        
    def set_services(self, services: Dict[str, ServiceConfig]):
        """Set services configuration"""
        self.services = services
        
    def run_command(self, command: str, cwd: Optional[Path] = None, 
                   check: bool = True) -> Tuple[bool, str, str]:
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
            
    def check_docker_environment(self) -> bool:
        """Check if Docker environment is available"""
        # Check Docker
        success, stdout, stderr = self.run_command("docker --version")
        if not success:
            return False
            
        # Check Docker Compose
        success, stdout, stderr = self.run_command("docker-compose --version")
        if not success:
            return False
            
        # Check Docker daemon
        success, stdout, stderr = self.run_command("docker info")
        return success
        
    def start_service(self, service_name: str) -> bool:
        """Start a specific service"""
        service = self.services.get(service_name)
        if not service:
            return False
            
        service_path = self.base_path / service.path
        if not service_path.exists():
            return False
            
        success, stdout, stderr = self.run_command(
            "docker-compose up -d",
            cwd=service_path
        )
        
        return success
        
    def stop_service(self, service_name: str) -> bool:
        """Stop a specific service"""
        service = self.services.get(service_name)
        if not service:
            return False
            
        service_path = self.base_path / service.path
        if not service_path.exists():
            return False
            
        success, stdout, stderr = self.run_command(
            "docker-compose down",
            cwd=service_path
        )
        
        return success
        
    def restart_service(self, service_name: str) -> bool:
        """Restart a specific service"""
        if self.stop_service(service_name):
            time.sleep(2)  # Give time for graceful shutdown
            return self.start_service(service_name)
        return False
        
    def get_service_status(self, service_name: str) -> Optional[ServiceStatus]:
        """Get status of a specific service"""
        service = self.services.get(service_name)
        if not service:
            return None
            
        service_path = self.base_path / service.path
        if not service_path.exists():
            return ServiceStatus(name=service_name, status="not_found")
            
        # Get container status
        success, stdout, stderr = self.run_command(
            "docker-compose ps --format json",
            cwd=service_path
        )
        
        if not success or not stdout.strip():
            return ServiceStatus(name=service_name, status="stopped")
            
        try:
            containers = json.loads(stdout)
            if isinstance(containers, dict):
                containers = [containers]
                
            for container in containers:
                if container.get('Service') == service_name:
                    return ServiceStatus(
                        name=service_name,
                        status=container.get('State', 'unknown'),
                        container_id=container.get('ID'),
                        port=container.get('Ports'),
                        health=container.get('Health', 'unknown')
                    )
                    
        except json.JSONDecodeError:
            pass
            
        return ServiceStatus(name=service_name, status="unknown")
        
    def get_all_service_status(self) -> List[ServiceStatus]:
        """Get status of all services"""
        statuses = []
        for service_name in self.services:
            status = self.get_service_status(service_name)
            if status:
                statuses.append(status)
        return statuses
        
    def start_all_services(self) -> Dict[str, bool]:
        """Start all enabled services"""
        results = {}
        for service_name, service in self.services.items():
            if service.enabled:
                results[service_name] = self.start_service(service_name)
        return results
        
    def stop_all_services(self) -> Dict[str, bool]:
        """Stop all services"""
        results = {}
        for service_name in self.services:
            results[service_name] = self.stop_service(service_name)
        return results
        
    def get_service_logs(self, service_name: str, follow: bool = False) -> str:
        """Get logs for a specific service"""
        service = self.services.get(service_name)
        if not service:
            return f"Error: Service '{service_name}' not found in configuration"
            
        service_path = self.base_path / service.path
        if not service_path.exists():
            return f"Error: Service path '{service_path}' does not exist"
            
        # First check if the service is running
        status = self.get_service_status(service_name)
        if not status or status.status not in ["running", "up"]:
            return f"Service '{service_name}' is not running (status: {status.status if status else 'unknown'})\n\nTo see logs, start the service first."
            
        command = "docker-compose logs"
        if follow:
            command += " -f"
        command += f" {service_name}"
        
        success, stdout, stderr = self.run_command(command, cwd=service_path)
        
        if not success:
            if stderr:
                return f"Error getting logs for '{service_name}': {stderr}"
            else:
                return f"Error getting logs for '{service_name}': Unknown error"
        
        if not stdout.strip():
            return f"No logs available for service '{service_name}'\n\nThis could mean:\n- The service just started and hasn't generated logs yet\n- The service is running but not producing output\n- Check if the service is configured to log to stdout/stderr"
        
        return stdout
        
    def health_check_service(self, service_name: str) -> bool:
        """Perform health check on a service"""
        service = self.services.get(service_name)
        if not service or not service.health_check:
            return False
            
        service_path = self.base_path / service.path
        if not service_path.exists():
            return False
            
        success, stdout, stderr = self.run_command(
            service.health_check,
            cwd=service_path
        )
        
        return success 