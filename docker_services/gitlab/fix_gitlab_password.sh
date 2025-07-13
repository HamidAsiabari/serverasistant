#!/bin/bash

# GitLab Password Fix Script
# This script helps fix GitLab login issues by finding the initial password or resetting it

set -e

echo "=== GitLab Password Fix Script ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if GitLab container is running
if ! docker ps | grep -q "gitlab"; then
    print_error "GitLab container is not running!"
    echo "Please start GitLab first:"
    echo "  cd docker_services/gitlab"
    echo "  docker-compose up -d"
    exit 1
fi

print_status "GitLab container is running"

# Method 1: Find the initial password from logs
print_status "Method 1: Finding initial password from logs..."
echo ""

# Look for the password in GitLab logs
PASSWORD_FROM_LOGS=$(docker logs gitlab 2>&1 | grep -i "password:" | tail -1)

if [ -n "$PASSWORD_FROM_LOGS" ]; then
    print_success "Found password in logs!"
    echo "Password line: $PASSWORD_FROM_LOGS"
    echo ""
    echo "Try logging in with:"
    echo "  Username: root"
    echo "  Password: (from the log line above)"
    echo ""
else
    print_warning "No password found in logs"
fi

# Method 2: Check if GitLab is fully initialized
print_status "Method 2: Checking GitLab initialization status..."
echo ""

# Check GitLab health
if docker exec gitlab /opt/gitlab/bin/gitlab-healthcheck --fail > /dev/null 2>&1; then
    print_success "GitLab is healthy and fully initialized"
else
    print_warning "GitLab is still initializing..."
    echo "This can take 5-10 minutes on first startup"
    echo "Please wait and try again later"
    echo ""
fi

# Method 3: Reset root password
print_status "Method 3: Reset root password (if needed)..."
echo ""

echo "If you need to reset the root password, you can:"
echo ""
echo "Option A: Use GitLab's built-in password reset"
echo "  1. Go to http://gitlab.soject.com/users/password/new"
echo "  2. Enter 'root' as the email"
echo "  3. Check the logs for the reset email:"
echo "     docker logs gitlab | grep -i 'reset'"
echo ""

echo "Option B: Reset password via Rails console"
echo "  1. Execute this command:"
echo "     docker exec -it gitlab gitlab-rails console -e production"
echo "  2. In the Rails console, run:"
echo "     user = User.find_by_username('root')"
echo "     user.password = 'your_new_password'"
echo "     user.password_confirmation = 'your_new_password'"
echo "     user.save!"
echo "     exit"
echo ""

echo "Option C: Use the quick reset script"
echo "  Run: ./quick_reset_password.sh"
echo ""

# Method 4: Check for common issues
print_status "Method 4: Checking for common issues..."
echo ""

# Check if GitLab is accessible
if curl -s http://localhost:8081 > /dev/null 2>&1; then
    print_success "GitLab is accessible on localhost:8081"
else
    print_warning "GitLab is not accessible on localhost:8081"
    echo "This might indicate an initialization issue"
fi

# Check recent logs for errors
print_status "Recent GitLab logs (last 20 lines):"
echo ""
docker logs gitlab --tail 20
echo ""

print_success "Password fix script completed!"
echo ""
echo "Next steps:"
echo "1. Try the password from the logs (Method 1)"
echo "2. If that doesn't work, wait for GitLab to fully initialize"
echo "3. Use one of the reset options (Method 3) if needed"
echo "4. Check the logs for any error messages" 