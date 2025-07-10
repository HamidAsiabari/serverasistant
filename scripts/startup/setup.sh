#!/bin/bash

# ServerAssistant Startup Script for Linux
# This script handles first-time setup and launches ServerAssistant

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Get the directory where this script is located and navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

print_status "ServerAssistant Startup Script (Organized Structure)"
print_status "Working directory: $PROJECT_ROOT"

# Virtual environment setup
VENV_DIR="$PROJECT_ROOT/venv"
VENV_ACTIVATE="$VENV_DIR/bin/activate"

# Check if this is first-time setup
FIRST_TIME_FILE="$PROJECT_ROOT/.first_time_setup_complete"

check_first_time() {
    if [ ! -f "$FIRST_TIME_FILE" ]; then
        print_warning "First-time setup detected!"
        return 0  # First time
    else
        print_success "Previous setup detected. Skipping installation."
        return 1  # Not first time
    fi
}

# Check if Python is installed
check_python() {
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        print_success "Python found: $PYTHON_VERSION"
        return 0
    elif command -v python &> /dev/null; then
        PYTHON_VERSION=$(python --version 2>&1)
        print_success "Python found: $PYTHON_VERSION"
        return 0
    else
        print_error "Python not found. Please install Python 3.7+ first."
        exit 1
    fi
}

# Check if virtual environment exists
check_venv() {
    if [ -d "$VENV_DIR" ] && [ -f "$VENV_ACTIVATE" ]; then
        print_success "Virtual environment found"
        return 0
    else
        print_warning "Virtual environment not found"
        return 1
    fi
}

# Create virtual environment
create_venv() {
    print_status "Creating virtual environment..."
    
    # Check if python3-venv is installed
    if ! dpkg -l | grep -q python3-venv; then
        print_status "Installing python3-venv..."
        sudo apt update
        sudo apt install -y python3-venv python3-pip
    fi
    
    # Create virtual environment
    python3 -m venv "$VENV_DIR"
    print_success "Virtual environment created at $VENV_DIR"
}

# Activate virtual environment
activate_venv() {
    if [ -f "$VENV_ACTIVATE" ]; then
        source "$VENV_ACTIVATE"
        print_success "Virtual environment activated"
        return 0
    else
        print_error "Virtual environment activation script not found"
        return 1
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker found: $DOCKER_VERSION"
        return 0
    else
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
}

# Check if Docker Compose is installed
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        print_success "Docker Compose found: $COMPOSE_VERSION"
        return 0
    else
        print_error "Docker Compose not found. Please install Docker Compose first."
        exit 1
    fi
}

# Check if Docker daemon is running
check_docker_daemon() {
    if docker info &> /dev/null; then
        print_success "Docker daemon is running"
        return 0
    else
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
}

# Install Python dependencies in virtual environment
install_python_dependencies() {
    print_status "Installing Python dependencies in virtual environment..."
    
    if [ -f "requirements.txt" ]; then
        # Activate virtual environment and install dependencies
        source "$VENV_ACTIVATE"
        pip install --upgrade pip
        pip install -r requirements.txt
        
        # Install additional dependencies for the organized structure
        pip install tabulate psutil colorama
        
        print_success "Python dependencies installed in virtual environment"
    else
        print_warning "requirements.txt not found, skipping Python dependencies"
    fi
}

# Install system dependencies
install_system_dependencies() {
    print_status "Installing system dependencies..."
    
    if [ -f "scripts/setup/install_requirements.sh" ]; then
        chmod +x scripts/setup/install_requirements.sh
        ./scripts/setup/install_requirements.sh
        print_success "System dependencies installed"
    else
        print_warning "install_requirements.sh not found, skipping system dependencies"
    fi
}

# Fix line endings and permissions
fix_environment() {
    print_status "Fixing environment issues..."
    
    # Fix line endings
    if [ -f "scripts/maintenance/fix_line_endings.sh" ]; then
        chmod +x scripts/maintenance/fix_line_endings.sh
        ./scripts/maintenance/fix_line_endings.sh
        print_success "Line endings fixed"
    fi
    
    # Fix permissions
    if [ -f "scripts/maintenance/fix_permissions.sh" ]; then
        chmod +x scripts/maintenance/fix_permissions.sh
        ./scripts/maintenance/fix_permissions.sh
        print_success "Permissions fixed"
    fi
    
    # Make scripts executable
    find . -name "*.sh" -type f -exec chmod +x {} \;
    print_success "Script permissions updated"
}

# Setup persistent storage
setup_persistent_storage() {
    print_status "Setting up persistent storage..."
    
    # GitLab persistent storage
    if [ -d "example_services/gitlab" ]; then
        cd example_services/gitlab
        if [ -f "setup_persistent_storage.sh" ]; then
            chmod +x setup_persistent_storage.sh
            ./setup_persistent_storage.sh
            print_success "GitLab persistent storage setup completed"
        fi
        cd "$PROJECT_ROOT"
    fi
    
    # Mail server persistent storage
    if [ -d "example_services/mail-server" ]; then
        cd example_services/mail-server
        if [ -f "setup_persistent_storage.sh" ]; then
            chmod +x setup_persistent_storage.sh
            ./setup_persistent_storage.sh
            print_success "Mail server persistent storage setup completed"
        fi
        cd "$PROJECT_ROOT"
    fi
}

# Generate SSL certificates
generate_ssl() {
    print_status "Generating SSL certificates..."
    
    if [ -d "example_services/nginx" ]; then
        cd example_services/nginx
        if [ -f "generate_ssl.sh" ]; then
            chmod +x generate_ssl.sh
            ./generate_ssl.sh
            print_success "SSL certificates generated"
        fi
        cd "$PROJECT_ROOT"
    fi
}

# Start minimal services for nginx
start_minimal_services() {
    print_status "Starting minimal services for nginx..."
    
    if [ -d "docker_services/nginx" ]; then
        cd docker_services/nginx
        if [ -f "start_minimal_services.sh" ]; then
            chmod +x start_minimal_services.sh
            ./start_minimal_services.sh
            print_success "Minimal services started"
        fi
        cd "$PROJECT_ROOT"
    fi
}

# First-time setup
perform_first_time_setup() {
    print_status "Performing first-time setup..."
    
    # Check prerequisites
    check_python
    check_docker
    check_docker_compose
    check_docker_daemon
    
    # Create virtual environment if needed
    if ! check_venv; then
        create_venv
    fi
    
    # Install dependencies
    install_python_dependencies
    install_system_dependencies
    
    # Fix environment
    fix_environment
    
    # Setup persistent storage
    setup_persistent_storage
    
    # Generate SSL certificates
    generate_ssl
    
    # Start minimal services
    start_minimal_services
    
    # Mark first-time setup as complete
    echo "$(date): First-time setup completed successfully" > "$FIRST_TIME_FILE"
    print_success "First-time setup completed!"
}

# Launch ServerAssistant with organized structure
launch_serverassistant() {
    print_status "Launching ServerAssistant (Organized Structure)..."
    echo ""
    
    # Try organized structure first
    if [ -f "src/main.py" ]; then
        # Make sure the script is executable
        chmod +x src/main.py
        
        # Activate virtual environment and run ServerAssistant
        source "$VENV_ACTIVATE"
        python src/main.py
    elif [ -f "serverassistant.py" ]; then
        # Fallback to refactored serverassistant.py
        chmod +x serverassistant.py
        source "$VENV_ACTIVATE"
        python serverassistant.py
    else
        print_error "No ServerAssistant found!"
        exit 1
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "    ServerAssistant Startup Script"
    echo "         (Organized Structure)"
    echo "=========================================="
    echo ""
    
    # Check if this is first time
    if check_first_time; then
        print_status "Starting first-time setup..."
        perform_first_time_setup
    else
        # Show options for existing setup
        echo "Previous setup detected. Choose an option:"
        echo "1. Launch ServerAssistant (default)"
        echo "2. Start minimal services for nginx"
        echo "3. Exit"
        echo ""
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            2)
                print_status "Starting minimal services..."
                start_minimal_services
                echo ""
                print_status "Minimal services started. You can now launch ServerAssistant."
                ;;
            3)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_status "Launching ServerAssistant..."
                ;;
        esac
    fi
    
    # Launch ServerAssistant
    launch_serverassistant
}

# Run main function
main "$@" 