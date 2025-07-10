#!/bin/bash
# ServerAssistant Prerequisites Installation Script
# This script installs all required dependencies for the ServerAssistant project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
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

print_header() {
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}==========================================${NC}"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            OS=$(uname -s)
            VER=$(uname -r)
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
    else
        OS="Unknown"
        VER="Unknown"
    fi
    echo "$OS $VER"
}

# Function to get OS name only
get_os_name() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "$NAME"
        else
            echo "$(uname -s)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    else
        echo "Unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        
        if [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -ge 7 ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to install Python on Ubuntu/Debian
install_python_ubuntu() {
    print_status "Installing Python 3.7+ on Ubuntu/Debian..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential
    
    # Check if python3-venv is available, if not try version-specific package
    if ! python3 -m venv --help >/dev/null 2>&1; then
        print_status "python3-venv not working, trying version-specific package..."
        PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
        print_status "Installing python${PYTHON_VERSION}-venv..."
        sudo apt install -y "python${PYTHON_VERSION}-venv"
        
        # Verify venv works now
        if ! python3 -m venv --help >/dev/null 2>&1; then
            print_error "Failed to install python3-venv package"
            print_error "Please install it manually: sudo apt install python3-venv"
            return 1
        fi
    fi
    
    print_success "Python installed successfully"
}

# Function to install Python on CentOS/RHEL/Fedora
install_python_centos() {
    print_status "Installing Python 3.7+ on CentOS/RHEL/Fedora..."
    if command_exists dnf; then
        sudo dnf install -y python3 python3-pip python3-devel gcc
    elif command_exists yum; then
        sudo yum install -y python3 python3-pip python3-devel gcc
    fi
    print_success "Python installed successfully"
}

# Function to install Docker on Ubuntu/Debian
install_docker_ubuntu() {
    print_status "Installing Docker on Ubuntu/Debian..."
    
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisites
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully"
    print_warning "You may need to log out and back in for docker group changes to take effect"
}

# Function to install Docker on CentOS/RHEL/Fedora
install_docker_centos() {
    print_status "Installing Docker on CentOS/RHEL/Fedora..."
    
    # Remove old versions
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
    
    # Install prerequisites
    if command_exists dnf; then
        sudo dnf install -y dnf-utils
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif command_exists yum; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed successfully"
    print_warning "You may need to log out and back in for docker group changes to take effect"
}

# Function to install Docker Compose (standalone)
install_docker_compose() {
    print_status "Installing Docker Compose..."
    
    # Download Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make it executable
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
}

# Function to check and fix virtual environment paths
check_and_fix_venv_paths() {
    print_status "Checking virtual environment paths..."
    
    # Check if venv directory exists
    if [[ ! -d "venv" ]]; then
        print_warning "Virtual environment directory 'venv' not found"
        return 1
    fi
    
    # Check if activate script exists
    if [[ ! -f "venv/bin/activate" ]]; then
        print_error "Virtual environment activate script not found at venv/bin/activate"
        
        # Try to find activate script in different locations
        ACTIVATE_SCRIPTS=$(find venv -name "activate" -type f 2>/dev/null)
        if [[ -n "$ACTIVATE_SCRIPTS" ]]; then
            print_status "Found activate scripts in:"
            echo "$ACTIVATE_SCRIPTS"
            
            # Create symlink to standard location
            ACTIVATE_SCRIPT=$(echo "$ACTIVATE_SCRIPTS" | head -1)
            print_status "Creating symlink from $ACTIVATE_SCRIPT to venv/bin/activate"
            mkdir -p venv/bin
            ln -sf "$ACTIVATE_SCRIPT" venv/bin/activate
            print_success "Symlink created successfully"
        else
            print_error "No activate script found in virtual environment"
            return 1
        fi
    else
        print_success "Virtual environment activate script found at venv/bin/activate"
    fi
    
    # Check if python executable exists
    if [[ ! -f "venv/bin/python" ]]; then
        print_error "Python executable not found at venv/bin/python"
        
        # Try to find python executable in different locations
        PYTHON_EXECUTABLES=$(find venv -name "python*" -type f -executable 2>/dev/null)
        if [[ -n "$PYTHON_EXECUTABLES" ]]; then
            print_status "Found Python executables in:"
            echo "$PYTHON_EXECUTABLES"
            
            # Create symlink to standard location
            PYTHON_EXECUTABLE=$(echo "$PYTHON_EXECUTABLES" | head -1)
            print_status "Creating symlink from $PYTHON_EXECUTABLE to venv/bin/python"
            mkdir -p venv/bin
            ln -sf "$PYTHON_EXECUTABLE" venv/bin/python
            print_success "Python symlink created successfully"
        else
            print_error "No Python executable found in virtual environment"
            return 1
        fi
    else
        print_success "Python executable found at venv/bin/python"
    fi
    
    # Check if pip executable exists
    if [[ ! -f "venv/bin/pip" ]]; then
        print_error "Pip executable not found at venv/bin/pip"
        
        # Try to find pip executable in different locations
        PIP_EXECUTABLES=$(find venv -name "pip*" -type f -executable 2>/dev/null)
        if [[ -n "$PIP_EXECUTABLES" ]]; then
            print_status "Found pip executables in:"
            echo "$PIP_EXECUTABLES"
            
            # Create symlink to standard location
            PIP_EXECUTABLE=$(echo "$PIP_EXECUTABLES" | head -1)
            print_status "Creating symlink from $PIP_EXECUTABLE to venv/bin/pip"
            mkdir -p venv/bin
            ln -sf "$PIP_EXECUTABLE" venv/bin/pip
            print_success "Pip symlink created successfully"
        else
            print_error "No pip executable found in virtual environment"
            return 1
        fi
    else
        print_success "Pip executable found at venv/bin/pip"
    fi
    
    return 0
}

# Function to create virtual environment and install Python dependencies
setup_python_environment() {
    print_status "Setting up Python virtual environment..."
    
    # Check if virtual environment exists
    if [[ -d "venv" ]]; then
        print_warning "Virtual environment already exists. Checking and fixing paths..."
        
        # Check and fix virtual environment paths
        if check_and_fix_venv_paths; then
            print_success "Virtual environment paths fixed successfully"
        else
            print_warning "Could not fix virtual environment paths. Removing and recreating..."
            rm -rf venv
        fi
    fi
    
    # Create virtual environment if it doesn't exist
    if [[ ! -d "venv" ]]; then
        print_status "Creating new virtual environment..."
        
        # Check if python3-venv is available
        if ! python3 -m venv --help >/dev/null 2>&1; then
            print_error "python3-venv is not available"
            print_status "Installing python3-venv package..."
            
            # Try to install python3-venv
            if command_exists apt; then
                PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
                print_status "Installing python${PYTHON_VERSION}-venv..."
                sudo apt update
                sudo apt install -y "python${PYTHON_VERSION}-venv"
                
                # Verify installation
                if ! python3 -m venv --help >/dev/null 2>&1; then
                    print_error "Failed to install python3-venv package"
                    print_error "Please install it manually: sudo apt install python3-venv"
                    return 1
                fi
            else
                print_error "Cannot install python3-venv automatically"
                print_error "Please install it manually for your distribution"
                return 1
            fi
        fi
        
        # Check if ensurepip is available
        if ! python3 -m ensurepip --help >/dev/null 2>&1; then
            print_error "ensurepip is not available"
            print_status "Installing python3-ensurepip package..."
            
            # Try to install python3-ensurepip
            if command_exists apt; then
                PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
                print_status "Installing python${PYTHON_VERSION}-ensurepip..."
                sudo apt update
                sudo apt install -y "python${PYTHON_VERSION}-ensurepip"
                
                # Verify installation
                if ! python3 -m ensurepip --help >/dev/null 2>&1; then
                    print_error "Failed to install python3-ensurepip package"
                    print_error "Please install it manually: sudo apt install python3-ensurepip"
                    return 1
                fi
            else
                print_error "Cannot install python3-ensurepip automatically"
                print_error "Please install it manually for your distribution"
                return 1
            fi
        fi
        
        # Test virtual environment creation first
        print_status "Testing virtual environment creation..."
        TEST_VENV_DIR="/tmp/test_venv_$$"
        if python3 -m venv "$TEST_VENV_DIR" 2>/dev/null; then
            print_success "Virtual environment creation test passed"
            rm -rf "$TEST_VENV_DIR"
        else
            print_error "Virtual environment creation test failed"
            print_error "This indicates an issue with python3-venv or ensurepip"
            return 1
        fi
        
        # Create virtual environment
        print_status "Creating virtual environment..."
        python3 -m venv venv
        
        # Verify the virtual environment was created properly
        if ! check_and_fix_venv_paths; then
            print_error "Failed to create virtual environment properly"
            return 1
        fi
    fi
    
    # Activate virtual environment
    print_status "Activating virtual environment..."
    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
    else
        print_error "Cannot activate virtual environment - activate script not found"
        return 1
    fi
    
    # Verify activation
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        print_error "Failed to activate virtual environment"
        return 1
    fi
    
    print_success "Virtual environment activated: $VIRTUAL_ENV"
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install dependencies
    if [[ -f "requirements.txt" ]]; then
        print_status "Installing Python dependencies from requirements.txt..."
        pip install -r requirements.txt
        print_success "Python dependencies installed successfully"
    else
        print_warning "requirements.txt not found. Installing basic dependencies..."
        pip install docker pyyaml psutil colorama tabulate schedule watchdog requests textual
        print_success "Basic Python dependencies installed"
    fi
    
    # Deactivate virtual environment
    deactivate
    print_success "Virtual environment setup completed successfully"
}

# Function to verify installations
verify_installations() {
    print_header "Verifying Installations"
    
    # Check Python
    if check_python_version; then
        print_success "Python 3.7+ is installed: $(python3 --version)"
    else
        print_error "Python 3.7+ is not properly installed"
        return 1
    fi
    
    # Check Docker
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version)
        print_success "Docker is installed: $DOCKER_VERSION"
    else
        print_error "Docker is not installed"
        return 1
    fi
    
    # Check Docker Compose
    if command_exists docker-compose; then
        COMPOSE_VERSION=$(docker-compose --version)
        print_success "Docker Compose is installed: $COMPOSE_VERSION"
    else
        print_error "Docker Compose is not installed"
        return 1
    fi
    
    # Check Docker daemon
    if sudo docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running"
        print_status "Starting Docker daemon..."
        sudo systemctl start docker
        if sudo docker info >/dev/null 2>&1; then
            print_success "Docker daemon started successfully"
        else
            print_error "Failed to start Docker daemon"
            return 1
        fi
    fi
    
    # Check virtual environment
    if [[ -d "venv" ]]; then
        print_success "Python virtual environment exists"
        
        # Check and fix virtual environment paths if needed
        if check_and_fix_venv_paths; then
            print_success "Virtual environment paths are correct"
        else
            print_error "Virtual environment paths are broken and could not be fixed"
            return 1
        fi
        
        # Test virtual environment
        if [[ -f "venv/bin/activate" ]]; then
            source venv/bin/activate
            if [[ "$VIRTUAL_ENV" != "" ]]; then
                print_success "Virtual environment is working correctly"
                deactivate
            else
                print_error "Virtual environment is not working correctly"
                return 1
            fi
        else
            print_error "Virtual environment activate script not found"
            return 1
        fi
    else
        print_error "Python virtual environment does not exist"
        return 1
    fi
    
    return 0
}

# Main installation function
main() {
    print_header "ServerAssistant Prerequisites Installation"
    
    # Detect OS
    OS_INFO=$(detect_os)
    OS_NAME=$(get_os_name)
    print_status "Detected OS: $OS_INFO"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_error "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Get current user
    CURRENT_USER=$(whoami)
    print_status "Current user: $CURRENT_USER"
    
    print_step "1. Installing Python 3.7+"
    
    # Install Python if needed
    if ! check_python_version; then
        if [[ "$OS_NAME" == *"Ubuntu"* ]] || [[ "$OS_NAME" == *"Debian"* ]]; then
            install_python_ubuntu
        elif [[ "$OS_NAME" == *"CentOS"* ]] || [[ "$OS_NAME" == *"Red Hat"* ]] || [[ "$OS_NAME" == *"Fedora"* ]]; then
            install_python_centos
        else
            print_error "Unsupported OS for automatic Python installation: $OS_NAME"
            print_error "Please install Python 3.7+ manually"
            exit 1
        fi
    else
        print_success "Python 3.7+ is already installed: $(python3 --version)"
    fi
    
    # Check if python3-venv is available
    print_status "Checking python3-venv availability..."
    if ! python3 -m venv --help >/dev/null 2>&1; then
        print_warning "python3-venv is not available, installing it..."
        
        if [[ "$OS_NAME" == *"Ubuntu"* ]] || [[ "$OS_NAME" == *"Debian"* ]]; then
            PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
            print_status "Installing python${PYTHON_VERSION}-venv..."
            sudo apt update
            sudo apt install -y "python${PYTHON_VERSION}-venv"
            
            # Verify installation
            if ! python3 -m venv --help >/dev/null 2>&1; then
                print_error "Failed to install python3-venv package"
                print_error "Please install it manually: sudo apt install python3-venv"
                exit 1
            fi
            print_success "python3-venv installed successfully"
        else
            print_error "Cannot install python3-venv automatically for $OS_NAME"
            print_error "Please install it manually for your distribution"
            exit 1
        fi
    else
        print_success "python3-venv is available"
    fi
    
    # Check if ensurepip is available (needed for virtual environment creation)
    print_status "Checking ensurepip availability..."
    if ! python3 -m ensurepip --help >/dev/null 2>&1; then
        print_warning "ensurepip is not available, installing python3-ensurepip..."
        
        if [[ "$OS_NAME" == *"Ubuntu"* ]] || [[ "$OS_NAME" == *"Debian"* ]]; then
            PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
            print_status "Installing python${PYTHON_VERSION}-ensurepip..."
            sudo apt update
            sudo apt install -y "python${PYTHON_VERSION}-ensurepip"
            
            # Verify installation
            if ! python3 -m ensurepip --help >/dev/null 2>&1; then
                print_error "Failed to install python3-ensurepip package"
                print_error "Please install it manually: sudo apt install python3-ensurepip"
                exit 1
            fi
            print_success "python3-ensurepip installed successfully"
        else
            print_error "Cannot install python3-ensurepip automatically for $OS_NAME"
            print_error "Please install it manually for your distribution"
            exit 1
        fi
    else
        print_success "ensurepip is available"
    fi
    
    print_step "2. Installing Docker"
    
    # Install Docker if needed
    if ! command_exists docker; then
        if [[ "$OS_NAME" == *"Ubuntu"* ]] || [[ "$OS_NAME" == *"Debian"* ]]; then
            install_docker_ubuntu
        elif [[ "$OS_NAME" == *"CentOS"* ]] || [[ "$OS_NAME" == *"Red Hat"* ]] || [[ "$OS_NAME" == *"Fedora"* ]]; then
            install_docker_centos
        else
            print_error "Unsupported OS for automatic Docker installation: $OS_NAME"
            print_error "Please install Docker manually"
            exit 1
        fi
    else
        print_success "Docker is already installed: $(docker --version)"
    fi
    
    print_step "3. Installing Docker Compose"
    
    # Install Docker Compose if needed
    if ! command_exists docker-compose; then
        install_docker_compose
    else
        print_success "Docker Compose is already installed: $(docker-compose --version)"
    fi
    
    print_step "4. Setting up Python Environment"
    
    # Setup Python virtual environment and install dependencies
    setup_python_environment
    
    print_step "5. Verifying Installations"
    
    # Verify all installations
    if verify_installations; then
        print_header "Installation Complete!"
        print_success "All prerequisites have been installed successfully!"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "1. Activate the virtual environment:"
        echo "   source venv/bin/activate"
        echo ""
        echo "2. Run the application:"
        echo "   python serverassistant.py"
        echo "   or"
        echo "   python gui_main.py"
        echo ""
        echo "3. Or use the convenience scripts:"
        echo "   ./start.sh"
        echo "   ./scripts/startup/launch_gui.sh"
        echo ""
        echo -e "${YELLOW}Note: You may need to log out and back in for docker group changes to take effect${NC}"
    else
        print_error "Installation verification failed"
        print_error "Please check the errors above and try again"
        exit 1
    fi
}

# Run main function
main "$@" 