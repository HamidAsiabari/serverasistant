#!/usr/bin/env python3
"""
Simple test for split-screen display without virtual environment
"""

import os
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

# Simple mock classes for testing
class MockLogPanel:
    def __init__(self, max_lines=10):
        self.log_lines = []
        
    def add_log(self, message, level="INFO"):
        timestamp = "14:30:15"
        log_entry = f"[{timestamp}] {level}: {message}"
        self.log_lines.append(log_entry)
        if len(self.log_lines) > 10:
            self.log_lines = self.log_lines[-10:]
            
    def get_logs(self):
        return self.log_lines.copy()

class MockDisplayUtils:
    @staticmethod
    def clear_screen():
        os.system('cls' if os.name == 'nt' else 'clear')
        
    @staticmethod
    def print_banner():
        print("=" * 60)
        print("ServerAssistant v1.0.0")
        print("=" * 60)
        
    @staticmethod
    def print_header(text):
        print(f"\n{text}")
        print("-" * len(text))

class SimpleSplitScreenDisplay:
    def __init__(self, log_panel):
        self.log_panel = log_panel
        self.terminal_width = 120  # Fixed width for testing
        self.menu_width = 70
        self.log_width = 45
        
    def print_menu_with_logs(self, title, menu_items):
        # Clear screen
        MockDisplayUtils.clear_screen()
        MockDisplayUtils.print_banner()
        MockDisplayUtils.print_header(title)
        
        # Build menu content
        menu_content = f"\n{title}\n"
        menu_content += "─" * (self.menu_width - 2) + "\n\n"
        
        for item in menu_items:
            key = item.get('key', '0')
            label = item.get('label', 'Unknown')
            description = item.get('description', '')
            
            menu_content += f"  {key}. {label}\n"
            if description:
                menu_content += f"     {description}\n"
            menu_content += "\n"
            
        menu_content += "─" * (self.menu_width - 2) + "\n"
        menu_content += "Use number keys to select, 0 to go back\n"
        
        # Split menu content into lines
        menu_lines = menu_content.split('\n')
        
        # Get log lines
        log_lines = self.log_panel.get_logs()
        if not log_lines:
            log_lines = ["[No logs available]"]
        
        # Calculate how many lines to display
        max_lines = max(len(menu_lines), len(log_lines), 10)
        
        # Print separator line
        separator = "─" * self.terminal_width
        print(separator)
        
        # Print content
        for i in range(max_lines):
            # Menu side
            menu_line = menu_lines[i] if i < len(menu_lines) else ""
            if len(menu_line) > self.menu_width:
                menu_line = menu_line[:self.menu_width-3] + "..."
            menu_padded = menu_line.ljust(self.menu_width)
            
            # Log side
            log_line = log_lines[i] if i < len(log_lines) else ""
            if len(log_line) > self.log_width:
                log_line = log_line[:self.log_width-3] + "..."
            log_padded = log_line.ljust(self.log_width)
            
            # Print the line
            print(f"{menu_padded} │ {log_padded}")
            
        # Print bottom separator
        print(separator)

def test_split_screen():
    """Test the split-screen display"""
    print("Testing Simple Split-Screen Display")
    print("=" * 50)
    
    # Create log panel
    log_panel = MockLogPanel(max_lines=10)
    
    # Add some test logs
    log_panel.add_log("ServerAssistant Enhanced started", "INFO")
    log_panel.add_log("Docker environment check...", "INFO")
    log_panel.add_log("Docker environment is available", "SUCCESS")
    log_panel.add_log("Menus created successfully", "INFO")
    log_panel.add_log("Ready for user interaction", "SUCCESS")
    log_panel.add_log("User selected: Service Management", "ACTION")
    log_panel.add_log("Fetching service status...", "INFO")
    log_panel.add_log("Status retrieved: 3/5 services running", "SUCCESS")
    
    # Create split screen display
    split_display = SimpleSplitScreenDisplay(log_panel)
    
    print(f"Terminal width: {split_display.terminal_width}")
    print(f"Menu width: {split_display.menu_width}")
    print(f"Log width: {split_display.log_width}")
    print()
    
    # Test menu items
    menu_items = [
        {"key": "1", "label": "Service Management", "description": "Manage Docker services"},
        {"key": "2", "label": "Setup & Installation", "description": "System setup and installation"},
        {"key": "3", "label": "Testing & Validation", "description": "Test and validate system"},
        {"key": "4", "label": "Monitoring & Health", "description": "Monitor system health"},
        {"key": "5", "label": "Backup & Restore", "description": "Backup and restore services"},
    ]
    
    # Test the display
    split_display.print_menu_with_logs("ServerAssistant Enhanced - Main Menu", menu_items)
    
    input("Press Enter to continue...")

if __name__ == "__main__":
    test_split_screen() 