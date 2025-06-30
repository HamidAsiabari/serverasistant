# Test Suite Documentation

This directory contains all tests for the ServerAssistant project, organized by type and purpose.

## 📁 Test Structure

```
tests/
├── README.md                    # This file - Test documentation
├── unit/                        # 🧪 Unit tests
│   ├── test_installation.py    # Installation validation tests
│   ├── test_installation_simple.py # Simplified installation tests
│   └── test_config_fix.py      # Configuration validation tests
├── integration/                 # 🔗 Integration tests
│   ├── test_startup.py         # Startup and initialization tests
│   └── test_services.py        # Service connectivity tests
├── e2e/                         # 🌐 End-to-end tests
│   └── test_services_setup.py  # Complete services setup tests
├── config/                      # ⚙️ Test configuration files
│   └── test_config_ubuntu22.json # Ubuntu 22.04 test configuration
└── scripts/                     # 🔧 Test scripts
    ├── quick_test.sh           # Quick test runner
    ├── quick_test_ubuntu22.sh  # Ubuntu 22.04 quick tests
    ├── test_ubuntu22.sh        # Comprehensive Ubuntu 22.04 tests
    └── check_mysql.sh          # MySQL connectivity check
```

## 🧪 Test Categories

### Unit Tests (`unit/`)
Fast, isolated tests that verify individual components and functions.

**Files:**
- `test_installation.py` - Validates installation requirements and dependencies
- `test_installation_simple.py` - Simplified installation validation
- `test_config_fix.py` - Configuration file validation and path checking

**Run with:**
```bash
# Run all unit tests
python -m pytest tests/unit/

# Run specific test file
python -m pytest tests/unit/test_installation.py
```

### Integration Tests (`integration/`)
Tests that verify how components work together.

**Files:**
- `test_startup.py` - Tests startup sequence and configuration loading
- `test_services.py` - Tests service connectivity and health checks

**Run with:**
```bash
# Run all integration tests
python -m pytest tests/integration/

# Run specific test file
python -m pytest tests/integration/test_services.py
```

### End-to-End Tests (`e2e/`)
Complete system tests that verify the entire application workflow.

**Files:**
- `test_services_setup.py` - Complete services setup tests

**Run with:**
```bash
# Run all e2e tests
python -m pytest tests/e2e/

# Run specific test file
python -m pytest tests/e2e/test_services_setup.py
```

### Test Scripts (`scripts/`)
Shell scripts for environment-specific testing and validation.

**Files:**
- `quick_test.sh` - Quick validation script
- `quick_test_ubuntu22.sh` - Ubuntu 22.04 specific quick tests
- `test_ubuntu22.sh` - Comprehensive Ubuntu 22.04 testing
- `check_mysql.sh` - MySQL connectivity validation

**Run with:**
```bash
# Make scripts executable
chmod +x tests/scripts/*.sh

# Run quick tests
./tests/scripts/quick_test.sh

# Run Ubuntu 22.04 tests
./tests/scripts/test_ubuntu22.sh
```

## 🚀 Running Tests

### Quick Test Run
```bash
# Run all tests
python -m pytest tests/

# Run with verbose output
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=src --cov-report=html
```

### Environment-Specific Tests
```bash
# Ubuntu 22.04 environment
./tests/scripts/test_ubuntu22.sh

# Quick validation
./tests/scripts/quick_test.sh

# MySQL connectivity
./tests/scripts/check_mysql.sh
```

### Individual Test Categories
```bash
# Unit tests only
python -m pytest tests/unit/

# Integration tests only
python -m pytest tests/integration/

# E2E tests only
python -m pytest tests/e2e/
```

## 📋 Test Configuration

### Test Configuration Files (`config/`)
- `test_config_ubuntu22.json` - Configuration for Ubuntu 22.04 testing environment

### Environment Variables
Set these environment variables for testing:
```bash
export TEST_ENV=ubuntu22
export TEST_CONFIG=tests/config/test_config_ubuntu22.json
export DOCKER_HOST=unix:///var/run/docker.sock
```

## 🔧 Test Dependencies

### Python Dependencies
```bash
pip install pytest pytest-cov pytest-mock requests
```

### System Dependencies
- Docker and Docker Compose
- Python 3.7+
- Access to Docker daemon

## 📊 Test Reports

### Coverage Reports
```bash
# Generate HTML coverage report
python -m pytest tests/ --cov=src --cov-report=html

# Generate XML coverage report
python -m pytest tests/ --cov=src --cov-report=xml
```

### Test Results
Test results are stored in:
- `htmlcov/` - HTML coverage reports
- `coverage.xml` - XML coverage data
- `test-results/` - Test execution results

## 🐛 Debugging Tests

### Verbose Output
```bash
python -m pytest tests/ -v -s
```

### Debug Specific Test
```bash
python -m pytest tests/unit/test_installation.py::test_imports -v -s
```

### Run Failed Tests Only
```bash
python -m pytest tests/ --lf
```

## 📝 Writing New Tests

### Unit Test Template
```python
import pytest
from src.core.docker_manager import DockerManager

def test_example_function():
    """Test description."""
    # Arrange
    expected = "expected_value"
    
    # Act
    result = function_under_test()
    
    # Assert
    assert result == expected
```

### Integration Test Template
```python
import pytest
import requests

def test_service_connectivity():
    """Test service connectivity."""
    # Arrange
    service_url = "http://localhost:8080"
    
    # Act
    response = requests.get(f"{service_url}/health")
    
    # Assert
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
```

## 🚨 Common Issues

### Docker Permission Issues
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Restart docker service
sudo systemctl restart docker
```

### Test Environment Setup
```bash
# Set up test environment
export TEST_ENV=development
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"
```

### Network Connectivity Issues
```bash
# Check Docker network
docker network ls

# Create test network if needed
docker network create test-network
```

## 📞 Support

For test-related issues:
1. Check the test logs in `test-results/`
2. Verify environment setup
3. Review the specific test category documentation
4. Check Docker and system dependencies 