#!/bin/bash
# Docker Service Manager - Linux Ubuntu Installation Script

set -e

echo "=========================================="
echo "Docker Service Manager - Linux Installation"
echo "=========================================="

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update package list
print_status "Updating package list..."
sudo apt update

# Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package list
    sudo apt update

    # Install Docker
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    print_success "Docker installed successfully"
else
    print_warning "Docker is already installed"
fi

# Install Docker Compose (standalone)
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    # Download Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_warning "Docker Compose is already installed"
fi

# Add user to docker group
print_status "Adding user to docker group..."
if ! groups $USER | grep -q docker; then
    sudo usermod -aG docker $USER
    print_warning "User added to docker group. Please log out and log back in for changes to take effect."
else
    print_success "User is already in docker group"
fi

# Create virtual environment
print_status "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs
mkdir -p reports
mkdir -p services

# Set proper permissions
print_status "Setting proper permissions..."
chmod +x main.py
chmod +x monitor.py
chmod +x test_installation.py

# Test Docker installation
print_status "Testing Docker installation..."
if docker --version &> /dev/null; then
    print_success "Docker is working"
else
    print_error "Docker is not working. Please check installation."
    exit 1
fi

# Test Docker Compose installation
print_status "Testing Docker Compose installation..."
if docker-compose --version &> /dev/null; then
    print_success "Docker Compose is working"
else
    print_error "Docker Compose is not working. Please check installation."
    exit 1
fi

# Create systemd service file (optional)
print_status "Creating systemd service file..."
sudo tee /etc/systemd/system/docker-manager.service > /dev/null <<EOF
[Unit]
Description=Docker Service Manager
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=PATH=$(pwd)/venv/bin
ExecStart=$(pwd)/venv/bin/python monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

print_success "Systemd service file created at /etc/systemd/system/docker-manager.service"

# Create startup script
print_status "Creating startup script..."
tee start.sh > /dev/null <<EOF
#!/bin/bash
# Docker Service Manager Startup Script

cd $(pwd)
source venv/bin/activate

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Docker is not running. Starting Docker..."
    sudo systemctl start docker
    sleep 5
fi

# Start the manager
python main.py \$@
EOF

chmod +x start.sh

# Create monitoring startup script
print_status "Creating monitoring startup script..."
tee start_monitor.sh > /dev/null <<EOF
#!/bin/bash
# Docker Service Manager Monitor Startup Script

cd $(pwd)
source venv/bin/activate

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Docker is not running. Starting Docker..."
    sudo systemctl start docker
    sleep 5
fi

# Start the monitor
python monitor.py \$@
EOF

chmod +x start_monitor.sh

print_success "Installation completed successfully!"
echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "1. Log out and log back in (for docker group changes)"
echo "2. Test the installation:"
echo "   ./test_installation.py"
echo ""
echo "3. Start using the manager:"
echo "   ./start.sh status"
echo "   ./start.sh start-all"
echo "   ./start_monitor.sh"
echo ""
echo "4. Optional: Enable systemd service:"
echo "   sudo systemctl enable docker-manager.service"
echo "   sudo systemctl start docker-manager.service"
echo ""
echo "5. Check logs:"
echo "   tail -f logs/docker_manager_$(date +%Y%m%d).log"
echo "==========================================" 