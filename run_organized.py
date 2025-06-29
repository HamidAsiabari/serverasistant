#!/usr/bin/env python3
"""
Simple script to run the organized version of ServerAssistant
"""

import sys
import os
from pathlib import Path

def main():
    """Run the organized version of ServerAssistant"""
    
    # Get the directory where this script is located
    script_dir = Path(__file__).parent
    
    # Add src to Python path
    src_path = script_dir / "src"
    if src_path.exists():
        sys.path.insert(0, str(src_path))
    else:
        print("ERROR: src/ directory not found!")
        print("Please ensure the organized structure is properly set up.")
        sys.exit(1)
    
    try:
        # Try to import from organized structure
        from core.server_assistant import ServerAssistant
        from ui.menu_system import MenuSystem
        from ui.display_utils import DisplayUtils
        
        print("Starting ServerAssistant (Organized Structure)...")
        
        # Initialize ServerAssistant
        server_assistant = ServerAssistant("config.json")
        
        # Display banner
        DisplayUtils.print_banner()
        
        # Create menu system
        menu_system = MenuSystem()
        
        # Create menus
        menu_system.create_main_menu(server_assistant)
        menu_system.create_service_management_menu(server_assistant)
        menu_system.create_setup_menu(server_assistant)
        menu_system.create_testing_menu(server_assistant)
        
        # Start main menu
        menu_system.display_menu("main", "ServerAssistant - Main Menu")
        
    except ImportError as e:
        print(f"ERROR: Failed to import organized modules: {e}")
        print("Please ensure all dependencies are installed:")
        print("  pip install tabulate psutil colorama")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 