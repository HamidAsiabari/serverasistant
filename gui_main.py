#!/usr/bin/env python3
"""
GUI entry point for ServerAssistant
Launches the Textual-based terminal GUI application.
"""

import argparse
import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.ui.simple_textual_app import run_simple_textual_app


def main():
    """Main function for GUI application."""
    parser = argparse.ArgumentParser(
        description="ServerAssistant GUI - Beautiful terminal interface for managing Docker services",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python gui_main.py                    # Launch GUI with default config
  python gui_main.py --config custom.json  # Launch GUI with custom config
        """
    )
    
    parser.add_argument(
        '--config',
        default='config.json',
        help='Path to configuration file (default: config.json)'
    )
    
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug mode'
    )
    
    args = parser.parse_args()
    
    try:
        # Check if config file exists
        config_path = Path(args.config)
        if not config_path.exists():
            print(f"Error: Configuration file '{args.config}' not found")
            sys.exit(1)
            
        print("🚀 Starting ServerAssistant GUI...")
        print(f"📁 Using config: {config_path.absolute()}")
        print("💡 Press 'q' to quit, 'f1' for help")
        print("📋 Keyboard shortcuts:")
        print("  1 - Dashboard")
        print("  2 - Services") 
        print("  3 - Logs")
        print("  4 - Settings")
        print("  r - Refresh")
        print("  q - Quit")
        print("-" * 50)
        
        # Launch the GUI
        run_simple_textual_app(str(config_path))
        
    except KeyboardInterrupt:
        print("\n👋 GUI closed by user")
        sys.exit(0)
    except Exception as e:
        print(f"❌ Error launching GUI: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 