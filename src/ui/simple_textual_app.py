"""
Simplified Textual-based GUI for ServerAssistant
"""

import sys
from pathlib import Path
from typing import Dict, List, Optional

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from textual.app import App, ComposeResult
    from textual.containers import Container, Horizontal, Vertical
    from textual.widgets import (
        Button, DataTable, Header, Footer, Static, Label, 
        Select, Log, Switch, TabbedContent, TabPane
    )
    from textual import work
    from textual.binding import Binding
    from textual.css.query import DOMQuery
    
    # Import our modules
    from src.core.server_assistant import ServerAssistant
    from src.core.docker_manager import ServiceStatus
    
    TEXTUAL_AVAILABLE = True
except ImportError as e:
    print(f"Textual not available: {e}")
    print("Please install textual: pip install textual>=0.52.0")
    TEXTUAL_AVAILABLE = False


class ServiceCard(Static):
    """Simple service card widget"""
    
    def __init__(self, service_name: str, status: str, enabled: bool = True):
        super().__init__(classes="service-card")
        self.service_name = service_name
        self.status = status
        self.enabled = enabled
        
    def compose(self) -> ComposeResult:
        with Vertical():
            yield Label(f"📦 {self.service_name}", classes="service-title")
            yield Label(f"Status: {self.status}", classes="service-status")
            with Horizontal(classes="service-controls"):
                yield Button("Start", id=f"start-{self.service_name}", variant="success")
                yield Button("Stop", id=f"stop-{self.service_name}", variant="error")
                yield Button("Restart", id=f"restart-{self.service_name}", variant="warning")
                yield Button("Logs", id=f"logs-{self.service_name}", variant="primary")


class DashboardScreen(Static):
    """Dashboard screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="dashboard"):
            yield Label("🚀 Server Assistant Dashboard", classes="dashboard-title")
            yield Button("Refresh", id="refresh-dashboard", variant="primary")
            
            with Container(id="services-container", classes="services-container"):
                # Services will be added dynamically
                pass


class ServicesScreen(Static):
    """Services management screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="services-screen"):
            yield Label("🔧 Services Management", classes="screen-title")
            
            with Horizontal(classes="services-header"):
                yield Button("Start All", id="start-all", variant="success")
                yield Button("Stop All", id="stop-all", variant="error")
                yield Button("Refresh", id="refresh-services", variant="primary")
                
            yield DataTable(id="services-table", classes="services-table")


class LogsScreen(Static):
    """Logs viewing screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="logs-screen"):
            yield Label("📋 Service Logs", classes="screen-title")
            
            with Horizontal(classes="logs-header"):
                service_names = list(self.server_assistant.get_services().keys())
                yield Select(
                    [(name, name) for name in service_names],
                    placeholder="Select service...",
                    id="service-selector"
                )
                yield Button("Refresh", id="refresh-logs", variant="primary")
                
            yield Log(id="main-log-viewer", classes="main-log-viewer")


class SettingsScreen(Static):
    """Settings screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="settings-screen"):
            yield Label("⚙️ Settings", classes="screen-title")
            
            config = self.server_assistant.get_configuration()
            if config:
                yield Label(f"Server Name: {config.server_name}")
                yield Label(f"Environment: {config.environment}")
                yield Label(f"Log Level: {config.log_level}")
            
            docker_status = "✅ Available" if self.server_assistant.check_docker_environment() else "❌ Not Available"
            yield Label(f"Docker: {docker_status}")


class SimpleServerAssistantApp(App):
    """Simplified Textual application for ServerAssistant"""
    
    CSS_PATH = "simple_textual_app.tcss"
    TITLE = "Server Assistant"
    SUB_TITLE = "Docker Service Manager"
    
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("r", "refresh", "Refresh"),
        Binding("1", "show_dashboard", "Dashboard"),
        Binding("2", "show_services", "Services"),
        Binding("3", "show_logs", "Logs"),
        Binding("4", "show_settings", "Settings"),
    ]
    
    def __init__(self, config_path: str = "config.json"):
        super().__init__()
        self.server_assistant = ServerAssistant(config_path)
        
    def compose(self) -> ComposeResult:
        """Create child widgets for the app."""
        yield Header(show_clock=True)
        
        with TabbedContent(id="main-tabs"):
            with TabPane("Dashboard", id="dashboard-tab"):
                yield DashboardScreen(self.server_assistant)
                
            with TabPane("Services", id="services-tab"):
                yield ServicesScreen(self.server_assistant)
                
            with TabPane("Logs", id="logs-tab"):
                yield LogsScreen(self.server_assistant)
                
            with TabPane("Settings", id="settings-tab"):
                yield SettingsScreen(self.server_assistant)
                
        yield Footer()
        
    def on_mount(self) -> None:
        """Called when the app is mounted."""
        self.refresh_data()
        self.initialize_logs_screen()
        
    def initialize_logs_screen(self) -> None:
        """Initialize the logs screen with helpful information."""
        logs_screen = self.query_one("#logs-tab")
        log_viewer = logs_screen.query_one("#main-log-viewer")
        
        welcome_message = """📋 Service Logs Viewer

Welcome to the logs viewer! Here's how to use it:

1. Select a service from the dropdown above
2. Click "Refresh" to reload logs
3. Use the "Logs" button on service cards to quickly view logs

Note: You can only view logs for running services. If a service is stopped, start it first to see its logs.

Available services:
"""
        
        services = self.server_assistant.get_services()
        for service_name in services.keys():
            welcome_message += f"• {service_name}\n"
            
        log_viewer.write(welcome_message)
        
    @work
    def refresh_data(self) -> None:
        """Refresh all data from the server assistant."""
        try:
            # Get all service statuses
            statuses = self.server_assistant.get_all_service_status()
            services = self.server_assistant.get_services()
            
            # Update dashboard
            self.update_dashboard(statuses, services)
            
            # Update services table
            self.update_services_table(statuses, services)
            
        except Exception as e:
            self.notify(f"Error refreshing data: {e}", severity="error")
            
    def update_dashboard(self, statuses: List[ServiceStatus], services: Dict):
        """Update dashboard with current data."""
        dashboard = self.query_one("#dashboard-tab")
        services_container = dashboard.query_one("#services-container")
        
        # Clear existing services
        services_container.remove_children()
        
        # Add service cards
        for service_name, service_config in services.items():
            status = next((s for s in statuses if s.name == service_name), None)
            status_text = status.status if status else "unknown"
            enabled = service_config.get("enabled", False)
            
            service_card = ServiceCard(service_name, status_text, enabled)
            services_container.mount(service_card)
            
    def update_services_table(self, statuses: List[ServiceStatus], services: Dict):
        """Update services table."""
        services_screen = self.query_one("#services-tab")
        table = services_screen.query_one("#services-table")
        
        # Clear existing data
        table.clear(columns=True)
        
        # Add columns
        table.add_columns("Name", "Status", "Container ID", "Ports", "Health")
        
        # Add rows
        for status in statuses:
            service_config = services.get(status.name, {})
            ports = ", ".join(service_config.get("ports", []))
            container_id = status.container_id[:12] + "..." if status.container_id else "N/A"
            
            table.add_row(
                status.name,
                status.status,
                container_id,
                ports,
                status.health or "N/A"
            )
            
    def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button press events."""
        button_id = event.button.id
        
        if button_id == "refresh-dashboard" or button_id == "refresh-services":
            self.refresh_data()
            
        elif button_id == "start-all":
            self.start_all_services()
            
        elif button_id == "stop-all":
            self.stop_all_services()
            
        elif button_id.startswith("start-"):
            service_name = button_id.replace("start-", "")
            self.start_service(service_name)
            
        elif button_id.startswith("stop-"):
            service_name = button_id.replace("stop-", "")
            self.stop_service(service_name)
            
        elif button_id.startswith("restart-"):
            service_name = button_id.replace("restart-", "")
            self.restart_service(service_name)
            
        elif button_id.startswith("logs-"):
            service_name = button_id.replace("logs-", "")
            self.show_service_logs(service_name)
            
        elif button_id == "refresh-logs":
            # Get currently selected service from the selector
            logs_screen = self.query_one("#logs-tab")
            service_selector = logs_screen.query_one("#service-selector")
            current_service = service_selector.value
            
            if current_service:
                self.show_service_logs(current_service)
            else:
                self.notify("Please select a service first", severity="warning")
            
    @work
    def start_service(self, service_name: str) -> None:
        """Start a service."""
        try:
            success = self.server_assistant.start_service(service_name)
            if success:
                self.notify(f"Service {service_name} started successfully", severity="information")
            else:
                self.notify(f"Failed to start service {service_name}", severity="error")
            self.refresh_data()
        except Exception as e:
            self.notify(f"Error starting service: {e}", severity="error")
            
    @work
    def stop_service(self, service_name: str) -> None:
        """Stop a service."""
        try:
            success = self.server_assistant.stop_service(service_name)
            if success:
                self.notify(f"Service {service_name} stopped successfully", severity="information")
            else:
                self.notify(f"Failed to stop service {service_name}", severity="error")
            self.refresh_data()
        except Exception as e:
            self.notify(f"Error stopping service: {e}", severity="error")
            
    @work
    def restart_service(self, service_name: str) -> None:
        """Restart a service."""
        try:
            success = self.server_assistant.restart_service(service_name)
            if success:
                self.notify(f"Service {service_name} restarted successfully", severity="information")
            else:
                self.notify(f"Failed to restart service {service_name}", severity="error")
            self.refresh_data()
        except Exception as e:
            self.notify(f"Error restarting service: {e}", severity="error")
            
    @work
    def start_all_services(self) -> None:
        """Start all services."""
        try:
            results = self.server_assistant.start_all_services()
            success_count = sum(1 for success in results.values() if success)
            self.notify(f"Started {success_count}/{len(results)} services", severity="information")
            self.refresh_data()
        except Exception as e:
            self.notify(f"Error starting all services: {e}", severity="error")
            
    @work
    def stop_all_services(self) -> None:
        """Stop all services."""
        try:
            results = self.server_assistant.stop_all_services()
            success_count = sum(1 for success in results.values() if success)
            self.notify(f"Stopped {success_count}/{len(results)} services", severity="information")
            self.refresh_data()
        except Exception as e:
            self.notify(f"Error stopping all services: {e}", severity="error")
            
    def show_service_logs(self, service_name: str) -> None:
        """Show logs for a service."""
        try:
            # Show loading message
            logs_screen = self.query_one("#logs-tab")
            log_viewer = logs_screen.query_one("#main-log-viewer")
            log_viewer.clear()
            log_viewer.write(f"Loading logs for {service_name}...")
            
            # Get logs
            logs = self.server_assistant.get_service_logs(service_name)
            
            # Clear and display logs
            log_viewer.clear()
            if logs:
                log_viewer.write(logs)
            else:
                log_viewer.write(f"No logs available for {service_name}")
            
            # Switch to logs tab
            self.query_one("#main-tabs").active = "logs-tab"
            
            # Show notification
            self.notify(f"Logs loaded for {service_name}", severity="information")
            
        except Exception as e:
            logs_screen = self.query_one("#logs-tab")
            log_viewer = logs_screen.query_one("#main-log-viewer")
            log_viewer.clear()
            log_viewer.write(f"Error getting logs for {service_name}: {str(e)}")
            self.notify(f"Error getting logs: {e}", severity="error")
            
    def on_select_changed(self, event: Select.Changed) -> None:
        """Handle select widget changes."""
        if event.select.id == "service-selector":
            service_name = event.value
            if service_name:
                self.show_service_logs(service_name)
            
    def action_refresh(self) -> None:
        """Refresh data."""
        self.refresh_data()
        
    def action_show_dashboard(self) -> None:
        """Show dashboard tab."""
        self.query_one("#main-tabs").active = "dashboard-tab"
        
    def action_show_services(self) -> None:
        """Show services tab."""
        self.query_one("#main-tabs").active = "services-tab"
        
    def action_show_logs(self) -> None:
        """Show logs tab."""
        self.query_one("#main-tabs").active = "logs-tab"
        
    def action_show_settings(self) -> None:
        """Show settings tab."""
        self.query_one("#main-tabs").active = "settings-tab"


def run_simple_textual_app(config_path: str = "config.json"):
    """Run the simplified Textual application."""
    if not TEXTUAL_AVAILABLE:
        print("Textual is not available. Please install it first:")
        print("pip install textual>=0.52.0")
        return
        
    app = SimpleServerAssistantApp(config_path)
    app.run()


if __name__ == "__main__":
    run_simple_textual_app() 