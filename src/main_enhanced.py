#!/usr/bin/env python3
"""
Enhanced main entry point for ServerAssistant with real-time logs
"""

import argparse
import sys
from pathlib import Path

# Add project root to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from src.core.server_assistant import ServerAssistant
from src.ui.display_utils import DisplayUtils
from src.ui.menu_system import SimpleEnhancedMenuSystem


def print_banner():
    """Print application banner."""
    DisplayUtils.print_banner()


def main():
    """Main function with enhanced menu system."""
    parser = argparse.ArgumentParser(
        description="ServerAssistant Enhanced - Docker Service Manager with Real-time Logs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python src/main_enhanced.py                    # Launch enhanced GUI with default config
  python src/main_enhanced.py --config custom.json  # Launch with custom config
  python src/main_enhanced.py --cli status       # Use CLI mode
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
        help='Use CLI mode instead of enhanced GUI'
    )
    
    parser.add_argument(
        'action',
        nargs='?',
        choices=['status', 'start', 'stop', 'restart', 'start-all', 'stop-all', 'logs'],
        help='Action to perform (CLI mode only)'
    )
    
    parser.add_argument(
        'service',
        nargs='?',
        help='Service name (CLI mode only)'
    )
    
    parser.add_argument(
        '--follow',
        '-f',
        action='store_true',
        help='Follow logs (CLI mode only)'
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
            # Enhanced GUI mode
            print_banner()
            DisplayUtils.print_info("🚀 Starting ServerAssistant Enhanced with Real-time Logs...")
            DisplayUtils.print_info("📋 The right panel will show live logs of all actions")
            DisplayUtils.print_info("💡 Press Ctrl+C to exit")
            print()
            
            # Create enhanced menu system
            menu_system = SimpleEnhancedMenuSystem()
            
            # Add initial log messages
            menu_system.log_action("🚀 ServerAssistant Enhanced started", "INFO")
            menu_system.log_action("📋 Simple logging system initialized", "INFO")
            menu_system.log_action("🔍 Docker environment check...", "INFO")
            
            # Check Docker environment
            if server_assistant.check_docker_environment():
                menu_system.log_action("✅ Docker environment is available", "SUCCESS")
            else:
                menu_system.log_action("❌ Docker environment not available", "ERROR")
            
            # Create menus
            menu_system.log_action("📝 Creating menu system...", "INFO")
            menu_system.create_main_menu(server_assistant)
            menu_system.create_service_management_menu(server_assistant)
            menu_system.create_setup_menu(server_assistant)
            menu_system.create_testing_menu(server_assistant)
            
            # Add enhanced logging to service actions
            menu_system.log_action("✅ Menus created successfully", "SUCCESS")
            menu_system.log_action("🎯 Ready for user interaction", "SUCCESS")
            menu_system.log_action("💡 Logs will appear after each action", "INFO")
            
            try:
                # Start main menu
                menu_system.display_menu("main", "ServerAssistant Enhanced - Main Menu")
            except KeyboardInterrupt:
                menu_system.log_action("Application interrupted by user", "WARNING")
                print("\n👋 Goodbye!")
            
    except KeyboardInterrupt:
        DisplayUtils.print_warning("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        DisplayUtils.print_error(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 