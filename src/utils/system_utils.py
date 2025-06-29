"""
System utility functions for ServerAssistant
"""

import os
import platform
import subprocess
import psutil
from typing import Dict, List, Optional, Tuple


class SystemUtils:
    """Utility class for system operations"""
    
    @staticmethod
    def get_system_info() -> Dict[str, str]:
        """Get basic system information"""
        return {
            'platform': platform.system(),
            'platform_version': platform.version(),
            'architecture': platform.machine(),
            'processor': platform.processor(),
            'python_version': platform.python_version(),
            'hostname': platform.node()
        }
        
    @staticmethod
    def run_command(command: str, cwd: Optional[str] = None, 
                   check: bool = True) -> Tuple[bool, str, str]:
        """Run a shell command and return result"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                check=check
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.CalledProcessError as e:
            return False, e.stdout, e.stderr
        except Exception as e:
            return False, "", str(e)
            
    @staticmethod
    def get_disk_usage(path: str = "/") -> Dict[str, float]:
        """Get disk usage information"""
        try:
            usage = psutil.disk_usage(path)
            return {
                'total_gb': usage.total / (1024**3),
                'used_gb': usage.used / (1024**3),
                'free_gb': usage.free / (1024**3),
                'percent_used': (usage.used / usage.total) * 100
            }
        except Exception as e:
            print(f"Error getting disk usage for {path}: {e}")
            return {}
            
    @staticmethod
    def get_memory_usage() -> Dict[str, float]:
        """Get memory usage information"""
        try:
            memory = psutil.virtual_memory()
            return {
                'total_gb': memory.total / (1024**3),
                'available_gb': memory.available / (1024**3),
                'used_gb': memory.used / (1024**3),
                'percent_used': memory.percent
            }
        except Exception as e:
            print(f"Error getting memory usage: {e}")
            return {}
            
    @staticmethod
    def get_cpu_usage() -> float:
        """Get CPU usage percentage"""
        try:
            return psutil.cpu_percent(interval=1)
        except Exception as e:
            print(f"Error getting CPU usage: {e}")
            return 0.0
            
    @staticmethod
    def get_network_interfaces() -> Dict[str, Dict[str, str]]:
        """Get network interface information"""
        try:
            interfaces = {}
            for interface, addresses in psutil.net_if_addrs().items():
                interfaces[interface] = {}
                for addr in addresses:
                    if addr.family == psutil.AF_INET:  # IPv4
                        interfaces[interface]['ipv4'] = addr.address
                    elif addr.family == psutil.AF_INET6:  # IPv6
                        interfaces[interface]['ipv6'] = addr.address
                    elif addr.family == psutil.AF_LINK:  # MAC
                        interfaces[interface]['mac'] = addr.address
            return interfaces
        except Exception as e:
            print(f"Error getting network interfaces: {e}")
            return {}
            
    @staticmethod
    def get_process_info(pid: Optional[int] = None) -> List[Dict[str, Any]]:
        """Get process information"""
        try:
            processes = []
            if pid:
                try:
                    process = psutil.Process(pid)
                    processes.append({
                        'pid': process.pid,
                        'name': process.name(),
                        'status': process.status(),
                        'cpu_percent': process.cpu_percent(),
                        'memory_mb': process.memory_info().rss / (1024**2),
                        'create_time': process.create_time()
                    })
                except psutil.NoSuchProcess:
                    pass
            else:
                for process in psutil.process_iter(['pid', 'name', 'status', 'cpu_percent', 'memory_info', 'create_time']):
                    try:
                        processes.append({
                            'pid': process.info['pid'],
                            'name': process.info['name'],
                            'status': process.info['status'],
                            'cpu_percent': process.info['cpu_percent'],
                            'memory_mb': process.info['memory_info'].rss / (1024**2) if process.info['memory_info'] else 0,
                            'create_time': process.info['create_time']
                        })
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        pass
            return processes
        except Exception as e:
            print(f"Error getting process information: {e}")
            return []
            
    @staticmethod
    def check_port_available(port: int, host: str = "localhost") -> bool:
        """Check if a port is available"""
        import socket
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(1)
                result = s.connect_ex((host, port))
                return result != 0  # Port is available if connection fails
        except Exception as e:
            print(f"Error checking port {port}: {e}")
            return False
            
    @staticmethod
    def get_open_ports() -> List[int]:
        """Get list of open ports"""
        try:
            open_ports = []
            for conn in psutil.net_connections():
                if conn.status == 'LISTEN':
                    open_ports.append(conn.laddr.port)
            return sorted(list(set(open_ports)))
        except Exception as e:
            print(f"Error getting open ports: {e}")
            return []
            
    @staticmethod
    def is_process_running(process_name: str) -> bool:
        """Check if a process is running by name"""
        try:
            for process in psutil.process_iter(['name']):
                if process.info['name'] == process_name:
                    return True
            return False
        except Exception as e:
            print(f"Error checking if process {process_name} is running: {e}")
            return False
            
    @staticmethod
    def kill_process(pid: int) -> bool:
        """Kill a process by PID"""
        try:
            process = psutil.Process(pid)
            process.terminate()
            process.wait(timeout=5)
            return True
        except psutil.NoSuchProcess:
            return True  # Process already dead
        except psutil.TimeoutExpired:
            try:
                process.kill()
                return True
            except psutil.NoSuchProcess:
                return True
        except Exception as e:
            print(f"Error killing process {pid}: {e}")
            return False
            
    @staticmethod
    def get_environment_variables() -> Dict[str, str]:
        """Get environment variables"""
        return dict(os.environ)
        
    @staticmethod
    def set_environment_variable(name: str, value: str) -> bool:
        """Set an environment variable"""
        try:
            os.environ[name] = value
            return True
        except Exception as e:
            print(f"Error setting environment variable {name}: {e}")
            return False
            
    @staticmethod
    def get_current_user() -> str:
        """Get current user name"""
        try:
            return os.getlogin()
        except Exception:
            return os.environ.get('USER', 'unknown')
            
    @staticmethod
    def is_root() -> bool:
        """Check if running as root/administrator"""
        try:
            return os.geteuid() == 0
        except AttributeError:
            # Windows doesn't have geteuid
            return False
            
    @staticmethod
    def get_system_uptime() -> float:
        """Get system uptime in seconds"""
        try:
            return time.time() - psutil.boot_time()
        except Exception as e:
            print(f"Error getting system uptime: {e}")
            return 0.0 