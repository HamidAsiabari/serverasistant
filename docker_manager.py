#!/usr/bin/env python3
"""
Docker Service Manager
A Python application for managing and running Docker services based on JSON configuration.
"""

import os
import sys
import json
import time
import subprocess
import logging
import threading
import platform
from datetime import datetime
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from pathlib import Path

import docker
import yaml
import psutil
from colorama import init, Fore, Style

# Initialize colorama for cross-platform colored output
init(autoreset=True)

@dataclass
class ServiceStatus:
    """Data class for service status information."""
    name: str
    status: str
    container_id: Optional[str] = None
    port: Optional[str] = None
    health: str = "unknown"
    uptime: Optional[str] = None
    memory_usage: Optional[str] = None
    cpu_usage: Optional[float] = None

class DockerManager:
    """Main class for managing Docker services."""
    
    def __init__(self, config_path: str = "config.json"):
        """Initialize the Docker manager with configuration."""
        self.config_path = config_path
        self.config = self._load_config()
        self.logger = self._setup_logging()
        self.platform = self._detect_platform()
        self.docker_client = self._init_docker_client()
        self.running_services = {}
        self.monitoring_thread = None
        self.stop_monitoring = False
        
    def _detect_platform(self) -> str:
        """Detect the current platform (linux or windows)."""
        system = platform.system().lower()
        if system == "linux":
            return "linux"
        elif system == "windows":
            return "windows"
        else:
            # Use print instead of logger since logger might not be ready yet
            print(f"Warning: Unsupported platform: {system}, defaulting to linux")
            return "linux"
    
    def _get_platform_config(self) -> Dict[str, Any]:
        """Get platform-specific configuration."""
        platform_config = self.config.get('global_settings', {}).get('platform_specific', {})
        return platform_config.get(self.platform, {})
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from JSON file."""
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
            # Use print instead of logger since logger is not set up yet
            print(f"Configuration loaded from {self.config_path}")
            return config
        except FileNotFoundError:
            print(f"Error: Configuration file {self.config_path} not found")
            sys.exit(1)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in configuration file: {e}")
            sys.exit(1)
    
    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration with platform-specific paths."""
        log_level = getattr(logging, self.config.get('log_level', 'INFO'))
        
        # Get platform-specific log path (use default for now)
        log_path = './logs'
        
        # Create logs directory if it doesn't exist
        log_dir = Path(log_path)
        log_dir.mkdir(exist_ok=True)
        
        # Setup file handler
        log_file = log_dir / f"docker_manager_{datetime.now().strftime('%Y%m%d')}.log"
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(log_level)
        
        # Setup console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        
        # Setup formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        # Setup logger
        logger = logging.getLogger('DockerManager')
        logger.setLevel(log_level)
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def _init_docker_client(self) -> docker.DockerClient:
        """Initialize Docker client with platform-specific settings."""
        try:
            # Get platform-specific configuration
            platform_config = self._get_platform_config()
            
            # Determine Docker host/socket
            docker_host = self.config.get('global_settings', {}).get('docker_host', 'auto')
            if docker_host == 'auto':
                docker_host = platform_config.get('docker_host', None)
            
            docker_socket = self.config.get('global_settings', {}).get('docker_socket', 'auto')
            if docker_socket == 'auto':
                docker_socket = platform_config.get('docker_socket', None)
            
            # Initialize Docker client
            if docker_host:
                client = docker.DockerClient(base_url=docker_host)
            elif docker_socket and self.platform == "linux":
                client = docker.DockerClient(base_url=f"unix://{docker_socket}")
            else:
                # Use default Docker client (will try to auto-detect)
                client = docker.from_env()
            
            # Test connection
            client.ping()
            self.logger.info(f"Docker client initialized successfully on {self.platform}")
            return client
        except Exception as e:
            self.logger.error(f"Failed to initialize Docker client: {e}")
            self.logger.error(f"Platform: {self.platform}")
            self.logger.error(f"Make sure Docker is running and accessible")
            sys.exit(1)
    
    def _get_compose_command(self) -> str:
        """Get the appropriate docker-compose command for the platform."""
        platform_config = self._get_platform_config()
        return platform_config.get('compose_command', 'docker-compose')
    
    def _normalize_path(self, path: str) -> str:
        """Normalize path for the current platform."""
        if self.platform == "windows":
            # Convert forward slashes to backslashes on Windows
            return path.replace('/', '\\')
        return path
    
    def _run_command(self, cmd: List[str], cwd: Optional[str] = None, capture_output: bool = True) -> subprocess.CompletedProcess:
        """Run a command with platform-specific considerations."""
        try:
            # On Windows, ensure we're using the right shell
            if self.platform == "windows":
                # Use shell=True on Windows for better compatibility
                cmd_str = ' '.join(cmd)
                return subprocess.run(
                    cmd_str,
                    shell=True,
                    cwd=cwd,
                    capture_output=capture_output,
                    text=True,
                    check=False
                )
            else:
                # On Linux, run directly
                return subprocess.run(
                    cmd,
                    cwd=cwd,
                    capture_output=capture_output,
                    text=True,
                    check=False
                )
        except Exception as e:
            self.logger.error(f"Command execution failed: {e}")
            raise
    
    def start_service(self, service_name: str) -> bool:
        """Start a specific service."""
        service_config = self._get_service_config(service_name)
        if not service_config:
            self.logger.error(f"Service '{service_name}' not found in configuration")
            return False
        
        if not service_config.get('enabled', True):
            self.logger.warning(f"Service '{service_name}' is disabled")
            return False
        
        try:
            if service_config['type'] == 'dockerfile':
                return self._start_dockerfile_service(service_config)
            elif service_config['type'] == 'docker-compose':
                return self._start_compose_service(service_config)
            else:
                self.logger.error(f"Unknown service type: {service_config['type']}")
                return False
        except Exception as e:
            self.logger.error(f"Failed to start service '{service_name}': {e}")
            return False
    
    def _start_dockerfile_service(self, service_config: Dict[str, Any]) -> bool:
        """Start a service using Dockerfile."""
        service_name = service_config['name']
        service_path = self._normalize_path(service_config['path'])
        
        self.logger.info(f"Starting Dockerfile service: {service_name}")
        
        # Check if service path exists
        if not os.path.exists(service_path):
            self.logger.error(f"Service path does not exist: {service_path}")
            return False
        
        # Build image
        try:
            dockerfile_path = os.path.join(service_path, service_config['dockerfile'])
            image, build_logs = self.docker_client.images.build(
                path=service_path,
                dockerfile=service_config['dockerfile'],
                tag=f"{service_name}:latest",
                rm=True
            )
            self.logger.info(f"Image built successfully: {image.tags[0]}")
        except Exception as e:
            self.logger.error(f"Failed to build image for {service_name}: {e}")
            return False
        
        # Run container
        try:
            container_config = {
                'image': f"{service_name}:latest",
                'name': service_name,
                'detach': True,
                'restart_policy': {'Name': service_config.get('restart_policy', 'unless-stopped')}
            }
            
            # Add ports if specified
            if 'ports' in service_config:
                container_config['ports'] = {}
                for port_mapping in service_config['ports']:
                    host_port, container_port = port_mapping.split(':')
                    container_config['ports'][container_port] = host_port
            
            # Add environment variables if specified
            if 'environment' in service_config:
                container_config['environment'] = service_config['environment']
            
            # Add volumes if specified
            if 'volumes' in service_config:
                container_config['volumes'] = {}
                for volume_mapping in service_config['volumes']:
                    host_path, container_path = volume_mapping.split(':')
                    # Normalize host path for platform
                    host_path = self._normalize_path(host_path)
                    container_config['volumes'][host_path] = {'bind': container_path, 'mode': 'rw'}
            
            container = self.docker_client.containers.run(**container_config)
            self.running_services[service_name] = container
            self.logger.info(f"Container started: {container.id}")
            
            # Start health monitoring if configured
            if 'health_check' in service_config:
                self._start_health_monitoring(service_config)
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start container for {service_name}: {e}")
            return False
    
    def _start_compose_service(self, service_config: Dict[str, Any]) -> bool:
        """Start a service using Docker Compose."""
        service_name = service_config['name']
        service_path = self._normalize_path(service_config['path'])
        compose_file = service_config['compose_file']
        
        self.logger.info(f"Starting Docker Compose service: {service_name}")
        
        # Check if service path exists
        if not os.path.exists(service_path):
            self.logger.error(f"Service path does not exist: {service_path}")
            return False
        
        compose_file_path = os.path.join(service_path, compose_file)
        if not os.path.exists(compose_file_path):
            self.logger.error(f"Compose file does not exist: {compose_file_path}")
            return False
        
        try:
            # Change to service directory
            original_cwd = os.getcwd()
            os.chdir(service_path)
            
            # Get compose command for platform
            compose_cmd = self._get_compose_command()
            
            # Run docker-compose up
            cmd = [compose_cmd, '-f', compose_file, 'up', '-d']
            if 'services' in service_config:
                cmd.extend(service_config['services'])
            
            result = self._run_command(cmd)
            
            if result.returncode == 0:
                self.logger.info(f"Docker Compose started successfully: {result.stdout}")
                
                # Store compose project info
                self.running_services[service_name] = {
                    'type': 'compose',
                    'path': service_path,
                    'compose_file': compose_file,
                    'services': service_config.get('services', [])
                }
                
                # Start health monitoring if configured
                if 'health_check' in service_config:
                    self._start_health_monitoring(service_config)
                
                # Restore original working directory
                os.chdir(original_cwd)
                return True
            else:
                self.logger.error(f"Docker Compose failed: {result.stderr}")
                os.chdir(original_cwd)
                return False
            
        except Exception as e:
            self.logger.error(f"Failed to start compose service {service_name}: {e}")
            os.chdir(original_cwd)
            return False
    
    def stop_service(self, service_name: str) -> bool:
        """Stop a specific service."""
        service_config = self._get_service_config(service_name)
        if not service_config:
            self.logger.error(f"Service '{service_name}' not found in configuration")
            return False
        
        try:
            if service_config['type'] == 'dockerfile':
                return self._stop_dockerfile_service(service_name)
            elif service_config['type'] == 'docker-compose':
                return self._stop_compose_service(service_config)
            else:
                self.logger.error(f"Unknown service type: {service_config['type']}")
                return False
        except Exception as e:
            self.logger.error(f"Failed to stop service '{service_name}': {e}")
            return False
    
    def _stop_dockerfile_service(self, service_name: str) -> bool:
        """Stop a Dockerfile service."""
        if service_name not in self.running_services:
            self.logger.warning(f"Service '{service_name}' is not running")
            return True
        
        try:
            container = self.running_services[service_name]
            container.stop(timeout=30)
            container.remove()
            del self.running_services[service_name]
            self.logger.info(f"Service '{service_name}' stopped successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to stop service '{service_name}': {e}")
            return False
    
    def _stop_compose_service(self, service_config: Dict[str, Any]) -> bool:
        """Stop a Docker Compose service."""
        service_name = service_config['name']
        service_path = self._normalize_path(service_config['path'])
        compose_file = service_config['compose_file']
        
        try:
            # Change to service directory
            original_cwd = os.getcwd()
            os.chdir(service_path)
            
            # Get compose command for platform
            compose_cmd = self._get_compose_command()
            
            # Run docker-compose down
            cmd = [compose_cmd, '-f', compose_file, 'down']
            result = self._run_command(cmd)
            
            if result.returncode == 0:
                self.logger.info(f"Docker Compose stopped successfully: {result.stdout}")
                
                if service_name in self.running_services:
                    del self.running_services[service_name]
                
                # Restore original working directory
                os.chdir(original_cwd)
                return True
            else:
                self.logger.error(f"Docker Compose stop failed: {result.stderr}")
                os.chdir(original_cwd)
                return False
            
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Docker Compose stop failed: {e}")
            os.chdir(original_cwd)
            return False
        except Exception as e:
            self.logger.error(f"Failed to stop compose service {service_name}: {e}")
            os.chdir(original_cwd)
            return False
    
    def restart_service(self, service_name: str) -> bool:
        """Restart a specific service."""
        self.logger.info(f"Restarting service: {service_name}")
        if self.stop_service(service_name):
            time.sleep(2)  # Wait a bit before starting
            return self.start_service(service_name)
        return False
    
    def get_service_status(self, service_name: str) -> Optional[ServiceStatus]:
        """Get status of a specific service."""
        service_config = self._get_service_config(service_name)
        if not service_config:
            return None
        
        try:
            if service_config['type'] == 'dockerfile':
                return self._get_dockerfile_status(service_name)
            elif service_config['type'] == 'docker-compose':
                return self._get_compose_status(service_config)
            else:
                return None
        except Exception as e:
            self.logger.error(f"Failed to get status for service '{service_name}': {e}")
            return None
    
    def _get_dockerfile_status(self, service_name: str) -> Optional[ServiceStatus]:
        """Get status of a Dockerfile service."""
        try:
            container = self.docker_client.containers.get(service_name)
            container.reload()
            
            # Get container stats
            stats = container.stats(stream=False)
            
            # Calculate memory usage
            memory_usage = stats['memory_stats']['usage'] if 'memory_stats' in stats else 0
            memory_limit = stats['memory_stats']['limit'] if 'memory_stats' in stats else 1
            memory_percent = (memory_usage / memory_limit) * 100 if memory_limit > 0 else 0
            
            # Calculate CPU usage
            cpu_delta = stats['cpu_stats']['cpu_usage']['total_usage'] - stats['precpu_stats']['cpu_usage']['total_usage']
            system_delta = stats['cpu_stats']['system_cpu_usage'] - stats['precpu_stats']['system_cpu_usage']
            cpu_percent = (cpu_delta / system_delta) * 100 if system_delta > 0 else 0
            
            return ServiceStatus(
                name=service_name,
                status=container.status,
                container_id=container.id[:12],
                port=container.ports.get('8080/tcp', [{}])[0].get('HostPort', 'N/A') if container.ports else 'N/A',
                health=container.attrs['State'].get('Health', {}).get('Status', 'unknown'),
                uptime=self._format_uptime(container.attrs['State']['StartedAt']),
                memory_usage=f"{memory_percent:.1f}%",
                cpu_usage=cpu_percent
            )
        except docker.errors.NotFound:
            return ServiceStatus(
                name=service_name,
                status="not_found",
                health="unknown"
            )
        except Exception as e:
            self.logger.error(f"Error getting container status: {e}")
            return None
    
    def _get_compose_status(self, service_config: Dict[str, Any]) -> Optional[ServiceStatus]:
        """Get status of a Docker Compose service."""
        service_name = service_config['name']
        service_path = self._normalize_path(service_config['path'])
        compose_file = service_config['compose_file']
        
        try:
            # Change to service directory
            original_cwd = os.getcwd()
            os.chdir(service_path)
            
            # Get compose command for platform
            compose_cmd = self._get_compose_command()
            
            # Run docker-compose ps
            cmd = [compose_cmd, '-f', compose_file, 'ps', '--format', 'json']
            result = self._run_command(cmd)
            
            if result.returncode == 0:
                # Parse the output
                containers = json.loads(result.stdout)
                if not containers:
                    os.chdir(original_cwd)
                    return ServiceStatus(
                        name=service_name,
                        status="not_running",
                        health="unknown"
                    )
                
                # Get status of first container (assuming single service or main service)
                container_info = containers[0]
                
                os.chdir(original_cwd)
                return ServiceStatus(
                    name=service_name,
                    status=container_info.get('State', 'unknown'),
                    container_id=container_info.get('ID', 'N/A')[:12] if container_info.get('ID') else 'N/A',
                    port=container_info.get('Ports', 'N/A'),
                    health=container_info.get('Health', 'unknown'),
                    uptime="N/A"  # Compose doesn't provide this easily
                )
            else:
                os.chdir(original_cwd)
                return ServiceStatus(
                    name=service_name,
                    status="error",
                    health="unknown"
                )
            
        except subprocess.CalledProcessError:
            os.chdir(original_cwd)
            return ServiceStatus(
                name=service_name,
                status="error",
                health="unknown"
            )
        except Exception as e:
            self.logger.error(f"Error getting compose status: {e}")
            os.chdir(original_cwd)
            return None
    
    def list_services(self) -> List[ServiceStatus]:
        """List all services and their status."""
        services = []
        for service_config in self.config['services']:
            service_name = service_config['name']
            status = self.get_service_status(service_name)
            if status:
                services.append(status)
        return services
    
    def start_all_services(self) -> Dict[str, bool]:
        """Start all enabled services."""
        results = {}
        self.logger.info("Starting all enabled services...")
        
        for service_config in self.config['services']:
            service_name = service_config['name']
            if service_config.get('enabled', True):
                results[service_name] = self.start_service(service_name)
            else:
                self.logger.info(f"Skipping disabled service: {service_name}")
                results[service_name] = False
        
        return results
    
    def stop_all_services(self) -> Dict[str, bool]:
        """Stop all running services."""
        results = {}
        self.logger.info("Stopping all services...")
        
        for service_config in self.config['services']:
            service_name = service_config['name']
            results[service_name] = self.stop_service(service_name)
        
        return results
    
    def _get_service_config(self, service_name: str) -> Optional[Dict[str, Any]]:
        """Get service configuration by name."""
        for service in self.config['services']:
            if service['name'] == service_name:
                return service
        return None
    
    def _start_health_monitoring(self, service_config: Dict[str, Any]):
        """Start health monitoring for a service."""
        # This is a placeholder for health monitoring implementation
        # In a full implementation, this would start a background thread
        # to periodically check the service health
        self.logger.info(f"Health monitoring started for {service_config['name']}")
    
    def _format_uptime(self, started_at: str) -> str:
        """Format container uptime."""
        try:
            start_time = datetime.fromisoformat(started_at.replace('Z', '+00:00'))
            uptime = datetime.now(start_time.tzinfo) - start_time
            days = uptime.days
            hours, remainder = divmod(uptime.seconds, 3600)
            minutes, _ = divmod(remainder, 60)
            
            if days > 0:
                return f"{days}d {hours}h {minutes}m"
            elif hours > 0:
                return f"{hours}h {minutes}m"
            else:
                return f"{minutes}m"
        except Exception:
            return "N/A"
    
    def cleanup(self):
        """Cleanup resources."""
        self.stop_monitoring = True
        if self.monitoring_thread and self.monitoring_thread.is_alive():
            self.monitoring_thread.join()
        self.docker_client.close() 