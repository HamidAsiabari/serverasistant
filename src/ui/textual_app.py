"""
Textual-based GUI for ServerAssistant
"""

import asyncio
from pathlib import Path
from typing import Dict, List, Optional
from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import (
    Button, DataTable, Header, Footer, Static, Label, 
    Input, Select, Log, ProgressBar, Switch, TabbedContent, TabPane
)
from textual.reactive import reactive
from textual import work
from textual.binding import Binding
from textual.widgets.data_table import RowKey
from textual.css.query import DOMQuery

# Import from parent modules
from ..core.server_assistant import ServerAssistant
from ..core.docker_manager import ServiceStatus


class ServiceStatusWidget(Static):
    """Widget to display service status with color coding"""
    
    def __init__(self, status: ServiceStatus):
        super().__init__()
        self.status = status
        
    def compose(self) -> ComposeResult:
        status_color = self._get_status_color(self.status.status)
        yield Label(f"[{status_color}]{self.status.name}[/{status_color}]", classes="service-name")
        yield Label(f"Status: {self.status.status}", classes="service-status")
        if self.status.container_id:
            yield Label(f"Container: {self.status.container_id[:12]}...", classes="service-detail")
        if self.status.port:
            yield Label(f"Port: {self.status.port}", classes="service-detail")
        if self.status.health:
            yield Label(f"Health: {self.status.health}", classes="service-detail")
            
    def _get_status_color(self, status: str) -> str:
        """Get color for status"""
        status_lower = status.lower()
        if "running" in status_lower:
            return "green"
        elif "stopped" in status_lower or "exited" in status_lower:
            return "red"
        elif "starting" in status_lower or "restarting" in status_lower:
            return "yellow"
        else:
            return "gray"


class ServiceControlWidget(Static):
    """Widget for service control buttons"""
    
    def __init__(self, service_name: str):
        super().__init__()
        self.service_name = service_name
        
    def compose(self) -> ComposeResult:
        with Horizontal(classes="service-controls"):
            yield Button("Start", id=f"start-{self.service_name}", variant="success", classes="control-btn")
            yield Button("Stop", id=f"stop-{self.service_name}", variant="error", classes="control-btn")
            yield Button("Restart", id=f"restart-{self.service_name}", variant="warning", classes="control-btn")
            yield Button("Logs", id=f"logs-{self.service_name}", variant="primary", classes="control-btn")


class ServiceCard(Static):
    """Card widget for displaying service information"""
    
    def __init__(self, service_name: str, service_config: dict, status: Optional[ServiceStatus] = None):
        super().__init__(classes="service-card")
        self.service_name = service_name
        self.service_config = service_config
        self.status = status or ServiceStatus(name=service_name, status="unknown")
        
    def compose(self) -> ComposeResult:
        # Service header
        with Horizontal(classes="service-header"):
            yield Label(self.service_name, classes="service-title")
            enabled = self.service_config.get("enabled", False)
            yield Switch(value=enabled, id=f"enabled-{self.service_name}", classes="service-toggle")
            
        # Service status
        yield ServiceStatusWidget(self.status)
        
        # Service controls
        yield ServiceControlWidget(self.service_name)
        
        # Service details
        with Vertical(classes="service-details"):
            if self.service_config.get("ports"):
                yield Label(f"Ports: {', '.join(self.service_config['ports'])}", classes="service-detail")
            if self.service_config.get("path"):
                yield Label(f"Path: {self.service_config['path']}", classes="service-detail")


class LogViewer(Static):
    """Widget for viewing service logs"""
    
    def __init__(self, service_name: str):
        super().__init__()
        self.service_name = service_name
        self.log_widget = Log(id=f"logs-{service_name}", classes="log-viewer")
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="log-container"):
            with Horizontal(classes="log-header"):
                yield Label(f"Logs for {self.service_name}", classes="log-title")
                yield Button("Refresh", id=f"refresh-logs-{self.service_name}", variant="primary")
                yield Button("Follow", id=f"follow-logs-{self.service_name}", variant="secondary")
            yield self.log_widget
            
    def update_logs(self, logs: str):
        """Update log content"""
        self.log_widget.clear()
        self.log_widget.write(logs)


class DashboardScreen(Static):
    """Main dashboard screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        self.services = {}
        self.statuses = {}
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="dashboard"):
            # Header
            with Horizontal(classes="dashboard-header"):
                yield Label("🚀 Server Assistant Dashboard", classes="dashboard-title")
                yield Button("Refresh", id="refresh-dashboard", variant="primary")
                
            # Summary stats
            with Horizontal(classes="stats-container"):
                yield Static("📊 Total Services", classes="stat-card")
                yield Static("🟢 Running", classes="stat-card")
                yield Static("🔴 Stopped", classes="stat-card")
                yield Static("🟡 Starting", classes="stat-card")
                
            # Services grid
            with Container(id="services-grid", classes="services-grid"):
                # Services will be added dynamically
                pass


class ServicesScreen(Static):
    """Services management screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="services-screen"):
            # Header
            with Horizontal(classes="services-header"):
                yield Label("🔧 Services Management", classes="screen-title")
                yield Button("Start All", id="start-all", variant="success")
                yield Button("Stop All", id="stop-all", variant="error")
                yield Button("Refresh", id="refresh-services", variant="primary")
                
            # Services table
            yield DataTable(id="services-table", classes="services-table")
            
            # Service details
            with Container(id="service-details", classes="service-details-panel"):
                yield Static("Select a service to view details", classes="placeholder-text")


class LogsScreen(Static):
    """Logs viewing screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        self.current_service = None
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="logs-screen"):
            # Header
            with Horizontal(classes="logs-header"):
                yield Label("📋 Service Logs", classes="screen-title")
                yield Select(
                    [(name, name) for name in self.server_assistant.get_services().keys()],
                    placeholder="Select service...",
                    id="service-selector"
                )
                yield Button("Refresh", id="refresh-logs", variant="primary")
                yield Switch(False, id="follow-logs", label="Follow")
                
            # Log viewer
            yield Log(id="main-log-viewer", classes="main-log-viewer")


class SettingsScreen(Static):
    """Settings screen"""
    
    def __init__(self, server_assistant: ServerAssistant):
        super().__init__()
        self.server_assistant = server_assistant
        
    def compose(self) -> ComposeResult:
        with Vertical(classes="settings-screen"):
            yield Label("⚙️ Settings", classes="screen-title")
            
            with Container(classes="settings-form"):
                yield Label("Server Configuration", classes="section-title")
                yield Label(f"Server Name: {self.server_assistant.get_configuration().server_name}")
                yield Label(f"Environment: {self.server_assistant.get_configuration().environment}")
                yield Label(f"Log Level: {self.server_assistant.get_configuration().log_level}")
                
                yield Label("Docker Environment", classes="section-title")
                docker_status = "✅ Available" if self.server_assistant.check_docker_environment() else "❌ Not Available"
                yield Label(f"Docker: {docker_status}")
                
                yield Label("Global Settings", classes="section-title")
                global_settings = self.server_assistant.get_configuration().global_settings
                yield Label(f"Backup Enabled: {global_settings.get('backup_enabled', False)}")
                yield Label(f"Log Retention: {global_settings.get('log_retention_days', 30)} days")


class ServerAssistantApp(App):
    """Main Textual application for ServerAssistant"""
    
    CSS_PATH = "textual_app.tcss"
    TITLE = "Server Assistant"
    SUB_TITLE = "Docker Service Manager"
    
    # Bindings
    BINDINGS = [
        Binding("q", "quit", "Quit"),
        Binding("r", "refresh", "Refresh"),
        Binding("1", "show_dashboard", "Dashboard"),
        Binding("2", "show_services", "Services"),
        Binding("3", "show_logs", "Logs"),
        Binding("4", "show_settings", "Settings"),
        Binding("f1", "help", "Help"),
    ]
    
    def __init__(self, config_path: str = "config.json"):
        super().__init__()
        self.server_assistant = ServerAssistant(config_path)
        self.current_screen = "dashboard"
        
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
        
        # Update stats
        total = len(services)
        running = sum(1 for s in statuses if "running" in s.status.lower())
        stopped = sum(1 for s in statuses if "stopped" in s.status.lower() or "exited" in s.status.lower())
        starting = sum(1 for s in statuses if "starting" in s.status.lower())
        
        # Update service cards
        services_grid = dashboard.query_one("#services-grid")
        services_grid.remove_children()
        
        for service_name, service_config in services.items():
            status = next((s for s in statuses if s.name == service_name), None)
            service_card = ServiceCard(service_name, service_config, status)
            services_grid.mount(service_card)
            
    def update_services_table(self, statuses: List[ServiceStatus], services: Dict):
        """Update services table."""
        services_screen = self.query_one("#services-tab")
        table = services_screen.query_one("#services-table")
        
        # Clear existing data
        table.clear(columns=True)
        
        # Add columns
        table.add_columns("Name", "Status", "Container ID", "Ports", "Health", "Actions")
        
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
                status.health or "N/A",
                "Actions"  # Placeholder for action buttons
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
            logs = self.server_assistant.get_service_logs(service_name)
            logs_screen = self.query_one("#logs-tab")
            log_viewer = logs_screen.query_one("#main-log-viewer")
            log_viewer.clear()
            log_viewer.write(logs)
            
            # Switch to logs tab
            self.query_one("#main-tabs").active = "logs-tab"
            
        except Exception as e:
            self.notify(f"Error getting logs: {e}", severity="error")
            
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


def run_textual_app(config_path: str = "config.json"):
    """Run the Textual application."""
    app = ServerAssistantApp(config_path)
    app.run()


if __name__ == "__main__":
    run_textual_app() 