#!/usr/bin/env python3
"""
Debug script for split-screen display
"""

import os
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.ui.display_utils import LogPanel, SplitScreenDisplay, DisplayUtils

def test_split_screen():
    """Test the split-screen display"""
    print("Testing Split-Screen Display")
    print("=" * 50)
    
    # Create log panel
    log_panel = LogPanel(max_lines=10)
    
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
    split_display = SplitScreenDisplay(log_panel)
    
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