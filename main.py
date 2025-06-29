#!/usr/bin/env python3
"""
Main entry point for Docker Service Manager
Provides CLI interface for managing Docker services.

This file has been refactored to use the new organized structure.
"""

import argparse
import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from core.server_assistant import ServerAssistant
from ui.display_utils import DisplayUtils


def print_banner():
    """Print application banner."""
    DisplayUtils.print_banner()


def main():
    """Main function - refactored to use organized structure."""
    parser = argparse.ArgumentParser(
        description="Docker Service Manager - Manage Docker services based on JSON configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python main.py status                    # Show status of all services
  python main.py start web-app            # Start specific service
  python main.py stop database            # Stop specific service
  python main.py restart monitoring       # Restart specific service
  python main.py start-all                # Start all enabled services
  python main.py stop-all                 # Stop all services
  python main.py logs web-app             # Show logs for specific service
        """
    )
    
    parser.add_argument(
        'action',
        choices=['status', 'start', 'stop', 'restart', 'start-all', 'stop-all', 'logs'],
        help='Action to perform'
    )
    
    parser.add_argument(
        'service',
        nargs='?',
        help='Service name (required for start, stop, restart, logs actions)'
    )
    
    parser.add_argument(
        '--config',
        default='config.json',
        help='Path to configuration file (default: config.json)'
    )
    
    parser.add_argument(
        '--follow',
        '-f',
        action='store_true',
        help='Follow logs (for logs action)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.action in ['start', 'stop', 'restart', 'logs'] and not args.service:
        DisplayUtils.print_error(f"Service name is required for '{args.action}' action")
        sys.exit(1)
    
    try:
        # Initialize ServerAssistant with organized structure
        server_assistant = ServerAssistant(args.config)
        
        # Print banner
        print_banner()
        
        # Execute action
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
            
    except KeyboardInterrupt:
        DisplayUtils.print_warning("\nOperation cancelled by user")
        sys.exit(1)
    except Exception as e:
        DisplayUtils.print_error(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 