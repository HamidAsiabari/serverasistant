#!/bin/bash
# Ubuntu 22.04 Test Script for Docker Service Manager
# This script prepares and tests the Docker Service Manager on Ubuntu 22.04

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Test configuration
TEST_CONFIG="test_config_ubuntu22.json"
LOG_FILE="test_ubuntu22_$(date +%Y%m%d_%H%M%S).log"

# Function to log output
log_output() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to fix permissions
fix_permissions() {
    print_header "Fixing Permissions"
    
    # Get current user and group
    CURRENT_USER=$(whoami)
    CURRENT_GROUP=$(id -gn)
    
    print_status "Current user: $CURRENT_USER"
    print_status "Current group: $CURRENT_GROUP"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Fix ownership of current directory
    print_status "Fixing ownership of current directory..."
    sudo chown -R $CURRENT_USER:$CURRENT_GROUP .
    
    # Set proper permissions
    print_status "Setting proper permissions..."
    chmod -R 755 .
    chmod 644 *.json *.txt *.md 2>/dev/null || true
    chmod 755 *.sh *.py 2>/dev/null || true
    
    print_success "Permissions fixed"
}

# Function to check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    # Check Ubuntu version
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "22.04" ]]; then
            print_success "Ubuntu 22.04 detected"
        else
            print_warning "This script is designed for Ubuntu 22.04, but you're running $ID $VERSION_ID"
        fi
    else
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check available memory (minimum 4GB)
    MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEMORY_GB=$((MEMORY_KB / 1024 / 1024))
    if [[ $MEMORY_GB -lt 4 ]]; then
        print_warning "Low memory detected: ${MEMORY_GB}GB (recommended: 4GB+)"
    else
        print_success "Memory: ${MEMORY_GB}GB"
    fi
    
    # Check available disk space (minimum 10GB)
    DISK_SPACE=$(df . | awk 'NR==2 {print $4}')
    DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))
    if [[ $DISK_SPACE_GB -lt 10 ]]; then
        print_warning "Low disk space: ${DISK_SPACE_GB}GB (recommended: 10GB+)"
    else
        print_success "Disk space: ${DISK_SPACE_GB}GB"
    fi
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity: OK"
    else
        print_error "No internet connectivity"
        exit 1
    fi
}

# Function to install system dependencies
install_system_dependencies() {
    print_header "Installing System Dependencies"
    
    # Update package list
    log_output "Updating package list..."
    sudo apt update
    
    # Install essential packages
    log_output "Installing essential packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        python3 \
        python3-pip \
        python3-venv \
        net-tools \
        telnet \
        htop \
        tree
    
    print_success "System dependencies installed"
}

# Function to install Docker
install_docker() {
    print_header "Installing Docker"
    
    if command_exists docker; then
        print_warning "Docker is already installed"
        docker --version
    else
        log_output "Installing Docker..."
        
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Update package list
        sudo apt update
        
        # Install Docker
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        print_success "Docker installed successfully"
        print_warning "Please log out and log back in for docker group changes to take effect"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    print_header "Installing Docker Compose"
    
    if command_exists docker-compose; then
        print_warning "Docker Compose is already installed"
        docker-compose --version
    else
        log_output "Installing Docker Compose..."
        
        # Download Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        print_success "Docker Compose installed successfully"
    fi
}

# Function to setup Python environment
setup_python_environment() {
    print_header "Setting up Python Environment"
    
    # Get current user
    CURRENT_USER=$(whoami)
    
    # Remove existing venv if owned by root
    if [[ -d "venv" ]]; then
        VENV_OWNER=$(stat -c '%U' venv)
        if [[ "$VENV_OWNER" == "root" ]]; then
            print_warning "Removing root-owned virtual environment..."
            sudo rm -rf venv
        fi
    fi
    
    # Create virtual environment
    if [[ ! -d "venv" ]]; then
        log_output "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Ensure proper ownership
    sudo chown -R $CURRENT_USER:$CURRENT_USER venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    log_output "Upgrading pip..."
    pip install --upgrade pip
    
    # Install Python dependencies
    log_output "Installing Python dependencies..."
    pip install -r requirements.txt
    
    print_success "Python environment setup complete"
}

# Function to create necessary directories
create_directories() {
    print_header "Creating Necessary Directories"
    
    # Get current user
    CURRENT_USER=$(whoami)
    
    # Create directories
    mkdir -p logs
    mkdir -p reports
    mkdir -p services
    mkdir -p backups
    
    # Set proper ownership
    sudo chown -R $CURRENT_USER:$CURRENT_USER logs reports services backups
    
    # Set permissions
    chmod 755 logs reports services backups
    
    print_success "Directories created"
}

# Function to test Docker installation
test_docker() {
    print_header "Testing Docker Installation"
    
    # Test Docker daemon
    if sudo docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        sudo systemctl start docker
        sleep 5
        if sudo docker info >/dev/null 2>&1; then
            print_success "Docker daemon started successfully"
        else
            print_error "Failed to start Docker daemon"
            exit 1
        fi
    fi
    
    # Test Docker Compose
    if docker-compose --version >/dev/null 2>&1; then
        print_success "Docker Compose is working"
    else
        print_error "Docker Compose is not working"
        exit 1
    fi
    
    # Test Docker permissions
    if docker ps >/dev/null 2>&1; then
        print_success "Docker permissions are correct"
    else
        print_warning "Docker permissions issue - you may need to log out and back in"
        print_warning "For now, using sudo for Docker commands"
    fi
}

# Function to test configuration
test_configuration() {
    print_header "Testing Configuration"
    
    # Check if test config exists
    if [[ ! -f "$TEST_CONFIG" ]]; then
        print_error "Test configuration file not found: $TEST_CONFIG"
        exit 1
    fi
    
    # Validate JSON
    if python3 -m json.tool "$TEST_CONFIG" >/dev/null 2>&1; then
        print_success "Configuration file is valid JSON"
    else
        print_error "Configuration file is not valid JSON"
        exit 1
    fi
    
    # Test Docker Manager with test config
    log_output "Testing Docker Manager initialization..."
    if python3 -c "
import sys
sys.path.append('.')
from docker_manager import DockerManager
try:
    manager = DockerManager('$TEST_CONFIG')
    print('Docker Manager initialized successfully')
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
"; then
        print_success "Docker Manager test passed"
    else
        print_error "Docker Manager test failed"
        exit 1
    fi
}

# Function to test services
test_services() {
    print_header "Testing Services"
    
    # Test with test configuration
    export CONFIG_FILE="$TEST_CONFIG"
    
    # Test service status
    log_output "Testing service status..."
    if python3 main.py status --config "$TEST_CONFIG"; then
        print_success "Service status check passed"
    else
        print_warning "Service status check had issues"
    fi
    
    # Test starting databases first
    log_output "Starting database services..."
    if python3 main.py start mysql-database --config "$TEST_CONFIG"; then
        print_success "MySQL database started"
    else
        print_error "Failed to start MySQL database"
        return 1
    fi
    
    if python3 main.py start postgres-redis --config "$TEST_CONFIG"; then
        print_success "PostgreSQL/Redis started"
    else
        print_error "Failed to start PostgreSQL/Redis"
        return 1
    fi
    
    # Wait for databases to be ready
    log_output "Waiting for databases to be ready..."
    sleep 30
    
    # Test starting web app
    log_output "Starting web application..."
    if python3 main.py start web-app --config "$TEST_CONFIG"; then
        print_success "Web application started"
    else
        print_error "Failed to start web application"
        return 1
    fi
    
    # Wait for web app to be ready
    log_output "Waiting for web application to be ready..."
    sleep 30
    
    # Test health checks
    log_output "Testing health checks..."
    
    # Test MySQL
    if curl -s http://localhost:8082 >/dev/null 2>&1; then
        print_success "phpMyAdmin is accessible"
    else
        print_warning "phpMyAdmin is not accessible"
    fi
    
    # Test web app
    if curl -s http://localhost:8080/health >/dev/null 2>&1; then
        print_success "Web application health check passed"
    else
        print_warning "Web application health check failed"
    fi
    
    # Test PostgreSQL
    if docker exec postgres pg_isready -U postgres >/dev/null 2>&1; then
        print_success "PostgreSQL is ready"
    else
        print_warning "PostgreSQL is not ready"
    fi
    
    # Test Redis
    if docker exec redis redis-cli ping >/dev/null 2>&1; then
        print_success "Redis is ready"
    else
        print_warning "Redis is not ready"
    fi
}

# Function to show service status
show_service_status() {
    print_header "Service Status"
    
    echo -e "${CYAN}Running Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${CYAN}Service URLs:${NC}"
    echo "Web Application: http://localhost:8080"
    echo "phpMyAdmin: http://localhost:8082"
    echo "PostgreSQL: localhost:5432"
    echo "Redis: localhost:6379"
    
    echo -e "\n${CYAN}Test Commands:${NC}"
    echo "Check service status: python3 main.py status --config $TEST_CONFIG"
    echo "View logs: tail -f logs/docker_manager_$(date +%Y%m%d).log"
    echo "Stop all services: python3 main.py stop-all --config $TEST_CONFIG"
}

# Function to cleanup test environment
cleanup_test() {
    print_header "Cleaning Up Test Environment"
    
    # Stop all services
    log_output "Stopping all services..."
    python3 main.py stop-all --config "$TEST_CONFIG" || true
    
    # Remove test containers
    log_output "Removing test containers..."
    docker rm -f $(docker ps -aq --filter "name=test") 2>/dev/null || true
    
    # Remove test images
    log_output "Removing test images..."
    docker rmi $(docker images -q --filter "dangling=true") 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Function to show test summary
show_test_summary() {
    print_header "Test Summary"
    
    echo -e "${GREEN}✅ System Requirements:${NC} Checked"
    echo -e "${GREEN}✅ Permissions:${NC} Fixed"
    echo -e "${GREEN}✅ System Dependencies:${NC} Installed"
    echo -e "${GREEN}✅ Docker:${NC} Installed and tested"
    echo -e "${GREEN}✅ Docker Compose:${NC} Installed and tested"
    echo -e "${GREEN}✅ Python Environment:${NC} Setup complete"
    echo -e "${GREEN}✅ Configuration:${NC} Validated"
    echo -e "${GREEN}✅ Services:${NC} Tested"
    
    echo -e "\n${CYAN}Next Steps:${NC}"
    echo "1. Log out and log back in for Docker group changes"
    echo "2. Start services: python3 main.py start-all --config $TEST_CONFIG"
    echo "3. Monitor services: python3 monitor.py --config $TEST_CONFIG"
    echo "4. View logs: tail -f logs/docker_manager_$(date +%Y%m%d).log"
    
    echo -e "\n${CYAN}Test Log:${NC} $LOG_FILE"
}

# Main execution
main() {
    print_header "Ubuntu 22.04 Docker Service Manager Test"
    
    # Create log file
    touch "$LOG_FILE"
    log_output "Starting Ubuntu 22.04 test"
    
    # Run all test phases
    check_system_requirements
    fix_permissions
    install_system_dependencies
    install_docker
    install_docker_compose
    setup_python_environment
    create_directories
    test_docker
    test_configuration
    test_services
    show_service_status
    show_test_summary
    
    log_output "Test completed successfully"
    print_success "Ubuntu 22.04 test completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "cleanup")
        cleanup_test
        ;;
    "status")
        show_service_status
        ;;
    "test")
        test_services
        ;;
    "fix-permissions")
        fix_permissions
        ;;
    *)
        main
        ;;
esac 