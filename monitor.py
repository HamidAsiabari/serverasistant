#!/usr/bin/env python3
"""
Service Monitor for Docker Service Manager
Monitors Docker services for health and sends notifications.
"""

import os
import sys
import time
import json
import logging
import schedule
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import requests
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from docker_manager import DockerManager, ServiceStatus

class ServiceMonitor:
    """Monitor Docker services for health and status."""
    
    def __init__(self, config_path: str = "config.json"):
        """Initialize the service monitor."""
        self.manager = DockerManager(config_path)
        self.config = self.manager.config
        self.logger = self.manager.logger
        self.monitoring = False
        self.health_history = {}
        self.alert_history = {}
        
    def start_monitoring(self, interval: int = 60):
        """Start continuous monitoring."""
        self.monitoring = True
        self.logger.info(f"Starting service monitoring with {interval}s interval")
        
        # Schedule health checks
        schedule.every(interval).seconds.do(self.check_all_services)
        
        # Schedule daily status report
        schedule.every().day.at("09:00").do(self.generate_daily_report)
        
        # Schedule cleanup
        schedule.every().day.at("02:00").do(self.cleanup_old_logs)
        
        try:
            while self.monitoring:
                schedule.run_pending()
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Monitoring stopped by user")
        finally:
            self.stop_monitoring()
    
    def stop_monitoring(self):
        """Stop monitoring."""
        self.monitoring = False
        self.manager.cleanup()
        self.logger.info("Service monitoring stopped")
    
    def check_all_services(self):
        """Check health of all services."""
        self.logger.info("Performing health check on all services")
        
        for service_config in self.config['services']:
            if not service_config.get('enabled', True):
                continue
                
            service_name = service_config['name']
            status = self.manager.get_service_status(service_name)
            
            if status:
                self._check_service_health(service_config, status)
            else:
                self._handle_service_unavailable(service_config)
    
    def _check_service_health(self, service_config: Dict, status: ServiceStatus):
        """Check health of a specific service."""
        service_name = service_config['name']
        
        # Update health history
        if service_name not in self.health_history:
            self.health_history[service_name] = []
        
        health_record = {
            'timestamp': datetime.now().isoformat(),
            'status': status.status,
            'health': status.health,
            'memory_usage': status.memory_usage,
            'cpu_usage': status.cpu_usage
        }
        
        self.health_history[service_name].append(health_record)
        
        # Keep only last 100 records
        if len(self.health_history[service_name]) > 100:
            self.health_history[service_name] = self.health_history[service_name][-100:]
        
        # Check for health issues
        issues = []
        
        if status.status != "running":
            issues.append(f"Service is not running (status: {status.status})")
        
        if status.health == "unhealthy":
            issues.append("Service health check failed")
        
        # Check resource usage
        if status.memory_usage and status.memory_usage != "N/A":
            try:
                memory_percent = float(status.memory_usage.rstrip('%'))
                if memory_percent > 90:
                    issues.append(f"High memory usage: {status.memory_usage}")
            except ValueError:
                pass
        
        if status.cpu_usage and status.cpu_usage > 90:
            issues.append(f"High CPU usage: {status.cpu_usage:.1f}%")
        
        # Perform custom health checks
        if 'health_check' in service_config:
            custom_issues = self._perform_custom_health_check(service_config)
            issues.extend(custom_issues)
        
        # Handle issues
        if issues:
            self._handle_service_issues(service_config, issues)
        else:
            self._clear_service_alerts(service_config)
    
    def _perform_custom_health_check(self, service_config: Dict) -> List[str]:
        """Perform custom health checks based on configuration."""
        issues = []
        health_config = service_config['health_check']
        
        try:
            if 'url' in health_config:
                # HTTP health check
                response = requests.get(
                    health_config['url'],
                    timeout=health_config.get('timeout', 10)
                )
                if response.status_code != 200:
                    issues.append(f"HTTP health check failed: {response.status_code}")
            
            elif 'command' in health_config:
                # Command-based health check
                import subprocess
                try:
                    result = subprocess.run(
                        health_config['command'].split(),
                        capture_output=True,
                        text=True,
                        timeout=health_config.get('timeout', 10)
                    )
                    if result.returncode != 0:
                        issues.append(f"Command health check failed: {result.stderr}")
                except subprocess.TimeoutExpired:
                    issues.append("Command health check timed out")
                except Exception as e:
                    issues.append(f"Command health check error: {e}")
        
        except Exception as e:
            issues.append(f"Health check error: {e}")
        
        return issues
    
    def _handle_service_issues(self, service_config: Dict, issues: List[str]):
        """Handle service health issues."""
        service_name = service_config['name']
        
        # Check if we should send alert (avoid spam)
        alert_key = f"{service_name}_issues"
        last_alert = self.alert_history.get(alert_key)
        
        if not last_alert or (datetime.now() - last_alert) > timedelta(minutes=15):
            self.logger.warning(f"Service '{service_name}' has issues: {', '.join(issues)}")
            
            # Send notifications
            self._send_notifications(service_config, issues)
            
            # Update alert history
            self.alert_history[alert_key] = datetime.now()
    
    def _handle_service_unavailable(self, service_config: Dict):
        """Handle service that is not available."""
        service_name = service_config['name']
        self.logger.error(f"Service '{service_name}' is not available")
        
        # Send notification
        self._send_notifications(service_config, ["Service is not available"])
    
    def _clear_service_alerts(self, service_config: Dict):
        """Clear alerts for healthy service."""
        service_name = service_config['name']
        alert_key = f"{service_name}_issues"
        
        if alert_key in self.alert_history:
            self.logger.info(f"Service '{service_name}' is healthy - clearing alerts")
            del self.alert_history[alert_key]
    
    def _send_notifications(self, service_config: Dict, issues: List[str]):
        """Send notifications about service issues."""
        notification_config = self.config.get('global_settings', {}).get('notification', {})
        
        message = f"Service '{service_config['name']}' has issues:\n"
        message += "\n".join(f"- {issue}" for issue in issues)
        message += f"\n\nTime: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        message += f"\nServer: {self.config.get('server_name', 'Unknown')}"
        
        # Send email notification
        if 'email' in notification_config:
            self._send_email_notification(notification_config['email'], message)
        
        # Send webhook notification
        if 'webhook' in notification_config:
            self._send_webhook_notification(notification_config['webhook'], message)
    
    def _send_email_notification(self, email: str, message: str):
        """Send email notification."""
        try:
            # This is a placeholder - you would configure SMTP settings
            self.logger.info(f"Email notification would be sent to {email}")
            # In a real implementation, you would use smtplib to send the email
        except Exception as e:
            self.logger.error(f"Failed to send email notification: {e}")
    
    def _send_webhook_notification(self, webhook_url: str, message: str):
        """Send webhook notification."""
        try:
            payload = {
                "text": message,
                "username": "Docker Service Manager",
                "icon_emoji": ":warning:"
            }
            
            response = requests.post(webhook_url, json=payload, timeout=10)
            if response.status_code != 200:
                self.logger.error(f"Webhook notification failed: {response.status_code}")
        except Exception as e:
            self.logger.error(f"Failed to send webhook notification: {e}")
    
    def generate_daily_report(self):
        """Generate daily status report."""
        self.logger.info("Generating daily status report")
        
        report = {
            "date": datetime.now().strftime('%Y-%m-%d'),
            "server": self.config.get('server_name', 'Unknown'),
            "services": {}
        }
        
        for service_config in self.config['services']:
            service_name = service_config['name']
            status = self.manager.get_service_status(service_name)
            
            if status:
                report["services"][service_name] = {
                    "status": status.status,
                    "health": status.health,
                    "uptime": status.uptime,
                    "memory_usage": status.memory_usage,
                    "cpu_usage": status.cpu_usage
                }
            else:
                report["services"][service_name] = {
                    "status": "unavailable",
                    "health": "unknown"
                }
        
        # Save report
        report_file = f"reports/daily_report_{datetime.now().strftime('%Y%m%d')}.json"
        import os
        os.makedirs("reports", exist_ok=True)
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        self.logger.info(f"Daily report saved to {report_file}")
    
    def cleanup_old_logs(self):
        """Clean up old log files."""
        import os
        from pathlib import Path
        
        log_retention_days = self.config.get('global_settings', {}).get('log_retention_days', 30)
        cutoff_date = datetime.now() - timedelta(days=log_retention_days)
        
        # Clean up log files
        log_dir = Path("logs")
        if log_dir.exists():
            for log_file in log_dir.glob("*.log"):
                if log_file.stat().st_mtime < cutoff_date.timestamp():
                    log_file.unlink()
                    self.logger.info(f"Deleted old log file: {log_file}")
        
        # Clean up report files
        report_dir = Path("reports")
        if report_dir.exists():
            for report_file in report_dir.glob("daily_report_*.json"):
                if report_file.stat().st_mtime < cutoff_date.timestamp():
                    report_file.unlink()
                    self.logger.info(f"Deleted old report file: {report_file}")
    
    def get_health_summary(self) -> Dict:
        """Get summary of service health."""
        summary = {
            "total_services": len(self.config['services']),
            "running_services": 0,
            "healthy_services": 0,
            "unhealthy_services": 0,
            "stopped_services": 0,
            "services": {}
        }
        
        for service_config in self.config['services']:
            service_name = service_config['name']
            status = self.manager.get_service_status(service_name)
            
            if status:
                if status.status == "running":
                    summary["running_services"] += 1
                    if status.health == "healthy":
                        summary["healthy_services"] += 1
                    else:
                        summary["unhealthy_services"] += 1
                else:
                    summary["stopped_services"] += 1
                
                summary["services"][service_name] = {
                    "status": status.status,
                    "health": status.health,
                    "uptime": status.uptime
                }
            else:
                summary["stopped_services"] += 1
                summary["services"][service_name] = {
                    "status": "unavailable",
                    "health": "unknown"
                }
        
        return summary

def main():
    """Main function for monitoring."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Docker Service Monitor")
    parser.add_argument(
        '--config',
        default='config.json',
        help='Path to configuration file (default: config.json)'
    )
    parser.add_argument(
        '--interval',
        type=int,
        default=60,
        help='Monitoring interval in seconds (default: 60)'
    )
    parser.add_argument(
        '--summary',
        action='store_true',
        help='Show health summary and exit'
    )
    
    args = parser.parse_args()
    
    try:
        monitor = ServiceMonitor(args.config)
        
        if args.summary:
            summary = monitor.get_health_summary()
            print(json.dumps(summary, indent=2))
        else:
            monitor.start_monitoring(args.interval)
    
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 