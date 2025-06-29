#!/usr/bin/env python3
"""
Universal ServerAssistant Launcher
Works on both Windows and Linux
"""

import os
import sys
import subprocess
import platform
from pathlib import Path

def print_status(message):
    """Print status message"""
    print(f"[INFO] {message}")

def print_success(message):
    """Print success message"""
    print(f"[SUCCESS] {message}")

def print_error(message):
    """Print error message"""
    print(f"[ERROR] {message}")

def print_warning(message):
    """Print warning message"""
    print(f"[WARNING] {message}")

def run_command(command, cwd=None):
    """Run a command and return success status"""
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            cwd=cwd,
            capture_output=True, 
            text=True
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def check_first_time():
    """Check if this is first-time setup"""
    first_time_file = Path(__file__).parent / ".first_time_setup_complete"
    return not first_time_file.exists()

def mark_first_time_complete():
    """Mark first-time setup as complete"""
    first_time_file = Path(__file__).parent / ".first_time_setup_complete"
    from datetime import datetime
    with open(first_time_file, 'w') as f:
        f.write(f"{datetime.now()}: First-time setup completed successfully\n")

def check_python():
    """Check Python installation"""
    print_status("Checking Python installation...")
    success, stdout, stderr = run_command("python --version")
    if success:
        print_success(f"Python found: {stdout.strip()}")
        return True
    else:
        print_error("Python not found. Please install Python 3.7+ first.")
        return False

def check_venv():
    """Check if virtual environment exists"""
    venv_dir = Path(__file__).parent / "venv"
    venv_activate = venv_dir / "bin" / "activate" if platform.system() != "Windows" else venv_dir / "Scripts" / "activate.bat"
    
    if venv_dir.exists() and venv_activate.exists():
        print_success("Virtual environment found")
        return True
    else:
        print_warning("Virtual environment not found")
        return False

def create_venv():
    """Create virtual environment"""
    print_status("Creating virtual environment...")
    
    venv_dir = Path(__file__).parent / "venv"
    
    # Install python3-venv on Linux if needed
    if platform.system() == "Linux":
        success, stdout, stderr = run_command("dpkg -l | grep python3-venv")
        if not success:
            print_status("Installing python3-venv...")
            run_command("sudo apt update")
            run_command("sudo apt install -y python3-venv python3-pip")
    
    # Create virtual environment
    success, stdout, stderr = run_command("python -m venv venv")
    if success:
        print_success(f"Virtual environment created at {venv_dir}")
        return True
    else:
        print_error(f"Failed to create virtual environment: {stderr}")
        return False

def get_venv_python():
    """Get the Python executable from virtual environment"""
    venv_dir = Path(__file__).parent / "venv"
    
    if platform.system() == "Windows":
        return venv_dir / "Scripts" / "python.exe"
    else:
        return venv_dir / "bin" / "python"

def get_venv_pip():
    """Get the pip executable from virtual environment"""
    venv_dir = Path(__file__).parent / "venv"
    
    if platform.system() == "Windows":
        return venv_dir / "Scripts" / "pip.exe"
    else:
        return venv_dir / "bin" / "pip"

def check_docker():
    """Check Docker installation"""
    print_status("Checking Docker installation...")
    success, stdout, stderr = run_command("docker --version")
    if success:
        print_success(f"Docker found: {stdout.strip()}")
        return True
    else:
        print_error("Docker not found. Please install Docker first.")
        return False

def check_docker_compose():
    """Check Docker Compose installation"""
    print_status("Checking Docker Compose installation...")
    success, stdout, stderr = run_command("docker-compose --version")
    if success:
        print_success(f"Docker Compose found: {stdout.strip()}")
        return True
    else:
        print_error("Docker Compose not found. Please install Docker Compose first.")
        return False

def check_docker_daemon():
    """Check if Docker daemon is running"""
    print_status("Checking Docker daemon...")
    success, stdout, stderr = run_command("docker info")
    if success:
        print_success("Docker daemon is running")
        return True
    else:
        print_error("Docker daemon is not running. Please start Docker first.")
        return False

def install_python_dependencies():
    """Install Python dependencies in virtual environment"""
    print_status("Installing Python dependencies in virtual environment...")
    
    if Path("requirements.txt").exists():
        venv_pip = get_venv_pip()
        if venv_pip.exists():
            # Upgrade pip first
            success, stdout, stderr = run_command(f'"{venv_pip}" install --upgrade pip')
            if not success:
                print_warning(f"Failed to upgrade pip: {stderr}")
            
            # Install requirements
            success, stdout, stderr = run_command(f'"{venv_pip}" install -r requirements.txt')
            if success:
                print_success("Python dependencies installed in virtual environment")
            else:
                print_warning(f"Failed to install Python dependencies: {stderr}")
        else:
            print_error("Virtual environment pip not found")
    else:
        print_warning("requirements.txt not found, skipping Python dependencies")

def install_system_dependencies():
    """Install system dependencies"""
    print_status("Installing system dependencies...")
    
    if platform.system() == "Windows":
        if Path("install_requirements.ps1").exists():
            success, stdout, stderr = run_command("powershell -ExecutionPolicy Bypass -File install_requirements.ps1")
            if success:
                print_success("System dependencies installed")
            else:
                print_warning(f"Failed to install system dependencies: {stderr}")
        else:
            print_warning("install_requirements.ps1 not found, skipping system dependencies")
    else:
        if Path("install_requirements.sh").exists():
            success, stdout, stderr = run_command("chmod +x install_requirements.sh && ./install_requirements.sh")
            if success:
                print_success("System dependencies installed")
            else:
                print_warning(f"Failed to install system dependencies: {stderr}")
        else:
            print_warning("install_requirements.sh not found, skipping system dependencies")

def fix_environment():
    """Fix environment issues"""
    print_status("Fixing environment issues...")
    
    if platform.system() == "Windows":
        if Path("fix_line_endings.bat").exists():
            success, stdout, stderr = run_command("fix_line_endings.bat")
            if success:
                print_success("Line endings fixed")
    else:
        if Path("fix_line_endings.sh").exists():
            success, stdout, stderr = run_command("chmod +x fix_line_endings.sh && ./fix_line_endings.sh")
            if success:
                print_success("Line endings fixed")
        
        if Path("fix_permissions.sh").exists():
            success, stdout, stderr = run_command("chmod +x fix_permissions.sh && ./fix_permissions.sh")
            if success:
                print_success("Permissions fixed")
        
        # Make all shell scripts executable
        for script in Path(".").rglob("*.sh"):
            run_command(f"chmod +x {script}")
        print_success("Script permissions updated")

def setup_persistent_storage():
    """Setup persistent storage"""
    print_status("Setting up persistent storage...")
    
    # GitLab persistent storage
    gitlab_path = Path("example_services/gitlab")
    if gitlab_path.exists():
        if platform.system() == "Windows":
            setup_script = gitlab_path / "setup_persistent_storage.bat"
            if setup_script.exists():
                success, stdout, stderr = run_command("setup_persistent_storage.bat", cwd=gitlab_path)
                if success:
                    print_success("GitLab persistent storage setup completed")
        else:
            setup_script = gitlab_path / "setup_persistent_storage.sh"
            if setup_script.exists():
                success, stdout, stderr = run_command("chmod +x setup_persistent_storage.sh && ./setup_persistent_storage.sh", cwd=gitlab_path)
                if success:
                    print_success("GitLab persistent storage setup completed")
    
    # Mail server persistent storage
    mail_path = Path("example_services/mail-server")
    if mail_path.exists():
        if platform.system() == "Windows":
            setup_script = mail_path / "setup_persistent_storage.bat"
            if setup_script.exists():
                success, stdout, stderr = run_command("setup_persistent_storage.bat", cwd=mail_path)
                if success:
                    print_success("Mail server persistent storage setup completed")
        else:
            setup_script = mail_path / "setup_persistent_storage.sh"
            if setup_script.exists():
                success, stdout, stderr = run_command("chmod +x setup_persistent_storage.sh && ./setup_persistent_storage.sh", cwd=mail_path)
                if success:
                    print_success("Mail server persistent storage setup completed")

def setup_nginx():
    """Setup Nginx"""
    print_status("Setting up Nginx reverse proxy...")
    
    nginx_path = Path("example_services/nginx")
    if nginx_path.exists():
        if platform.system() == "Windows":
            setup_script = nginx_path / "setup_nginx.bat"
            if setup_script.exists():
                success, stdout, stderr = run_command("setup_nginx.bat", cwd=nginx_path)
                if success:
                    print_success("Nginx setup completed")
        else:
            setup_script = nginx_path / "setup_nginx.sh"
            if setup_script.exists():
                success, stdout, stderr = run_command("chmod +x setup_nginx.sh && ./setup_nginx.sh", cwd=nginx_path)
                if success:
                    print_success("Nginx setup completed")

def generate_ssl():
    """Generate SSL certificates"""
    print_status("Generating SSL certificates...")
    
    nginx_path = Path("example_services/nginx")
    if nginx_path.exists():
        if platform.system() == "Windows":
            ssl_script = nginx_path / "generate_ssl.bat"
            if ssl_script.exists():
                success, stdout, stderr = run_command("generate_ssl.bat", cwd=nginx_path)
                if success:
                    print_success("SSL certificates generated")
        else:
            ssl_script = nginx_path / "generate_ssl.sh"
            if ssl_script.exists():
                success, stdout, stderr = run_command("chmod +x generate_ssl.sh && ./generate_ssl.sh", cwd=nginx_path)
                if success:
                    print_success("SSL certificates generated")

def perform_first_time_setup():
    """Perform first-time setup"""
    print_status("Performing first-time setup...")
    
    # Check prerequisites
    if not check_python():
        return False
    if not check_docker():
        return False
    if not check_docker_compose():
        return False
    if not check_docker_daemon():
        return False
    
    # Create virtual environment if needed
    if not check_venv():
        if not create_venv():
            return False
    
    # Install dependencies
    install_python_dependencies()
    install_system_dependencies()
    
    # Fix environment
    fix_environment()
    
    # Setup persistent storage
    setup_persistent_storage()
    
    # Setup Nginx
    setup_nginx()
    
    # Generate SSL certificates
    generate_ssl()
    
    # Mark first-time setup as complete
    mark_first_time_complete()
    print_success("First-time setup completed!")
    return True

def launch_serverassistant():
    """Launch ServerAssistant"""
    print_status("Launching ServerAssistant...")
    print()
    
    if Path("serverassistant.py").exists():
        venv_python = get_venv_python()
        if venv_python.exists():
            success, stdout, stderr = run_command(f'"{venv_python}" serverassistant.py')
            if not success:
                print_error(f"Failed to launch ServerAssistant: {stderr}")
                return False
            return True
        else:
            print_error("Virtual environment Python not found")
            return False
    else:
        print_error("serverassistant.py not found!")
        return False

def main():
    """Main function"""
    print("=" * 50)
    print("    ServerAssistant Startup Script")
    print("=" * 50)
    print()
    
    # Change to script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Check if this is first time
    if check_first_time():
        print_warning("First-time setup detected!")
        if not perform_first_time_setup():
            print_error("First-time setup failed!")
            return 1
    else:
        print_success("Previous setup detected. Skipping installation.")
    
    # Launch ServerAssistant
    if not launch_serverassistant():
        return 1
    
    return 0

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\nGoodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1) 