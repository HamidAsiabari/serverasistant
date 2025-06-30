#!/usr/bin/env python3
"""
Launcher for ServerAssistant Enhanced with real-time logs
"""

import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

if __name__ == "__main__":
    from src.main_enhanced import main
    main() 