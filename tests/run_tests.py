#!/usr/bin/env python3
"""
Test Runner for ServerAssistant

This script provides a unified interface for running different types of tests
in the ServerAssistant project.
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
from typing import List, Dict, Optional

class TestRunner:
    """Main test runner class."""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.tests_dir = self.project_root / "tests"
        self.src_dir = self.project_root / "src"
        
    def run_pytest(self, test_path: str, args: List[str] = None) -> bool:
        """Run pytest with given arguments."""
        cmd = ["python", "-m", "pytest", test_path]
        if args:
            cmd.extend(args)
        
        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, cwd=self.project_root)
        return result.returncode == 0
    
    def run_shell_script(self, script_path: str) -> bool:
        """Run a shell script."""
        script_file = self.tests_dir / "scripts" / script_path
        if not script_file.exists():
            print(f"❌ Script not found: {script_file}")
            return False
        
        print(f"Running shell script: {script_path}")
        result = subprocess.run(["bash", str(script_file)], cwd=self.project_root)
        return result.returncode == 0
    
    def run_unit_tests(self, verbose: bool = False, coverage: bool = False) -> bool:
        """Run unit tests."""
        print("🧪 Running Unit Tests...")
        args = []
        if verbose:
            args.append("-v")
        if coverage:
            args.extend(["--cov=src", "--cov-report=html"])
        
        return self.run_pytest("tests/unit/", args)
    
    def run_integration_tests(self, verbose: bool = False, coverage: bool = False) -> bool:
        """Run integration tests."""
        print("🔗 Running Integration Tests...")
        args = []
        if verbose:
            args.append("-v")
        if coverage:
            args.extend(["--cov=src", "--cov-report=html"])
        
        return self.run_pytest("tests/integration/", args)
    
    def run_e2e_tests(self, verbose: bool = False, coverage: bool = False) -> bool:
        """Run end-to-end tests."""
        print("🌐 Running End-to-End Tests...")
        args = []
        if verbose:
            args.append("-v")
        if coverage:
            args.extend(["--cov=src", "--cov-report=html"])
        
        return self.run_pytest("tests/e2e/", args)
    
    def run_quick_tests(self) -> bool:
        """Run quick validation tests."""
        print("⚡ Running Quick Tests...")
        return self.run_shell_script("quick_test.sh")
    
    def run_ubuntu_tests(self) -> bool:
        """Run Ubuntu-specific tests."""
        print("🐧 Running Ubuntu Tests...")
        return self.run_shell_script("test_ubuntu22.sh")
    
    def run_mysql_check(self) -> bool:
        """Run MySQL connectivity check."""
        print("🗄️ Running MySQL Connectivity Check...")
        return self.run_shell_script("check_mysql.sh")
    
    def run_all_tests(self, verbose: bool = False, coverage: bool = False) -> bool:
        """Run all tests."""
        print("🚀 Running All Tests...")
        
        results = {
            "unit": self.run_unit_tests(verbose, coverage),
            "integration": self.run_integration_tests(verbose, coverage),
            "e2e": self.run_e2e_tests(verbose, coverage),
            "quick": self.run_quick_tests(),
            "ubuntu": self.run_ubuntu_tests(),
            "mysql": self.run_mysql_check()
        }
        
        # Print summary
        print("\n📊 Test Results Summary:")
        print("=" * 40)
        for test_type, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{test_type.title():15} {status}")
        
        all_passed = all(results.values())
        print("=" * 40)
        print(f"Overall: {'✅ ALL TESTS PASSED' if all_passed else '❌ SOME TESTS FAILED'}")
        
        return all_passed
    
    def list_tests(self):
        """List all available tests."""
        print("📋 Available Tests:")
        print("=" * 40)
        
        # Python tests
        print("\n🐍 Python Tests:")
        for test_dir in ["unit", "integration", "e2e"]:
            test_path = self.tests_dir / test_dir
            if test_path.exists():
                test_files = list(test_path.glob("test_*.py"))
                if test_files:
                    print(f"  {test_dir}/:")
                    for test_file in test_files:
                        print(f"    - {test_file.name}")
        
        # Shell scripts
        print("\n🔧 Shell Scripts:")
        scripts_dir = self.tests_dir / "scripts"
        if scripts_dir.exists():
            script_files = list(scripts_dir.glob("*.sh"))
            for script_file in script_files:
                print(f"  - {script_file.name}")
        
        # Configuration files
        print("\n⚙️ Test Configurations:")
        config_dir = self.tests_dir / "config"
        if config_dir.exists():
            config_files = list(config_dir.glob("*.json"))
            for config_file in config_files:
                print(f"  - {config_file.name}")

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="ServerAssistant Test Runner")
    parser.add_argument("test_type", nargs="?", choices=[
        "unit", "integration", "e2e", "quick", "ubuntu", "mysql", "all", "list"
    ], default="all", help="Type of tests to run")
    
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")
    parser.add_argument("-c", "--coverage", action="store_true", help="Generate coverage report")
    parser.add_argument("--pytest-args", help="Additional pytest arguments")
    
    args = parser.parse_args()
    
    runner = TestRunner()
    
    if args.test_type == "list":
        runner.list_tests()
        return
    
    # Set up environment
    os.environ["PYTHONPATH"] = f"{os.environ.get('PYTHONPATH', '')}:{runner.src_dir}"
    
    # Run tests
    success = False
    
    if args.test_type == "unit":
        success = runner.run_unit_tests(args.verbose, args.coverage)
    elif args.test_type == "integration":
        success = runner.run_integration_tests(args.verbose, args.coverage)
    elif args.test_type == "e2e":
        success = runner.run_e2e_tests(args.verbose, args.coverage)
    elif args.test_type == "quick":
        success = runner.run_quick_tests()
    elif args.test_type == "ubuntu":
        success = runner.run_ubuntu_tests()
    elif args.test_type == "mysql":
        success = runner.run_mysql_check()
    elif args.test_type == "all":
        success = runner.run_all_tests(args.verbose, args.coverage)
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 