#!/bin/bash
# Quick Test Script for Ubuntu 22.04 Docker Service Manager
# Run this after the main setup to verify everything is working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
TEST_CONFIG="test_config_ubuntu22.json"

print_header() {
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}==========================================${NC}"
}

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

# Function to test basic requirements
test_basic_requirements() {
    print_header "Testing Basic Requirements"
    
    # Test Docker
    if docker --version >/dev/null 2>&1; then
        print_success "Docker: $(docker --version | head -n1)"
    else
        print_error "Docker not found"
        return 1
    fi
    
    # Test Docker Compose
    if docker-compose --version >/dev/null 2>&1; then
        print_success "Docker Compose: $(docker-compose --version | head -n1)"
    else
        print_error "Docker Compose not found"
        return 1
    fi
    
    # Test Python
    if python3 --version >/dev/null 2>&1; then
        print_success "Python: $(python3 --version)"
    else
        print_error "Python3 not found"
        return 1
    fi
    
    # Test Docker daemon
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        return 1
    fi
}

# Function to test Docker Service Manager
test_docker_manager() {
    print_header "Testing Docker Service Manager"
    
    # Activate virtual environment
    if [[ -d "venv" ]]; then
        source venv/bin/activate
        print_success "Virtual environment activated"
    else
        print_error "Virtual environment not found"
        return 1
    fi
    
    # Test imports
    if python3 -c "
import sys
sys.path.append('.')
try:
    from docker_manager import DockerManager
    print('Docker Manager import successful')
except ImportError as e:
    print(f'Import error: {e}')
    sys.exit(1)
"; then
        print_success "Docker Manager imports work"
    else
        print_error "Docker Manager imports failed"
        return 1
    fi
    
    # Test configuration
    if [[ -f "$TEST_CONFIG" ]]; then
        print_success "Test configuration file exists"
    else
        print_error "Test configuration file not found: $TEST_CONFIG"
        return 1
    fi
    
    # Test Docker Manager initialization
    if python3 -c "
import sys
sys.path.append('.')
from docker_manager import DockerManager
try:
    manager = DockerManager('$TEST_CONFIG')
    print('Docker Manager initialized successfully')
except Exception as e:
    print(f'Initialization error: {e}')
    sys.exit(1)
"; then
        print_success "Docker Manager initialization successful"
    else
        print_error "Docker Manager initialization failed"
        return 1
    fi
}

# Function to test service startup
test_service_startup() {
    print_header "Testing Service Startup"
    
    # Start databases first
    print_status "Starting MySQL database..."
    if python3 main.py start mysql-database --config "$TEST_CONFIG"; then
        print_success "MySQL database started"
    else
        print_error "Failed to start MySQL database"
        return 1
    fi
    
    print_status "Starting PostgreSQL/Redis..."
    if python3 main.py start postgres-redis --config "$TEST_CONFIG"; then
        print_success "PostgreSQL/Redis started"
    else
        print_error "Failed to start PostgreSQL/Redis"
        return 1
    fi
    
    # Wait for databases
    print_status "Waiting for databases to be ready..."
    sleep 20
    
    # Start web app
    print_status "Starting web application..."
    if python3 main.py start web-app --config "$TEST_CONFIG"; then
        print_success "Web application started"
    else
        print_error "Failed to start web application"
        return 1
    fi
    
    # Wait for web app
    print_status "Waiting for web application to be ready..."
    sleep 20
}

# Function to test service connectivity
test_service_connectivity() {
    print_header "Testing Service Connectivity"
    
    # Test phpMyAdmin
    print_status "Testing phpMyAdmin..."
    if curl -s -f http://localhost:8082 >/dev/null 2>&1; then
        print_success "phpMyAdmin is accessible at http://localhost:8082"
    else
        print_warning "phpMyAdmin is not accessible"
    fi
    
    # Test web app
    print_status "Testing web application..."
    if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
        print_success "Web application health check passed"
        # Get health response
        HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
        echo "Health response: $HEALTH_RESPONSE"
    else
        print_warning "Web application health check failed"
    fi
    
    # Test web app main page
    if curl -s -f http://localhost:8080 >/dev/null 2>&1; then
        print_success "Web application main page is accessible"
    else
        print_warning "Web application main page is not accessible"
    fi
    
    # Test PostgreSQL
    print_status "Testing PostgreSQL..."
    if docker exec postgres pg_isready -U postgres >/dev/null 2>&1; then
        print_success "PostgreSQL is ready"
    else
        print_warning "PostgreSQL is not ready"
    fi
    
    # Test Redis
    print_status "Testing Redis..."
    if docker exec redis redis-cli ping >/dev/null 2>&1; then
        print_success "Redis is ready"
    else
        print_warning "Redis is not ready"
    fi
    
    # Test MySQL
    print_status "Testing MySQL..."
    if docker exec mysql mysqladmin ping -h localhost -u root -proot_password_secure >/dev/null 2>&1; then
        print_success "MySQL is ready"
    else
        print_warning "MySQL is not ready"
    fi
}

# Function to test service status
test_service_status() {
    print_header "Testing Service Status"
    
    # Get service status
    print_status "Getting service status..."
    python3 main.py status --config "$TEST_CONFIG"
    
    # Show running containers
    echo -e "\n${CYAN}Running Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to test monitoring
test_monitoring() {
    print_header "Testing Monitoring"
    
    # Test health summary
    print_status "Testing health summary..."
    if python3 monitor.py --summary --config "$TEST_CONFIG"; then
        print_success "Health summary generated"
    else
        print_warning "Health summary failed"
    fi
}

# Function to show access information
show_access_info() {
    print_header "Access Information"
    
    echo -e "${CYAN}Service URLs:${NC}"
    echo "Web Application: http://localhost:8080"
    echo "phpMyAdmin: http://localhost:8082"
    echo "PostgreSQL: localhost:5432"
    echo "Redis: localhost:6379"
    echo "MySQL: localhost:3306"
    
    echo -e "\n${CYAN}Test Commands:${NC}"
    echo "Service Status: python3 main.py status --config $TEST_CONFIG"
    echo "Start All: python3 main.py start-all --config $TEST_CONFIG"
    echo "Stop All: python3 main.py stop-all --config $TEST_CONFIG"
    echo "Monitor: python3 monitor.py --config $TEST_CONFIG"
    echo "View Logs: tail -f logs/docker_manager_$(date +%Y%m%d).log"
    
    echo -e "\n${CYAN}Database Credentials:${NC}"
    echo "MySQL Root: root / root_password_secure"
    echo "MySQL App: myapp_user / myapp_password"
    echo "PostgreSQL: postgres / password"
}

# Function to cleanup
cleanup() {
    print_header "Cleaning Up"
    
    print_status "Stopping all services..."
    python3 main.py stop-all --config "$TEST_CONFIG" || true
    
    print_success "Cleanup completed"
}

# Main execution
main() {
    print_header "Quick Test - Ubuntu 22.04 Docker Service Manager"
    
    # Run all tests
    test_basic_requirements || exit 1
    test_docker_manager || exit 1
    test_service_startup || exit 1
    test_service_connectivity
    test_service_status
    test_monitoring
    show_access_info
    
    print_success "Quick test completed successfully!"
    echo -e "\n${YELLOW}Note:${NC} Services are still running. Use 'cleanup' to stop them."
}

# Handle script arguments
case "${1:-}" in
    "cleanup")
        cleanup
        ;;
    "status")
        test_service_status
        ;;
    "connectivity")
        test_service_connectivity
        ;;
    *)
        main
        ;;
esac 