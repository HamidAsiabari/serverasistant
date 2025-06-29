#!/usr/bin/env python3
"""
Main entry point for ServerAssistant
"""

import sys
import argparse
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from core.server_assistant import ServerAssistant
from ui.menu_system import MenuSystem
from ui.display_utils import DisplayUtils


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="ServerAssistant - Terminal-based Server Management Application",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python src/main.py                    # Start interactive mode
  python src/main.py --config config.json  # Use specific config file
  python src/main.py --cli status       # Use CLI mode
  python src/main.py --cli start web-app   # Start specific service
        """
    )
    
    parser.add_argument(
        '--config',
        default='config.json',
        help='Path to configuration file (default: config.json)'
    )
    
    parser.add_argument(
        '--cli',
        action='store_true',
        help='Use CLI mode instead of interactive menu'
    )
    
    parser.add_argument(
        'action',
        nargs='?',
        choices=['status', 'start', 'stop', 'restart', 'start-all', 'stop-all', 'logs'],
        help='CLI action to perform'
    )
    
    parser.add_argument(
        'service',
        nargs='?',
        help='Service name (required for start, stop, restart, logs actions)'
    )
    
    parser.add_argument(
        '--follow',
        '-f',
        action='store_true',
        help='Follow logs (for logs action)'
    )
    
    args = parser.parse_args()
    
    try:
        # Initialize ServerAssistant
        server_assistant = ServerAssistant(args.config)
        
        if args.cli:
            # CLI mode
            if not args.action:
                DisplayUtils.print_error("Action is required in CLI mode")
                sys.exit(1)
                
            if args.action in ['start', 'stop', 'restart', 'logs'] and not args.service:
                DisplayUtils.print_error(f"Service name is required for '{args.action}' action")
                sys.exit(1)
                
            # Execute CLI action
            if args.action == 'status':
                DisplayUtils.print_header("Service Status")
                statuses = server_assistant.get_all_service_status()
                
                # Convert to list of dictionaries for display
                service_data = []
                for status in statuses:
                    service_data.append({
                        'name': status.name,
                        'status': status.status,
                        'container_id': status.container_id or 'N/A',
                        'port': status.port or 'N/A',
                        'health': status.health or 'N/A',
                        'uptime': status.uptime or 'N/A'
                    })
                    
                DisplayUtils.print_service_status_table(service_data)
                
            elif args.action == 'start':
                if args.service == 'all':
                    server_assistant.start_all_services()
                else:
                    server_assistant.start_service(args.service)
                    
            elif args.action == 'stop':
                if args.service == 'all':
                    server_assistant.stop_all_services()
                else:
                    server_assistant.stop_service(args.service)
                    
            elif args.action == 'restart':
                server_assistant.restart_service(args.service)
                
            elif args.action == 'start-all':
                server_assistant.start_all_services()
                
            elif args.action == 'stop-all':
                server_assistant.stop_all_services()
                
            elif args.action == 'logs':
                logs = server_assistant.get_service_logs(args.service, args.follow)
                DisplayUtils.print_header(f"Logs - {args.service}")
                print(logs)
                
        else:
            # Interactive mode
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
            
    except KeyboardInterrupt:
        DisplayUtils.print_warning("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        DisplayUtils.print_error(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 