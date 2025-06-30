#!/usr/bin/env python3
"""
Real-time ServerAssistant with bottom log panel
Enhanced version with persistent bottom log display
"""

import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from src.main_enhanced import main

if __name__ == "__main__":
    print("🚀 Starting ServerAssistant with Bottom Log Panel...")
    print("📋 Logs will be displayed at the bottom of the screen")
    print("🔄 Real-time updates every 300ms")
    print()
    
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 ServerAssistant stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1) 