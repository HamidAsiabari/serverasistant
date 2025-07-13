#!/bin/bash

# Quick GitLab Password Reset Script
# This script quickly resets the GitLab root password

set -e

echo "=== Quick GitLab Password Reset ==="

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

# Check if GitLab is healthy
print_status "Checking GitLab health..."
if ! docker exec gitlab /opt/gitlab/bin/gitlab-healthcheck --fail > /dev/null 2>&1; then
    print_warning "GitLab is not fully initialized yet"
    echo "Please wait for GitLab to finish initializing (5-10 minutes)"
    echo "You can check the status with: docker logs gitlab"
    exit 1
fi

print_success "GitLab is healthy"

# Prompt for new password
echo ""
echo "Enter the new password for GitLab root user:"
read -s NEW_PASSWORD

if [ -z "$NEW_PASSWORD" ]; then
    print_error "Password cannot be empty"
    exit 1
fi

echo ""
echo "Confirm the new password:"
read -s CONFIRM_PASSWORD

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    print_error "Passwords do not match"
    exit 1
fi

print_status "Resetting GitLab root password..."

# Create a temporary script to run in the Rails console
cat > /tmp/gitlab_password_reset.rb << EOF
user = User.find_by_username('root')
if user
  user.password = '$NEW_PASSWORD'
  user.password_confirmation = '$NEW_PASSWORD'
  if user.save!
    puts "SUCCESS: Root password has been reset"
  else
    puts "ERROR: Failed to save password"
    puts user.errors.full_messages
  end
else
  puts "ERROR: Root user not found"
end
exit
EOF

# Execute the password reset
print_status "Executing password reset..."
if docker exec -i gitlab gitlab-rails console -e production < /tmp/gitlab_password_reset.rb; then
    print_success "Password reset completed!"
    echo ""
    echo "You can now login to GitLab with:"
    echo "  Username: root"
    echo "  Password: (the password you just set)"
    echo ""
    echo "URL: http://gitlab.soject.com"
else
    print_error "Password reset failed"
    echo "Please try the manual method:"
    echo "  docker exec -it gitlab gitlab-rails console -e production"
    echo "  Then run the commands manually"
fi

# Clean up temporary file
rm -f /tmp/gitlab_password_reset.rb

print_success "Script completed!" 