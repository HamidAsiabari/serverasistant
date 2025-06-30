#!/usr/bin/env python3
"""
Test script for the simple logging functionality
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.ui.display_utils import SimpleLogDisplay

def test_logging():
    """Test the simple logging functionality"""
    print("Testing Simple Logging System")
    print("=" * 50)
    
    # Create log display
    log_display = SimpleLogDisplay(max_lines=10)
    
    # Add some test logs
    log_display.add_log("ServerAssistant Enhanced started", "INFO")
    log_display.add_log("Docker environment check...", "INFO")
    log_display.add_log("Docker environment is available", "SUCCESS")
    log_display.add_log("User selected: Service Management", "ACTION")
    log_display.add_log("Executing: Stop All Services", "INFO")
    log_display.add_log("Stopping all services...", "INFO")
    log_display.add_log("Successfully stopped 3 services", "SUCCESS")
    
    # Show logs
    log_display.show_logs("Test Logs")
    
    # Test action completion
    print("\n" + "="*50)
    print("Testing action completion...")
    log_display.show_logs_after_action("Stop All Services")
    
    print("\nTest completed!")

if __name__ == "__main__":
    test_logging() 