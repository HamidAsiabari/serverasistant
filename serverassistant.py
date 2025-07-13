#!/usr/bin/env python3
"""
ServerAssistant - Terminal-based Server Management Application
A comprehensive tool for managing Docker services, testing, monitoring, and implementation

This file has been refactored to use the new organized structure.
"""

import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from core.server_assistant import ServerAssistant
from ui.menu_system import MenuSystem
from ui.display_utils import DisplayUtils


def main():
    """Main function - refactored to use organized structure"""
    try:
        # Initialize ServerAssistant with organized structure
        server_assistant = ServerAssistant("config.json")
        
        # Display banner
        DisplayUtils.print_banner()
        
        # Create menu system
        menu_system = MenuSystem()
        
        # Create menus
        menu_system.create_main_menu(server_assistant)
        menu_system.create_service_management_menu(server_assistant)
        menu_system.create_setup_menu(server_assistant)
        menu_system.create_certificate_management_menu(server_assistant)
        menu_system.create_testing_menu(server_assistant)
        
        # Start main menu
        menu_system.display_menu("main", "ServerAssistant - Main Menu")
        
    except KeyboardInterrupt:
        DisplayUtils.print_warning("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        DisplayUtils.print_error(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 