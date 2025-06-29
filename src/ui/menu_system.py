"""
Menu system for ServerAssistant
"""

from typing import Dict, List, Callable, Any, Optional
from .display_utils import DisplayUtils


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
                    
            print("\n0. Back" if menu_id != "main" else "\n0. Exit")
            
            # Get user input
            choice = input("\nSelect an option: ").strip()
            
            if choice == "0":
                if menu_id == "main":
                    self.running = False
                else:
                    self.current_menu = None
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
                          
        self.add_menu_item("setup", "2", "Setup Nginx",
                          lambda: self._setup_nginx(server_assistant),
                          "Setup Nginx reverse proxy")
                          
        self.add_menu_item("setup", "3", "Setup GitLab Storage",
                          lambda: self._setup_gitlab_storage(server_assistant),
                          "Setup GitLab persistent storage")
                          
        self.add_menu_item("setup", "4", "Setup Mail Storage",
                          lambda: self._setup_mail_storage(server_assistant),
                          "Setup mail server persistent storage")
                          
        self.add_menu_item("setup", "5", "Generate SSL Certificates",
                          lambda: self._generate_ssl_certificates(server_assistant),
                          "Generate SSL certificates")
                          
        self.add_menu_item("setup", "6", "Complete System Setup",
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
                          
        self.add_menu_item("testing", "3", "Test Nginx Setup",
                          lambda: self._test_nginx_setup(server_assistant),
                          "Test Nginx configuration and connectivity")
                          
        self.add_menu_item("testing", "4", "Test GitLab",
                          lambda: self._test_gitlab(server_assistant),
                          "Test GitLab functionality")
                          
        self.add_menu_item("testing", "5", "Test Mail Server",
                          lambda: self._test_mail_server(server_assistant),
                          "Test mail server functionality")
                          
        self.add_menu_item("testing", "6", "Test Database Connections",
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
        
        DisplayUtils.print_header("Individual Service Control")
        
        for i, (name, service) in enumerate(services.items(), 1):
            print(f"{i}. {name}")
            
        print("0. Back")
        
        choice = input("\nSelect a service: ").strip()
        
        if choice == "0":
            return
            
        try:
            service_index = int(choice) - 1
            service_names = list(services.keys())
            
            if 0 <= service_index < len(service_names):
                service_name = service_names[service_index]
                self._show_service_control_menu(server_assistant, service_name)
            else:
                DisplayUtils.print_warning("Invalid service selection")
        except ValueError:
            DisplayUtils.print_warning("Invalid input")
            
    def _show_service_control_menu(self, server_assistant, service_name):
        """Show control menu for a specific service"""
        DisplayUtils.print_header(f"Service Control - {service_name}")
        
        print("1. Start Service")
        print("2. Stop Service")
        print("3. Restart Service")
        print("4. View Logs")
        print("5. Health Check")
        print("0. Back")
        
        choice = input("\nSelect an action: ").strip()
        
        if choice == "1":
            server_assistant.start_service(service_name)
        elif choice == "2":
            server_assistant.stop_service(service_name)
        elif choice == "3":
            server_assistant.restart_service(service_name)
        elif choice == "4":
            logs = server_assistant.get_service_logs(service_name)
            DisplayUtils.print_header(f"Logs - {service_name}")
            print(logs)
        elif choice == "5":
            server_assistant.health_check_service(service_name)
        elif choice == "0":
            return
        else:
            DisplayUtils.print_warning("Invalid option")
            
    def _show_service_status(self, server_assistant):
        """Show service status"""
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
        
    def _show_service_logs_menu(self, server_assistant):
        """Show service logs menu"""
        services = server_assistant.get_services()
        
        DisplayUtils.print_header("Service Logs")
        
        for i, (name, service) in enumerate(services.items(), 1):
            print(f"{i}. {name}")
            
        print("0. Back")
        
        choice = input("\nSelect a service: ").strip()
        
        if choice == "0":
            return
            
        try:
            service_index = int(choice) - 1
            service_names = list(services.keys())
            
            if 0 <= service_index < len(service_names):
                service_name = service_names[service_index]
                logs = server_assistant.get_service_logs(service_name)
                DisplayUtils.print_header(f"Logs - {service_name}")
                print(logs)
            else:
                DisplayUtils.print_warning("Invalid service selection")
        except ValueError:
            DisplayUtils.print_warning("Invalid input")
            
    # Placeholder methods for other menu actions
    def _install_dependencies(self, server_assistant):
        DisplayUtils.print_info("Installing dependencies...")
        # Implementation would go here
        
    def _setup_nginx(self, server_assistant):
        DisplayUtils.print_info("Setting up Nginx...")
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
        
    def _test_nginx_setup(self, server_assistant):
        DisplayUtils.print_info("Testing Nginx setup...")
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