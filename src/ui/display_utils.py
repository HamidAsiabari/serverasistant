"""
Display utilities for ServerAssistant UI
"""

from typing import List, Dict, Any, Optional
from tabulate import tabulate
import os


class DisplayUtils:
    """Utility class for consistent display formatting"""
    
    # Colors for terminal output
    COLORS = {
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
    
    @classmethod
    def print_color(cls, text: str, color: str = 'white', bold: bool = False):
        """Print colored text"""
        color_code = cls.COLORS.get(color, '')
        bold_code = cls.COLORS['bold'] if bold else ''
        print(f"{bold_code}{color_code}{text}{cls.COLORS['reset']}")
        
    @classmethod
    def print_header(cls, text: str):
        """Print header with decoration"""
        print("\n" + "="*60)
        cls.print_color(f"  {text}", 'cyan', bold=True)
        print("="*60)
        
    @classmethod
    def print_success(cls, text: str):
        """Print success message"""
        cls.print_color(f"✓ {text}", 'green')
        
    @classmethod
    def print_error(cls, text: str):
        """Print error message"""
        cls.print_color(f"✗ {text}", 'red')
        
    @classmethod
    def print_warning(cls, text: str):
        """Print warning message"""
        cls.print_color(f"⚠ {text}", 'yellow')
        
    @classmethod
    def print_info(cls, text: str):
        """Print info message"""
        cls.print_color(f"ℹ {text}", 'blue')
        
    @classmethod
    def print_table(cls, data: List[List[Any]], headers: List[str], 
                   title: Optional[str] = None, tablefmt: str = "grid"):
        """Print data in a formatted table"""
        if title:
            cls.print_header(title)
            
        print(tabulate(data, headers=headers, tablefmt=tablefmt))
        
    @classmethod
    def print_service_status_table(cls, services: List[Dict[str, Any]]):
        """Print service status in a formatted table"""
        if not services:
            cls.print_warning("No services found.")
            return
            
        headers = ["Service", "Status", "Container ID", "Port", "Health", "Uptime"]
        table_data = []
        
        for service in services:
            # Color code status
            status = service.get('status', 'unknown')
            status_display = status
            
            # Color code health
            health = service.get('health', 'unknown')
            health_display = health
            
            table_data.append([
                service.get('name', 'Unknown'),
                status_display,
                service.get('container_id', 'N/A'),
                service.get('port', 'N/A'),
                health_display,
                service.get('uptime', 'N/A')
            ])
            
        cls.print_table(table_data, headers, "Service Status")
        
    @classmethod
    def print_configuration_summary(cls, config: Dict[str, Any]):
        """Print configuration summary"""
        cls.print_header("Configuration Summary")
        
        print(f"Server Name: {config.get('server_name', 'Unknown')}")
        print(f"Environment: {config.get('environment', 'production')}")
        print(f"Backup Path: {config.get('backup_path', './backups')}")
        print(f"Log Level: {config.get('log_level', 'INFO')}")
        
        services = config.get('services', [])
        enabled_count = sum(1 for s in services if s.get('enabled', False))
        
        print(f"\nServices: {len(services)} total, {enabled_count} enabled")
        
        if services:
            cls.print_header("Services")
            for service in services:
                status = "✓ Enabled" if service.get('enabled', False) else "✗ Disabled"
                print(f"  {service.get('name', 'Unknown')}: {status}")
                
    @classmethod
    def print_banner(cls):
        """Print application banner"""
        banner = f"""
{cls.COLORS['cyan']}╔══════════════════════════════════════════════════════════════╗
║                    ServerAssistant v1.0.0                    ║
║              Terminal-based Server Management                 ║
╚══════════════════════════════════════════════════════════════╝{cls.COLORS['reset']}
"""
        print(banner)
        
    @classmethod
    def print_menu(cls, title: str, options: List[Dict[str, str]]):
        """Print menu with options"""
        cls.print_header(title)
        
        for option in options:
            print(f"{option.get('key', '0')}. {option.get('label', 'Unknown')}")
            
    @classmethod
    def clear_screen(cls):
        """Clear the terminal screen"""
        os.system('cls' if os.name == 'nt' else 'clear')
        
    @classmethod
    def print_progress(cls, current: int, total: int, description: str = ""):
        """Print progress bar"""
        percentage = (current / total) * 100 if total > 0 else 0
        bar_length = 40
        filled_length = int(bar_length * current // total)
        bar = '█' * filled_length + '-' * (bar_length - filled_length)
        
        print(f"\r{description} [{bar}] {percentage:.1f}% ({current}/{total})", end='')
        if current == total:
            print()  # New line when complete 