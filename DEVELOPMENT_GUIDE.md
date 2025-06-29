# Development Guide - ServerAssistant

## Getting Started

### Prerequisites
- Python 3.7+
- Docker and Docker Compose
- Git

### Setup Development Environment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd serverimp
   ```

2. **Create virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   pip install tabulate psutil colorama
   ```

4. **Run the application**
   ```bash
   python src/main.py
   ```

## Project Structure Overview

### Core Module (`src/core/`)

The core module contains the main business logic:

- **`server_assistant.py`**: Main orchestrator class
- **`config_manager.py`**: Configuration management
- **`docker_manager.py`**: Docker operations

### UI Module (`src/ui/`)

The UI module handles user interactions:

- **`display_utils.py`**: Display formatting utilities
- **`menu_system.py`**: Menu system and user input handling

### Utils Module (`src/utils/`)

The utils module provides utility functions:

- **`file_utils.py`**: File operations
- **`system_utils.py`**: System operations
- **`validation_utils.py`**: Data validation

## Development Workflow

### 1. Adding New Features

#### Step 1: Identify the Module
- **Core logic** → `src/core/`
- **User interface** → `src/ui/`
- **Utility functions** → `src/utils/`

#### Step 2: Create/Update Classes
```python
# Example: Adding a new service type
# File: src/core/service_manager.py

from typing import Dict, List, Optional
from dataclasses import dataclass

@dataclass
class ServiceInfo:
    name: str
    type: str
    status: str
    config: Dict[str, Any]

class ServiceManager:
    def __init__(self):
        self.services: Dict[str, ServiceInfo] = {}
    
    def add_service(self, name: str, service_type: str, config: Dict[str, Any]) -> bool:
        # Implementation
        pass
    
    def get_service_status(self, name: str) -> Optional[str]:
        # Implementation
        pass
```

#### Step 3: Update Main Entry Point
```python
# File: src/main.py

from core.service_manager import ServiceManager

def main():
    # Initialize new component
    service_manager = ServiceManager()
    
    # Integrate with existing functionality
    # ...
```

#### Step 4: Add UI Integration
```python
# File: src/ui/menu_system.py

def create_service_manager_menu(self, service_manager):
    self.add_menu("service_manager", "Service Manager")
    
    self.add_menu_item("service_manager", "1", "List Services",
                      lambda: self._list_services(service_manager))
    
    self.add_menu_item("service_manager", "2", "Add Service",
                      lambda: self._add_service(service_manager))
```

### 2. Testing Your Changes

#### Unit Testing
```python
# File: tests/test_service_manager.py

import unittest
from src.core.service_manager import ServiceManager, ServiceInfo

class TestServiceManager(unittest.TestCase):
    def setUp(self):
        self.manager = ServiceManager()
    
    def test_add_service(self):
        config = {"port": 8080, "path": "/app"}
        result = self.manager.add_service("test-service", "web", config)
        self.assertTrue(result)
        self.assertIn("test-service", self.manager.services)
    
    def test_get_service_status(self):
        # Test implementation
        pass

if __name__ == '__main__':
    unittest.main()
```

#### Integration Testing
```python
# File: tests/test_integration.py

import unittest
from src.main import main
from src.core.server_assistant import ServerAssistant

class TestIntegration(unittest.TestCase):
    def test_full_workflow(self):
        # Test complete workflow
        pass
```

### 3. Debugging

#### Using Python Debugger
```python
import pdb

def some_function():
    # Add breakpoint
    pdb.set_trace()
    
    # Your code here
    result = complex_operation()
    
    # Continue execution
    return result
```

#### Using Logging
```python
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def some_function():
    logger.debug("Starting operation")
    try:
        result = complex_operation()
        logger.info("Operation completed successfully")
        return result
    except Exception as e:
        logger.error(f"Operation failed: {e}")
        raise
```

#### Testing Individual Components
```python
# Test configuration manager
from src.core.config_manager import ConfigManager

config = ConfigManager("test_config.json")
if config.load_config():
    print("Configuration loaded successfully")
    print(f"Services: {len(config.get_all_services())}")
else:
    print("Failed to load configuration")

# Test Docker manager
from src.core.docker_manager import DockerManager
from pathlib import Path

docker = DockerManager(Path("."))
if docker.check_docker_environment():
    print("Docker environment is ready")
else:
    print("Docker environment check failed")
```

## Best Practices

### 1. Code Organization

#### Use Type Hints
```python
from typing import Dict, List, Optional, Any

def process_services(services: List[Dict[str, Any]]) -> Dict[str, bool]:
    results: Dict[str, bool] = {}
    for service in services:
        results[service['name']] = process_service(service)
    return results
```

#### Use Data Classes
```python
from dataclasses import dataclass
from typing import Optional

@dataclass
class ServiceConfig:
    name: str
    enabled: bool
    path: str
    port: Optional[int] = None
    health_check: Optional[str] = None
```

#### Follow Naming Conventions
- **Classes**: PascalCase (`ServiceManager`)
- **Functions/Methods**: snake_case (`get_service_status`)
- **Constants**: UPPER_CASE (`DEFAULT_PORT`)
- **Variables**: snake_case (`service_name`)

### 2. Error Handling

#### Use Specific Exceptions
```python
class ConfigurationError(Exception):
    """Raised when configuration is invalid"""
    pass

class ServiceError(Exception):
    """Raised when service operation fails"""
    pass

def load_config(config_path: str) -> Dict[str, Any]:
    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        raise ConfigurationError(f"Configuration file not found: {config_path}")
    except json.JSONDecodeError as e:
        raise ConfigurationError(f"Invalid JSON in configuration: {e}")
```

#### Provide Meaningful Error Messages
```python
def start_service(service_name: str) -> bool:
    try:
        # Service start logic
        return True
    except DockerError as e:
        logger.error(f"Failed to start service '{service_name}': {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error starting service '{service_name}': {e}")
        return False
```

### 3. Documentation

#### Docstrings
```python
def get_service_status(service_name: str) -> Optional[str]:
    """
    Get the current status of a service.
    
    Args:
        service_name: Name of the service to check
        
    Returns:
        Service status string or None if service not found
        
    Raises:
        ServiceError: If unable to check service status
    """
    # Implementation
    pass
```

#### Comments
```python
# Check if service is running
if service.status == "running":
    # Perform health check
    health_result = perform_health_check(service)
    
    # Update status based on health check
    if health_result:
        service.status = "healthy"
    else:
        service.status = "unhealthy"
```

## Common Development Tasks

### 1. Adding a New Service Type

1. **Update configuration schema**
   ```python
   # In config_manager.py
   @dataclass
   class ServiceConfig:
       name: str
       enabled: bool
       path: str
       type: str  # Add new field
       port: Optional[int] = None
   ```

2. **Add service-specific logic**
   ```python
   # In docker_manager.py
   def start_service(self, service_name: str) -> bool:
       service = self.services.get(service_name)
       if service.type == "web":
           return self._start_web_service(service)
       elif service.type == "database":
           return self._start_database_service(service)
       else:
           return self._start_generic_service(service)
   ```

3. **Update UI**
   ```python
   # In menu_system.py
   def _show_service_control_menu(self, server_assistant, service_name):
       service = server_assistant.get_service(service_name)
       
       if service.type == "web":
           print("4. View Web Interface")
       elif service.type == "database":
           print("4. Database Console")
   ```

### 2. Adding New Configuration Options

1. **Update data classes**
   ```python
   @dataclass
   class ServerConfig:
       server_name: str
       environment: str
       services: List[ServiceConfig]
       backup_path: str
       log_level: str = "INFO"
       new_option: str = "default"  # Add new option
   ```

2. **Add validation**
   ```python
   def validate_config(self) -> List[str]:
       errors = []
       
       # Existing validation...
       
       # New validation
       if self.config.new_option not in ["option1", "option2", "option3"]:
           errors.append("new_option must be one of: option1, option2, option3")
           
       return errors
   ```

3. **Update UI to display new options**
   ```python
   def print_configuration_summary(self, config: Dict[str, Any]):
       # Existing display...
       print(f"New Option: {config.get('new_option', 'default')}")
   ```

### 3. Adding New CLI Commands

1. **Update argument parser**
   ```python
   parser.add_argument(
       'action',
       nargs='?',
       choices=['status', 'start', 'stop', 'restart', 'start-all', 'stop-all', 'logs', 'new-command'],
       help='CLI action to perform'
   )
   ```

2. **Add command handler**
   ```python
   elif args.action == 'new-command':
       result = server_assistant.new_command(args.service)
       if result:
           DisplayUtils.print_success("New command executed successfully")
       else:
           DisplayUtils.print_error("New command failed")
   ```

3. **Implement the command**
   ```python
   # In server_assistant.py
   def new_command(self, service_name: str) -> bool:
       """Execute new command for a service"""
       # Implementation
       pass
   ```

## Performance Considerations

### 1. Lazy Loading
```python
class ServiceManager:
    def __init__(self):
        self._services = None
    
    @property
    def services(self) -> Dict[str, ServiceInfo]:
        if self._services is None:
            self._services = self._load_services()
        return self._services
```

### 2. Caching
```python
from functools import lru_cache

@lru_cache(maxsize=128)
def get_service_config(service_name: str) -> Optional[ServiceConfig]:
    # Expensive operation
    pass
```

### 3. Async Operations
```python
import asyncio

async def start_all_services_async(self) -> Dict[str, bool]:
    tasks = []
    for service_name in self.services:
        task = asyncio.create_task(self._start_service_async(service_name))
        tasks.append((service_name, task))
    
    results = {}
    for service_name, task in tasks:
        results[service_name] = await task
    
    return results
```

## Troubleshooting

### Common Issues

1. **Import Errors**
   - Make sure you're running from the project root
   - Check that all `__init__.py` files exist
   - Verify import paths are correct

2. **Configuration Issues**
   - Validate configuration with `ConfigManager.validate_config()`
   - Check JSON syntax
   - Verify file paths exist

3. **Docker Issues**
   - Ensure Docker daemon is running
   - Check Docker Compose version compatibility
   - Verify service paths exist

### Debugging Tips

1. **Use the CLI mode for testing**
   ```bash
   python src/main.py --cli status
   ```

2. **Test individual components**
   ```python
   python -c "from src.core.config_manager import ConfigManager; c = ConfigManager(); print(c.load_config())"
   ```

3. **Enable debug logging**
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

4. **Use Python debugger**
   ```python
   import pdb; pdb.set_trace()
   ```

This development guide provides a comprehensive overview of how to work with the reorganized ServerAssistant structure. Follow these guidelines to maintain code quality and consistency across the project. 