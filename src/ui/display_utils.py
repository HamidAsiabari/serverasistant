"""
Display utilities for ServerAssistant UI
"""

from typing import List, Dict, Any, Optional
from tabulate import tabulate
import os
import threading
import time
import queue
from datetime import datetime


class LogPanel:
    """Real-time log panel for displaying live logs"""
    
    def __init__(self, max_lines: int = 20):
        self.max_lines = max_lines
        self.log_lines = []
        self.log_queue = queue.Queue()
        self.running = True
        self.lock = threading.Lock()
        
    def add_log(self, message: str, level: str = "INFO"):
        """Add a log message to the panel"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {level}: {message}"
        
        with self.lock:
            self.log_lines.append(log_entry)
            # Keep only the last max_lines
            if len(self.log_lines) > self.max_lines:
                self.log_lines = self.log_lines[-self.max_lines:]
                
    def get_logs(self) -> List[str]:
        """Get current log lines"""
        with self.lock:
            return self.log_lines.copy()
            
    def clear(self):
        """Clear all logs"""
        with self.lock:
            self.log_lines.clear()
            
    def stop(self):
        """Stop the log panel"""
        self.running = False


class SplitScreenDisplay:
    """Split-screen display with menu on left and logs on right"""
    
    def __init__(self, log_panel: LogPanel):
        self.log_panel = log_panel
        self.terminal_width = self._get_terminal_width()
        self.menu_width = int(self.terminal_width * 0.6)  # 60% for menu
        self.log_width = self.terminal_width - self.menu_width - 2  # 2 for separator
        
    def _get_terminal_width(self) -> int:
        """Get terminal width"""
        try:
            return os.get_terminal_size().columns
        except:
            return 120  # Default width
            
    def print_split_screen(self, menu_content: str, title: str = ""):
        """Print split screen with menu on left and logs on right"""
        # Clear screen
        DisplayUtils.clear_screen()
        
        # Print banner
        DisplayUtils.print_banner()
        
        # Print title
        if title:
            DisplayUtils.print_header(title)
            
        # Split menu content into lines
        menu_lines = menu_content.split('\n')
        
        # Get log lines
        log_lines = self.log_panel.get_logs()
        
        # Calculate how many lines to display
        max_lines = max(len(menu_lines), len(log_lines))
        
        # Print separator line
        separator = "─" * self.terminal_width
        print(separator)
        
        # Print content
        for i in range(max_lines):
            # Menu side
            menu_line = menu_lines[i] if i < len(menu_lines) else ""
            menu_padded = menu_line.ljust(self.menu_width)
            
            # Log side
            log_line = log_lines[i] if i < len(log_lines) else ""
            # Truncate log line if too long
            if len(log_line) > self.log_width:
                log_line = log_line[:self.log_width-3] + "..."
            log_padded = log_line.ljust(self.log_width)
            
            # Print the line
            print(f"{menu_padded} │ {log_padded}")
            
        # Print bottom separator
        print(separator)
        
    def print_menu_with_logs(self, title: str, menu_items: List[Dict[str, str]], 
                           current_selection: str = ""):
        """Print menu with real-time logs"""
        # Build menu content
        menu_content = f"\n{title}\n"
        menu_content += "─" * (self.menu_width - 2) + "\n\n"
        
        for item in menu_items:
            key = item.get('key', '0')
            label = item.get('label', 'Unknown')
            description = item.get('description', '')
            
            # Highlight current selection
            if key == current_selection:
                menu_content += f"▶ {key}. {label}\n"
            else:
                menu_content += f"  {key}. {label}\n"
                
            if description:
                menu_content += f"     {description}\n"
            menu_content += "\n"
            
        # Add navigation info
        menu_content += "─" * (self.menu_width - 2) + "\n"
        menu_content += "Use number keys to select, 0 to go back\n"
        
        self.print_split_screen(menu_content, title)


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