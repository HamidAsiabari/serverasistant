#!/bin/bash
# ServerAssistant Code Update Script
# This script updates the code from git repository and sets proper permissions

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

# Function to check if we're in a git repository
check_git_repo() {
    if [[ ! -d ".git" ]]; then
        print_error "This directory is not a git repository"
        print_error "Please run this script from the root of the ServerAssistant repository"
        exit 1
    fi
}

# Function to check git status
check_git_status() {
    print_status "Checking git status..."
    
    # Check if there are uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "There are uncommitted changes in your repository:"
        git status --short
        
        echo ""
        read -p "Do you want to stash these changes before updating? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Stashing uncommitted changes..."
            git stash push -m "Auto-stash before update $(date)"
            STASHED=true
        else
            print_error "Cannot proceed with uncommitted changes"
            print_error "Please commit or stash your changes first"
            exit 1
        fi
    else
        STASHED=false
    fi
}

# Function to backup current state
backup_current_state() {
    print_status "Creating backup of current state..."
    
    # Create backup directory with timestamp
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Copy important files
    if [[ -f "config.json" ]]; then
        cp config.json "$BACKUP_DIR/"
        print_status "Backed up config.json"
    fi
    
    if [[ -d "venv" ]]; then
        print_status "Virtual environment exists - will be preserved"
    fi
    
    print_success "Backup created in: $BACKUP_DIR"
}

# Function to update code from git
update_code() {
    print_step "1. Updating code from git repository"
    
    # Check if we're in a git repository
    check_git_repo
    
    # Check git status and handle uncommitted changes
    check_git_status
    
    # Create backup
    backup_current_state
    
    # Reset to previous commit and pull latest changes
    print_status "Resetting to previous commit..."
    git reset --hard HEAD~1
    
    print_status "Pulling latest changes from remote repository..."
    git pull
    
    print_success "Code updated successfully from git repository"
}

# Function to set executable permissions
set_executable_permissions() {
    print_step "2. Setting executable permissions on scripts"
    
    # Main scripts
    print_status "Setting permissions on main scripts..."
    chmod +x install_prerequisites.sh 2>/dev/null || true
    chmod +x setup.sh 2>/dev/null || true
    chmod +x start.sh 2>/dev/null || true
    chmod +x update_server.sh 2>/dev/null || true
    
    # Startup scripts
    print_status "Setting permissions on startup scripts..."
    chmod +x scripts/startup/*.sh 2>/dev/null || true
    
    # Linux scripts
    print_status "Setting permissions on Linux scripts..."
    chmod +x scripts/linux/*.sh 2>/dev/null || true
    
    # Maintenance scripts
    print_status "Setting permissions on maintenance scripts..."
    chmod +x scripts/maintenance/*.sh 2>/dev/null || true
    
    # Setup scripts
    print_status "Setting permissions on setup scripts..."
    chmod +x scripts/setup/*.sh 2>/dev/null || true
    
    # Backup scripts
    print_status "Setting permissions on backup scripts..."
    chmod +x scripts/backup/*.sh 2>/dev/null || true
    
    # Test scripts
    print_status "Setting permissions on test scripts..."
    chmod +x tests/scripts/*.sh 2>/dev/null || true
    
    # Docker service scripts
    print_status "Setting permissions on Docker service scripts..."
    find docker_services/ -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    print_success "All script permissions set successfully"
}

# Function to verify update
verify_update() {
    print_step "3. Verifying update"
    
    # Check if key files exist
    if [[ -f "serverassistant.py" ]]; then
        print_success "Main application file exists"
    else
        print_warning "Main application file not found"
    fi
    
    if [[ -f "requirements.txt" ]]; then
        print_success "Requirements file exists"
    else
        print_warning "Requirements file not found"
    fi
    
    if [[ -f "config.json" ]]; then
        print_success "Configuration file exists"
    else
        print_warning "Configuration file not found"
    fi
    
    # Check git status
    print_status "Current git status:"
    git status --short
    
    # Show recent commits
    print_status "Recent commits:"
    git log --oneline -5
}

# Function to restore stashed changes
restore_stashed_changes() {
    if [[ "$STASHED" == true ]]; then
        print_step "4. Restoring stashed changes"
        
        if git stash list | grep -q "Auto-stash before update"; then
            print_status "Restoring stashed changes..."
            git stash pop
            
            if [[ $? -eq 0 ]]; then
                print_success "Stashed changes restored successfully"
            else
                print_warning "There were conflicts when restoring stashed changes"
                print_warning "Please resolve conflicts manually"
            fi
        fi
    fi
}

# Function to check if virtual environment needs updating
check_virtual_environment() {
    print_step "5. Checking virtual environment"
    
    if [[ -d "venv" ]]; then
        print_status "Virtual environment exists"
        
        # Check if requirements.txt has changed
        if [[ -f "requirements.txt" ]]; then
            print_status "Checking if Python dependencies need updating..."
            
            # Activate virtual environment and check for outdated packages
            source venv/bin/activate
            
            # Get list of installed packages
            INSTALLED_PACKAGES=$(pip list --format=freeze)
            
            # Check if any packages from requirements.txt are missing or outdated
            while IFS= read -r line; do
                if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                    PACKAGE_NAME=$(echo "$line" | cut -d'=' -f1)
                    PACKAGE_VERSION=$(echo "$line" | cut -d'=' -f2)
                    
                    if echo "$INSTALLED_PACKAGES" | grep -q "^$PACKAGE_NAME=="; then
                        INSTALLED_VERSION=$(echo "$INSTALLED_PACKAGES" | grep "^$PACKAGE_NAME==" | cut -d'=' -f2)
                        if [[ "$INSTALLED_VERSION" != "$PACKAGE_VERSION" ]]; then
                            print_warning "Package $PACKAGE_NAME version mismatch: installed=$INSTALLED_VERSION, required=$PACKAGE_VERSION"
                            NEEDS_UPDATE=true
                        fi
                    else
                        print_warning "Package $PACKAGE_NAME not installed"
                        NEEDS_UPDATE=true
                    fi
                fi
            done < requirements.txt
            
            deactivate
            
            if [[ "$NEEDS_UPDATE" == true ]]; then
                echo ""
                read -p "Do you want to update the virtual environment? (y/N): " -n 1 -r
                echo ""
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    print_status "Updating virtual environment..."
                    source venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    deactivate
                    print_success "Virtual environment updated successfully"
                else
                    print_warning "Virtual environment not updated"
                fi
            else
                print_success "Virtual environment is up to date"
            fi
        fi
    else
        print_warning "No virtual environment found"
        echo ""
        read -p "Do you want to create a new virtual environment? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Creating new virtual environment..."
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt
            deactivate
            print_success "Virtual environment created successfully"
        fi
    fi
}

# Function to show next steps
show_next_steps() {
    print_header "Update Complete!"
    print_success "ServerAssistant code has been updated successfully!"
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
    echo "4. If you need to install prerequisites:"
    echo "   ./install_prerequisites.sh"
    echo ""
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}Backup created in: $BACKUP_DIR${NC}"
        echo "You can restore files from there if needed"
    fi
}

# Main function
main() {
    print_header "ServerAssistant Code Update"
    
    # Check if we're in the right directory
    if [[ ! -f "README.md" ]] || [[ ! -d "src" ]]; then
        print_error "This doesn't appear to be the ServerAssistant root directory"
        print_error "Please run this script from the root of the ServerAssistant repository"
        exit 1
    fi
    
    # Update code
    update_code
    
    # Set permissions
    set_executable_permissions
    
    # Verify update
    verify_update
    
    # Restore stashed changes if any
    restore_stashed_changes
    
    # Check virtual environment
    check_virtual_environment
    
    # Show next steps
    show_next_steps
}

# Run main function
main "$@" 