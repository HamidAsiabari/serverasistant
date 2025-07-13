"""
Menu system for ServerAssistant
"""

from typing import Dict, List, Callable, Any, Optional
from .display_utils import DisplayUtils, LogPanel, SimpleLogDisplay, RealTimeLogPanel, BottomLogDisplay
import threading
import time
from datetime import datetime
from core.docker_manager import DockerManager
from core.config_manager import ConfigManager


class MenuItem:
    """Represents a menu item"""
    
    def __init__(self, key: str, label: str, action: Callable, 
                 description: str = "", requires_confirmation: bool = False):
        self.key = key
        self.label = label
        self.action = action
        self.description = description
        self.requires_confirmation = requires_confirmation


class MenuSystem:
    """Menu system for handling user interactions"""
    
    def __init__(self):
        self.menus: Dict[str, List[MenuItem]] = {}
        self.current_menu: Optional[str] = None
        self.menu_stack: List[str] = []  # Navigation stack
        self.running = True
        
    def add_menu(self, menu_id: str, title: str):
        """Add a new menu"""
        if menu_id not in self.menus:
            self.menus[menu_id] = []
            
    def add_menu_item(self, menu_id: str, key: str, label: str, action: Callable,
                     description: str = "", requires_confirmation: bool = False):
        """Add an item to a menu"""
        if menu_id not in self.menus:
            self.add_menu(menu_id, "")
            
        menu_item = MenuItem(key, label, action, description, requires_confirmation)
        self.menus[menu_id].append(menu_item)
        
    def display_menu(self, menu_id: str, title: str):
        """Display a menu and handle user input"""
        if menu_id not in self.menus:
            DisplayUtils.print_error(f"Menu '{menu_id}' not found")
            return
            
        # Add current menu to stack (unless it's already there)
        if not self.menu_stack or self.menu_stack[-1] != menu_id:
            self.menu_stack.append(menu_id)
            
        self.current_menu = menu_id
        
        while self.running and self.current_menu == menu_id:
            DisplayUtils.clear_screen()
            DisplayUtils.print_banner()
            DisplayUtils.print_header(title)
            
            # Display menu items
            for item in self.menus[menu_id]:
                print(f"{item.key}. {item.label}")
                if item.description:
                    DisplayUtils.print_info(f"    {item.description}")
                    
            # Show appropriate back/exit option
            if menu_id == "main":
                print("\n0. Exit")
            else:
                print("\n0. Back")
            
            # Get user input
            choice = input("\nSelect an option: ").strip()
            
            if choice == "0":
                if menu_id == "main":
                    self.running = False
                else:
                    # Go back to previous menu
                    self.menu_stack.pop()  # Remove current menu from stack
                    if self.menu_stack:
                        # Return to previous menu
                        previous_menu = self.menu_stack[-1]
                        self.current_menu = None  # Break current loop
                        # Recursively call display_menu for the previous menu
                        self.display_menu(previous_menu, self._get_menu_title(previous_menu))
                    else:
                        # If no previous menu, go to main
                        self.current_menu = None
                        self.display_menu("main", "ServerAssistant - Main Menu")
                break
                
            # Find and execute selected action
            selected_item = None
            for item in self.menus[menu_id]:
                if item.key == choice:
                    selected_item = item
                    break
                    
            if selected_item:
                if selected_item.requires_confirmation:
                    confirm = input(f"Are you sure you want to {selected_item.label.lower()}? (y/N): ").strip().lower()
                    if confirm != 'y':
                        DisplayUtils.print_warning("Operation cancelled")
                        input("Press Enter to continue...")
                        continue
                        
                try:
                    selected_item.action()
                except Exception as e:
                    DisplayUtils.print_error(f"Error executing action: {e}")
                    
                input("Press Enter to continue...")
            else:
                DisplayUtils.print_warning("Invalid option. Please try again.")
                input("Press Enter to continue...")
                
    def _get_menu_title(self, menu_id: str) -> str:
        """Get the title for a menu"""
        if menu_id == "main":
            return "ServerAssistant - Main Menu"
        elif menu_id == "service_management":
            return "Service Management"
        elif menu_id == "setup":
            return "Setup & Installation"
        elif menu_id == "testing":
            return "Testing & Validation"
        else:
            return menu_id.replace("_", " ").title()
        
    def create_service_management_menu(self, server_assistant):
        """Create service management menu"""
        self.add_menu("service_management", "Service Management")
        
        self.add_menu_item("service_management", "1", "Start All Services",
                          lambda: server_assistant.start_all_services(),
                          "Start all enabled services")
                          
        self.add_menu_item("service_management", "2", "Stop All Services",
                          lambda: server_assistant.stop_all_services(),
                          "Stop all running services", True)
                          
        self.add_menu_item("service_management", "3", "Restart All Services",
                          lambda: server_assistant.restart_all_services(),
                          "Restart all services", True)
                          
        self.add_menu_item("service_management", "4", "Individual Service Control",
                          lambda: self._show_individual_service_menu(server_assistant),
                          "Control individual services")
                          
        self.add_menu_item("service_management", "5", "Service Status",
                          lambda: self._show_service_status(server_assistant),
                          "Show status of all services")
                          
        self.add_menu_item("service_management", "6", "Service Logs",
                          lambda: self._show_service_logs_menu(server_assistant),
                          "View service logs")
                          
    def create_setup_menu(self, server_assistant):
        """Create setup menu"""
        self.add_menu("setup", "Setup & Installation")
        
        self.add_menu_item("setup", "1", "Install Dependencies",
                          lambda: self._install_dependencies(server_assistant),
                          "Install system dependencies")
                          
        self.add_menu_item("setup", "2", "Setup GitLab Storage",
                          lambda: self._setup_gitlab_storage(server_assistant),
                          "Setup GitLab persistent storage")
                          
        self.add_menu_item("setup", "3", "Setup Mail Storage",
                          lambda: self._setup_mail_storage(server_assistant),
                          "Setup mail server persistent storage")
                          
        self.add_menu_item("setup", "4", "Generate SSL Certificates",
                          lambda: self._generate_ssl_certificates(server_assistant),
                          "Generate SSL certificates")
                          
        self.add_menu_item("setup", "5", "Complete System Setup",
                          lambda: self._complete_system_setup(server_assistant),
                          "Run complete system setup")
                          
    def create_testing_menu(self, server_assistant):
        """Create testing menu"""
        self.add_menu("testing", "Testing & Validation")
        
        self.add_menu_item("testing", "1", "Run All Tests",
                          lambda: self._run_all_tests(server_assistant),
                          "Run comprehensive system tests")
                          
        self.add_menu_item("testing", "2", "Test Docker Environment",
                          lambda: self._test_docker_environment(server_assistant),
                          "Test Docker installation and configuration")
                          
        self.add_menu_item("testing", "3", "Test GitLab",
                          lambda: self._test_gitlab(server_assistant),
                          "Test GitLab functionality")
                          
        self.add_menu_item("testing", "4", "Test Mail Server",
                          lambda: self._test_mail_server(server_assistant),
                          "Test mail server functionality")
                          
        self.add_menu_item("testing", "5", "Test Database Connections",
                          lambda: self._test_database_connections(server_assistant),
                          "Test database connectivity")
                          
    def create_main_menu(self, server_assistant):
        """Create main menu"""
        self.add_menu("main", "ServerAssistant - Main Menu")
        
        self.add_menu_item("main", "1", "Service Management",
                          lambda: self.display_menu("service_management", "Service Management"),
                          "Manage Docker services")
                          
        self.add_menu_item("main", "2", "Setup & Installation",
                          lambda: self.display_menu("setup", "Setup & Installation"),
                          "System setup and installation")
                          
        self.add_menu_item("main", "3", "Testing & Validation",
                          lambda: self.display_menu("testing", "Testing & Validation"),
                          "Test and validate system")
                          
        self.add_menu_item("main", "4", "Monitoring & Health",
                          lambda: self._show_monitoring_menu(server_assistant),
                          "Monitor system health")
                          
        self.add_menu_item("main", "5", "Backup & Restore",
                          lambda: self._show_backup_menu(server_assistant),
                          "Backup and restore services")
                          
        self.add_menu_item("main", "6", "Configuration",
                          lambda: self._show_configuration_menu(server_assistant),
                          "Manage configuration")
                          
        self.add_menu_item("main", "7", "System Information",
                          lambda: self._show_system_info(server_assistant),
                          "Display system information")
                          
    # Helper methods for menu actions
    def _show_individual_service_menu(self, server_assistant):
        """Show individual service control menu"""
        services = server_assistant.get_services()
        
        # Create a temporary menu for individual services
        temp_menu_id = "individual_services"
        self.add_menu(temp_menu_id, "Individual Service Control")
        
        # Add menu items for each service
        for i, (name, service) in enumerate(services.items(), 1):
            self.add_menu_item(temp_menu_id, str(i), name,
                              lambda s=name: self._show_service_control_menu(server_assistant, s),
                              f"Control {name} service")
        
        # Display the menu
        self.display_menu(temp_menu_id, "Individual Service Control")
        
        # Clean up temporary menu
        if temp_menu_id in self.menus:
            del self.menus[temp_menu_id]
        
    def _show_service_control_menu(self, server_assistant, service_name):
        """Show control menu for a specific service"""
        # Create a temporary menu for service control
        temp_menu_id = f"service_control_{service_name}"
        self.add_menu(temp_menu_id, f"Service Control - {service_name}")
        
        # Add menu items for service actions
        self.add_menu_item(temp_menu_id, "1", "Start Service",
                          lambda: server_assistant.start_service(service_name),
                          f"Start {service_name} service")
                          
        self.add_menu_item(temp_menu_id, "2", "Stop Service",
                          lambda: server_assistant.stop_service(service_name),
                          f"Stop {service_name} service", True)
                          
        self.add_menu_item(temp_menu_id, "3", "Restart Service",
                          lambda: server_assistant.restart_service(service_name),
                          f"Restart {service_name} service", True)
                          
        self.add_menu_item(temp_menu_id, "4", "View Logs",
                          lambda: self._show_service_logs(server_assistant, service_name),
                          f"View logs for {service_name}")
                          
        self.add_menu_item(temp_menu_id, "5", "Health Check",
                          lambda: server_assistant.health_check_service(service_name),
                          f"Perform health check on {service_name}")
        
        # Add special network fix option for nginx
        if service_name == "nginx":
            self.add_menu_item(temp_menu_id, "6", "Fix Network Issue",
                              lambda: self._fix_nginx_network_issue(server_assistant),
                              "Fix nginx network connectivity issues")
            self.add_menu_item(temp_menu_id, "7", "Fix Nginx Configuration",
                              lambda: self._fix_nginx_configuration(server_assistant),
                              "Fix nginx configuration for running services only")
            self.add_menu_item(temp_menu_id, "8", "Start Minimal Services",
                              lambda: self._start_minimal_services(server_assistant),
                              "Start only essential services needed for nginx")
        
        # Add special password fix option for gitlab
        if service_name == "gitlab":
            self.add_menu_item(temp_menu_id, "6", "Fix Password Issue",
                              lambda: self._fix_gitlab_password(server_assistant),
                              "Fix GitLab login password issues")
            self.add_menu_item(temp_menu_id, "7", "Quick Password Reset",
                              lambda: self._quick_reset_gitlab_password(server_assistant),
                              "Quickly reset GitLab root password")
        
        # Display the menu
        self.display_menu(temp_menu_id, f"Service Control - {service_name}")
        
        # Clean up temporary menu
        if temp_menu_id in self.menus:
            del self.menus[temp_menu_id]
            
    def _show_service_logs(self, server_assistant, service_name):
        """Show logs for a specific service"""
        # Add logging if using enhanced menu system
        if hasattr(self, 'log_panel'):
            self.log_panel.add_log(f"Fetching logs for {service_name}", "INFO")
        elif hasattr(self, 'log_display'):
            self.log_display.add_log(f"Fetching logs for {service_name}", "INFO")
            
        logs = server_assistant.get_service_logs(service_name)
        DisplayUtils.print_header(f"Logs - {service_name}")
        print(logs)
        
        # Add logging if using enhanced menu system
        if hasattr(self, 'log_panel'):
            if logs and logs.strip():
                self.log_panel.add_log(f"Logs retrieved for {service_name} ({len(logs)} chars)", "SUCCESS")
            else:
                self.log_panel.add_log(f"No logs available for {service_name}", "WARNING")
        elif hasattr(self, 'log_display'):
            if logs and logs.strip():
                self.log_display.add_log(f"Logs retrieved for {service_name} ({len(logs)} chars)", "SUCCESS")
            else:
                self.log_display.add_log(f"No logs available for {service_name}", "WARNING")
                
        input("Press Enter to continue...")
        
    def _show_service_status(self, server_assistant):
        """Show service status"""
        # Add logging if using enhanced menu system
        if hasattr(self, 'log_panel'):
            self.log_panel.add_log("Fetching service status...", "INFO")
        elif hasattr(self, 'log_display'):
            self.log_display.add_log("Fetching service status...", "INFO")
            
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
        
        # Add logging if using enhanced menu system
        if hasattr(self, 'log_panel'):
            running_count = sum(1 for s in service_data if s['status'] == 'running')
            self.log_panel.add_log(f"Status retrieved: {running_count}/{len(service_data)} services running", "SUCCESS")
        elif hasattr(self, 'log_display'):
            running_count = sum(1 for s in service_data if s['status'] == 'running')
            self.log_display.add_log(f"Status retrieved: {running_count}/{len(service_data)} services running", "SUCCESS")
        
    def _show_service_logs_menu(self, server_assistant):
        """Show service logs menu"""
        services = server_assistant.get_services()
        
        # Create a temporary menu for service logs
        temp_menu_id = "service_logs"
        self.add_menu(temp_menu_id, "Service Logs")
        
        # Add menu items for each service
        for i, (name, service) in enumerate(services.items(), 1):
            self.add_menu_item(temp_menu_id, str(i), name,
                              lambda s=name: self._show_service_logs(server_assistant, s),
                              f"View logs for {name}")
        
        # Display the menu
        self.display_menu(temp_menu_id, "Service Logs")
        
        # Clean up temporary menu
        if temp_menu_id in self.menus:
            del self.menus[temp_menu_id]
            
    def _fix_nginx_network_issue(self, server_assistant):
        """Fix nginx network issue by running the fix script"""
        import subprocess
        import os
        
        DisplayUtils.print_header("Fixing Nginx Network Issue")
        
        # Get the nginx directory path
        nginx_path = server_assistant.base_path / "docker_services" / "nginx"
        fix_script_path = nginx_path / "fix_network_issue.sh"
        
        if not fix_script_path.exists():
            DisplayUtils.print_error(f"Fix script not found: {fix_script_path}")
            input("Press Enter to continue...")
            return
            
        try:
            # Make script executable
            os.chmod(fix_script_path, 0o755)
            
            # Run the fix script
            DisplayUtils.print_info("Running network fix script...")
            result = subprocess.run(
                [str(fix_script_path)],
                cwd=nginx_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Display output
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                DisplayUtils.print_error(f"Script errors: {result.stderr}")
                
            if result.returncode == 0:
                DisplayUtils.print_success("Network fix completed successfully!")
            else:
                DisplayUtils.print_error(f"Network fix failed with return code: {result.returncode}")
                    
        except Exception as e:
            DisplayUtils.print_error(f"Error running network fix script: {e}")
                
        input("Press Enter to continue...")
            
    def _fix_nginx_configuration(self, server_assistant):
        """Fix nginx configuration for running services only"""
        import subprocess
        import os
        
        DisplayUtils.print_header("Fixing Nginx Configuration")
        
        # Get the nginx directory path
        nginx_path = server_assistant.base_path / "docker_services" / "nginx"
        fix_script_path = nginx_path / "fix_nginx_config.sh"
        
        if not fix_script_path.exists():
            DisplayUtils.print_error(f"Fix script not found: {fix_script_path}")
            input("Press Enter to continue...")
            return
            
        try:
            # Make script executable
            os.chmod(fix_script_path, 0o755)
            
            # Run the fix script
            DisplayUtils.print_info("Running nginx configuration fix script...")
            result = subprocess.run(
                [str(fix_script_path)],
                cwd=nginx_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Display output
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                DisplayUtils.print_error(f"Script errors: {result.stderr}")
                
            if result.returncode == 0:
                DisplayUtils.print_success("Nginx configuration fix completed successfully!")
            else:
                DisplayUtils.print_error(f"Nginx configuration fix failed with return code: {result.returncode}")
                    
        except Exception as e:
            DisplayUtils.print_error(f"Error running nginx configuration fix script: {e}")
                
        input("Press Enter to continue...")
            
    def _start_minimal_services(self, server_assistant):
        """Start minimal services needed for nginx"""
        import subprocess
        import os
        
        DisplayUtils.print_header("Starting Minimal Services")
        
        # Get the nginx directory path
        nginx_path = server_assistant.base_path / "docker_services" / "nginx"
        start_script_path = nginx_path / "start_minimal_services.sh"
        
        if not start_script_path.exists():
            DisplayUtils.print_error(f"Start script not found: {start_script_path}")
            input("Press Enter to continue...")
            return
            
        try:
            # Make script executable
            os.chmod(start_script_path, 0o755)
            
            # Run the start script
            DisplayUtils.print_info("Starting minimal services...")
            result = subprocess.run(
                [str(start_script_path)],
                cwd=nginx_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Display output
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                DisplayUtils.print_error(f"Script errors: {result.stderr}")
                
            if result.returncode == 0:
                DisplayUtils.print_success("Minimal services started successfully!")
            else:
                DisplayUtils.print_error(f"Failed to start minimal services (return code: {result.returncode})")
                    
        except Exception as e:
            DisplayUtils.print_error(f"Error starting minimal services: {e}")
                
        input("Press Enter to continue...")
            
    def _fix_gitlab_password(self, server_assistant):
        """Fix GitLab password issue by running the fix script"""
        import subprocess
        import os
        
        DisplayUtils.print_header("Fixing GitLab Password Issue")
        
        # Get the gitlab directory path
        gitlab_path = server_assistant.base_path / "docker_services" / "gitlab"
        fix_script_path = gitlab_path / "fix_gitlab_password.sh"
        
        if not fix_script_path.exists():
            DisplayUtils.print_error(f"Fix script not found: {fix_script_path}")
            DisplayUtils.print_info("Creating the fix script...")
            
            # Create the fix script if it doesn't exist
            self._create_gitlab_password_fix_script(gitlab_path)
            
        try:
            # Make script executable
            os.chmod(fix_script_path, 0o755)
            
            # Run the fix script
            DisplayUtils.print_info("Running GitLab password fix script...")
            result = subprocess.run(
                [str(fix_script_path)],
                cwd=gitlab_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Display output
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                DisplayUtils.print_error(f"Script errors: {result.stderr}")
                
            if result.returncode == 0:
                DisplayUtils.print_success("GitLab password fix completed successfully!")
            else:
                DisplayUtils.print_error(f"GitLab password fix failed with return code: {result.returncode}")
                    
        except Exception as e:
            DisplayUtils.print_error(f"Error running GitLab password fix script: {e}")
                
        input("Press Enter to continue...")
            
    def _quick_reset_gitlab_password(self, server_assistant):
        """Quickly reset GitLab root password"""
        import subprocess
        import os
        
        DisplayUtils.print_header("Quick GitLab Password Reset")
        
        # Get the gitlab directory path
        gitlab_path = server_assistant.base_path / "docker_services" / "gitlab"
        reset_script_path = gitlab_path / "quick_reset_password.sh"
        
        if not reset_script_path.exists():
            DisplayUtils.print_error(f"Reset script not found: {reset_script_path}")
            DisplayUtils.print_info("Creating the reset script...")
            
            # Create the reset script if it doesn't exist
            self._create_gitlab_quick_reset_script(gitlab_path)
            
        try:
            # Make script executable
            os.chmod(reset_script_path, 0o755)
            
            # Run the reset script
            DisplayUtils.print_info("Running GitLab password reset script...")
            result = subprocess.run(
                [str(reset_script_path)],
                cwd=gitlab_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            # Display output
            if result.stdout:
                print(result.stdout)
            if result.stderr:
                DisplayUtils.print_error(f"Script errors: {result.stderr}")
                
            if result.returncode == 0:
                DisplayUtils.print_success("GitLab password reset completed successfully!")
            else:
                DisplayUtils.print_error(f"GitLab password reset failed with return code: {result.returncode}")
                    
        except Exception as e:
            DisplayUtils.print_error(f"Error running GitLab password reset script: {e}")
                
        input("Press Enter to continue...")
            
    def _create_gitlab_password_fix_script(self, gitlab_path):
        """Create the GitLab password fix script if it doesn't exist"""
        script_content = '''#!/bin/bash

# GitLab Password Fix Script
# This script helps fix GitLab login issues by finding the initial password or resetting it

set -e

echo "=== GitLab Password Fix Script ==="

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitLab container is running
if ! docker ps | grep -q "gitlab"; then
    print_error "GitLab container is not running!"
    echo "Please start GitLab first:"
    echo "  cd docker_services/gitlab"
    echo "  docker-compose up -d"
    exit 1
fi

print_status "GitLab container is running"

# Method 1: Find the initial password from logs
print_status "Method 1: Finding initial password from logs..."
echo ""

# Look for the password in GitLab logs
PASSWORD_FROM_LOGS=$(docker logs gitlab 2>&1 | grep -i "password:" | tail -1)

if [ -n "$PASSWORD_FROM_LOGS" ]; then
    print_success "Found password in logs!"
    echo "Password line: $PASSWORD_FROM_LOGS"
    echo ""
    echo "Try logging in with:"
    echo "  Username: root"
    echo "  Password: (from the log line above)"
    echo ""
else
    print_warning "No password found in logs"
fi

# Method 2: Check if GitLab is fully initialized
print_status "Method 2: Checking GitLab initialization status..."
echo ""

# Check GitLab health
if docker exec gitlab /opt/gitlab/bin/gitlab-healthcheck --fail > /dev/null 2>&1; then
    print_success "GitLab is healthy and fully initialized"
else
    print_warning "GitLab is still initializing..."
    echo "This can take 5-10 minutes on first startup"
    echo "Please wait and try again later"
    echo ""
fi

# Method 3: Reset root password
print_status "Method 3: Reset root password (if needed)..."
echo ""

echo "If you need to reset the root password, you can:"
echo ""
echo "Option A: Use GitLab\\'s built-in password reset"
echo "  1. Go to http://gitlab.soject.com/users/password/new"
echo "  2. Enter \\'root\\' as the email"
echo "  3. Check the logs for the reset email:"
echo "     docker logs gitlab | grep -i \\'reset\\'"
echo ""

echo "Option B: Reset password via Rails console"
echo "  1. Execute this command:"
echo "     docker exec -it gitlab gitlab-rails console -e production"
echo "  2. In the Rails console, run:"
echo "     user = User.find_by_username(\\'root\\')"
echo "     user.password = \\'your_new_password\\'"
echo "     user.password_confirmation = \\'your_new_password\\'"
echo "     user.save!"
echo "     exit"
echo ""

echo "Option C: Use the quick reset script"
echo "  Run: ./quick_reset_password.sh"
echo ""

# Method 4: Check for common issues
print_status "Method 4: Checking for common issues..."
echo ""

# Check if GitLab is accessible
if curl -s http://localhost:8081 > /dev/null 2>&1; then
    print_success "GitLab is accessible on localhost:8081"
else
    print_warning "GitLab is not accessible on localhost:8081"
    echo "This might indicate an initialization issue"
fi

# Check recent logs for errors
print_status "Recent GitLab logs (last 20 lines):"
echo ""
docker logs gitlab --tail 20
echo ""

print_success "Password fix script completed!"
echo ""
echo "Next steps:"
echo "1. Try the password from the logs (Method 1)"
echo "2. If that doesn\\'t work, wait for GitLab to fully initialize"
echo "3. Use one of the reset options (Method 3) if needed"
echo "4. Check the logs for any error messages"
'''
        
        script_path = gitlab_path / "fix_gitlab_password.sh"
        with open(script_path, 'w') as f:
            f.write(script_content)
        
        DisplayUtils.print_success(f"Created GitLab password fix script: {script_path}")
        
    def _create_gitlab_quick_reset_script(self, gitlab_path):
        """Create the GitLab quick reset script if it doesn't exist"""
        script_content = '''#!/bin/bash

# Quick GitLab Password Reset Script
# This script quickly resets the GitLab root password

set -e

echo "=== Quick GitLab Password Reset ==="

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if GitLab container is running
if ! docker ps | grep -q "gitlab"; then
    print_error "GitLab container is not running!"
    echo "Please start GitLab first:"
    echo "  cd docker_services/gitlab"
    echo "  docker-compose up -d"
    exit 1
fi

# Check if GitLab is healthy
print_status "Checking GitLab health..."
if ! docker exec gitlab /opt/gitlab/bin/gitlab-healthcheck --fail > /dev/null 2>&1; then
    print_warning "GitLab is not fully initialized yet"
    echo "Please wait for GitLab to finish initializing (5-10 minutes)"
    echo "You can check the status with: docker logs gitlab"
    exit 1
fi

print_success "GitLab is healthy"

# Prompt for new password
echo ""
echo "Enter the new password for GitLab root user:"
read -s NEW_PASSWORD

if [ -z "$NEW_PASSWORD" ]; then
    print_error "Password cannot be empty"
    exit 1
fi

echo ""
echo "Confirm the new password:"
read -s CONFIRM_PASSWORD

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    print_error "Passwords do not match"
    exit 1
fi

print_status "Resetting GitLab root password..."

# Create a temporary script to run in the Rails console
cat > /tmp/gitlab_password_reset.rb << EOF
user = User.find_by_username('root')
if user
  user.password = '$NEW_PASSWORD'
  user.password_confirmation = '$NEW_PASSWORD'
  if user.save!
    puts "SUCCESS: Root password has been reset"
  else
    puts "ERROR: Failed to save password"
    puts user.errors.full_messages
  end
else
  puts "ERROR: Root user not found"
end
exit
EOF

# Execute the password reset
print_status "Executing password reset..."
if docker exec -i gitlab gitlab-rails console -e production < /tmp/gitlab_password_reset.rb; then
    print_success "Password reset completed!"
    echo ""
    echo "You can now login to GitLab with:"
    echo "  Username: root"
    echo "  Password: (the password you just set)"
    echo ""
    echo "URL: http://gitlab.soject.com"
else
    print_error "Password reset failed"
    echo "Please try the manual method:"
    echo "  docker exec -it gitlab gitlab-rails console -e production"
    echo "  Then run the commands manually"
fi

# Clean up temporary file
rm -f /tmp/gitlab_password_reset.rb

print_success "Script completed!"
'''
        
        script_path = gitlab_path / "quick_reset_password.sh"
        with open(script_path, 'w') as f:
            f.write(script_content)
        
        DisplayUtils.print_success(f"Created GitLab quick reset script: {script_path}")
            
    # Placeholder methods for other menu actions
    def _install_dependencies(self, server_assistant):
        DisplayUtils.print_info("Installing dependencies...")
        # Implementation would go here
        
    def _setup_gitlab_storage(self, server_assistant):
        DisplayUtils.print_info("Setting up GitLab storage...")
        # Implementation would go here
        
    def _setup_mail_storage(self, server_assistant):
        DisplayUtils.print_info("Setting up mail storage...")
        # Implementation would go here
        
    def _generate_ssl_certificates(self, server_assistant):
        DisplayUtils.print_info("Generating SSL certificates...")
        # Implementation would go here
        
    def _complete_system_setup(self, server_assistant):
        DisplayUtils.print_info("Running complete system setup...")
        # Implementation would go here
        
    def _run_all_tests(self, server_assistant):
        DisplayUtils.print_info("Running all tests...")
        # Implementation would go here
        
    def _test_docker_environment(self, server_assistant):
        DisplayUtils.print_info("Testing Docker environment...")
        # Implementation would go here
        
    def _test_gitlab(self, server_assistant):
        DisplayUtils.print_info("Testing GitLab...")
        # Implementation would go here
        
    def _test_mail_server(self, server_assistant):
        DisplayUtils.print_info("Testing mail server...")
        # Implementation would go here
        
    def _test_database_connections(self, server_assistant):
        DisplayUtils.print_info("Testing database connections...")
        # Implementation would go here
        
    def _show_monitoring_menu(self, server_assistant):
        DisplayUtils.print_info("Monitoring menu - not yet implemented")
        
    def _show_backup_menu(self, server_assistant):
        DisplayUtils.print_info("Backup menu - not yet implemented")
        
    def _show_configuration_menu(self, server_assistant):
        DisplayUtils.print_info("Configuration menu - not yet implemented")
        
    def _show_system_info(self, server_assistant):
        config = server_assistant.get_configuration()
        if config:
            DisplayUtils.print_configuration_summary(config.__dict__)
        else:
            DisplayUtils.print_error("No configuration available")


class SimpleEnhancedMenuSystem(MenuSystem):
    """Simplified enhanced menu system with simple log display after actions"""
    
    def __init__(self):
        super().__init__()
        self.log_display = SimpleLogDisplay(max_lines=10)
        
    def display_menu(self, menu_id: str, title: str):
        """Display a menu with simple log display after actions"""
        if menu_id not in self.menus:
            DisplayUtils.print_error(f"Menu '{menu_id}' not found")
            return
            
        # Add current menu to stack (unless it's already there)
        if not self.menu_stack or self.menu_stack[-1] != menu_id:
            self.menu_stack.append(menu_id)
            
        self.current_menu = menu_id
        
        # Add initial log
        self.log_display.add_log(f"Entered menu: {menu_id}", "INFO")
        
        while self.running and self.current_menu == menu_id:
            # Clear screen and show menu
            DisplayUtils.clear_screen()
            DisplayUtils.print_banner()
            DisplayUtils.print_header(title)
            
            # Display menu items
            for item in self.menus[menu_id]:
                print(f"{item.key}. {item.label}")
                if item.description:
                    DisplayUtils.print_info(f"    {item.description}")
                    
            print("\n0. Back" if menu_id != "main" else "\n0. Exit")
            
            # Get user input
            choice = input("\nSelect an option: ").strip()
            
            if choice == "0":
                if menu_id == "main":
                    self.log_display.add_log("User chose to exit", "INFO")
                    self.running = False
                else:
                    # Go back to previous menu
                    self.log_display.add_log(f"Going back from {menu_id}", "INFO")
                    self.menu_stack.pop()  # Remove current menu from stack
                    if self.menu_stack:
                        # Return to previous menu
                        previous_menu = self.menu_stack[-1]
                        self.current_menu = None  # Break current loop
                        # Recursively call display_menu for the previous menu
                        self.display_menu(previous_menu, self._get_menu_title(previous_menu))
                    else:
                        # If no previous menu, go to main
                        self.current_menu = None
                        self.display_menu("main", "ServerAssistant - Main Menu")
                break
                
            # Find and execute selected action
            selected_item = None
            for item in self.menus[menu_id]:
                if item.key == choice:
                    selected_item = item
                    break
                    
            if selected_item:
                # Log the action
                self.log_display.add_log(f"User selected: {selected_item.label}", "ACTION")
                
                if selected_item.requires_confirmation:
                    confirm = input(f"Are you sure you want to {selected_item.label.lower()}? (y/N): ").strip().lower()
                    if confirm != 'y':
                        self.log_display.add_log("Operation cancelled by user", "WARNING")
                        self.log_display.show_logs_after_action("Operation Cancelled")
                        continue
                        
                try:
                    # Execute the action
                    self.log_display.add_log(f"Executing: {selected_item.label}", "INFO")
                    selected_item.action()
                    self.log_display.add_log(f"Successfully executed: {selected_item.label}", "SUCCESS")
                    # Show logs after action
                    self.log_display.show_logs_after_action(selected_item.label)
                except Exception as e:
                    self.log_display.add_log(f"Error executing {selected_item.label}: {e}", "ERROR")
                    DisplayUtils.print_error(f"Error executing action: {e}")
                    self.log_display.show_logs_after_error(selected_item.label, str(e))
            else:
                self.log_display.add_log(f"Invalid option selected: {choice}", "WARNING")
                DisplayUtils.print_warning("Invalid option. Please try again.")
                self.log_display.show_logs_after_action("Invalid Selection")
        
    def log_action(self, message: str, level: str = "INFO"):
        """Add a log message"""
        self.log_display.add_log(message, level)
        
    def show_logs(self, title: str = "Recent Logs"):
        """Show current logs"""
        self.log_display.show_logs(title)
        
    def clear_logs(self):
        """Clear the logs"""
        self.log_display.clear()


class RealTimeEnhancedMenuSystem(MenuSystem):
    """Real-time enhanced menu system with persistent bottom log panel"""
    
    def __init__(self):
        super().__init__()
        self.log_panel = RealTimeLogPanel(max_lines=30)  # Increased for more debugging
        self.bottom_display = BottomLogDisplay(self.log_panel)
        self.refresh_thread = None
        self.auto_refresh = True
        
    def start_auto_refresh(self):
        """Start auto-refresh thread for the display"""
        if self.refresh_thread is None or not self.refresh_thread.is_alive():
            self.refresh_thread = threading.Thread(target=self._auto_refresh_loop, daemon=True)
            self.refresh_thread.start()
            
    def stop_auto_refresh(self):
        """Stop auto-refresh thread"""
        self.auto_refresh = False
        if self.refresh_thread and self.refresh_thread.is_alive():
            self.refresh_thread.join(timeout=1)
            
    def _auto_refresh_loop(self):
        """Auto-refresh loop for the display"""
        while self.auto_refresh and self.running:
            try:
                time.sleep(0.3)  # Refresh every 300ms for smoother updates
            except KeyboardInterrupt:
                break
                
    def display_menu(self, menu_id: str, title: str):
        """Display a menu with persistent bottom logs"""
        if menu_id not in self.menus:
            DisplayUtils.print_error(f"Menu '{menu_id}' not found")
            return
            
        # Add current menu to stack (unless it's already there)
        if not self.menu_stack or self.menu_stack[-1] != menu_id:
            self.menu_stack.append(menu_id)
            
        self.current_menu = menu_id
        
        # Add initial log
        self.log_panel.add_log(f"Entered menu: {menu_id}", "INFO")
        
        # Start auto-refresh
        self.start_auto_refresh()
        
        while self.running and self.current_menu == menu_id:
            # Build menu items for display
            menu_items = []
            for item in self.menus[menu_id]:
                menu_items.append({
                    'key': item.key,
                    'label': item.label,
                    'description': item.description
                })
            
            # Display menu with bottom logs
            self.bottom_display.print_menu_with_logs(title, menu_items)
            
            # Get user input
            choice = input("\nSelect an option: ").strip()
            
            if choice == "0":
                if menu_id == "main":
                    self.log_panel.add_log("User chose to exit", "INFO")
                    self.running = False
                else:
                    # Go back to previous menu
                    self.log_panel.add_log(f"Going back from {menu_id}", "INFO")
                    self.menu_stack.pop()  # Remove current menu from stack
                    if self.menu_stack:
                        # Return to previous menu
                        previous_menu = self.menu_stack[-1]
                        self.current_menu = None  # Break current loop
                        # Recursively call display_menu for the previous menu
                        self.display_menu(previous_menu, self._get_menu_title(previous_menu))
                    else:
                        # If no previous menu, go to main
                        self.current_menu = None
                        self.display_menu("main", "ServerAssistant - Main Menu")
                break
                
            # Find and execute selected action
            selected_item = None
            for item in self.menus[menu_id]:
                if item.key == choice:
                    selected_item = item
                    break
                    
            if selected_item:
                # Log the action
                self.log_panel.add_log(f"User selected: {selected_item.label}", "ACTION")
                
                if selected_item.requires_confirmation:
                    confirm = input(f"Are you sure you want to {selected_item.label.lower()}? (y/N): ").strip().lower()
                    if confirm != 'y':
                        self.log_panel.add_log("Operation cancelled by user", "WARNING")
                        continue
                        
                try:
                    # Execute the action
                    self.log_panel.add_log(f"Executing: {selected_item.label}", "INFO")
                    selected_item.action()
                    self.log_panel.add_log(f"Successfully executed: {selected_item.label}", "SUCCESS")
                except Exception as e:
                    self.log_panel.add_log(f"Error executing {selected_item.label}: {e}", "ERROR")
                    DisplayUtils.print_error(f"Error executing action: {e}")
                    
                # Brief pause to show the result
                input("Press Enter to continue...")
            else:
                self.log_panel.add_log(f"Invalid option selected: {choice}", "WARNING")
                DisplayUtils.print_warning("Invalid option. Please try again.")
                input("Press Enter to continue...")
                
    def log_action(self, message: str, level: str = "INFO"):
        """Add a log message to the real-time panel"""
        self.log_panel.add_log(message, level)
        
    def show_logs(self, title: str = "Recent Logs"):
        """Show current logs (for compatibility)"""
        logs = self.log_panel.get_logs()
        print(f"\n{title}")
        print("-" * len(title))
        for log in logs:
            print(log)
        print("-" * len(title))
        
    def clear_logs(self):
        """Clear the logs"""
        self.log_panel.clear()
        
    def cleanup(self):
        """Cleanup resources"""
        self.stop_auto_refresh() 