#!/bin/bash
# Test Runner Script for ServerAssistant
# This script provides a simple way to run tests from the project root

set -e

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "TEST_TYPE:"
    echo "  unit         Run unit tests only"
    echo "  integration  Run integration tests only"
    echo "  e2e          Run end-to-end tests only"
    echo "  quick        Run quick validation tests"
    echo "  ubuntu       Run Ubuntu-specific tests"
    echo "  mysql        Run MySQL connectivity check"
    echo "  all          Run all tests (default)"
    echo "  list         List all available tests"
    echo ""
    echo "OPTIONS:"
    echo "  -v, --verbose    Verbose output"
    echo "  -c, --coverage   Generate coverage report"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 unit               # Run unit tests only"
    echo "  $0 -v integration     # Run integration tests with verbose output"
    echo "  $0 -c e2e             # Run e2e tests with coverage"
}

# Parse command line arguments
TEST_TYPE="all"
VERBOSE=false
COVERAGE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        unit|integration|e2e|quick|ubuntu|mysql|all|list)
            TEST_TYPE="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [[ ! -f "config.json" ]]; then
    print_error "This script must be run from the project root directory"
    exit 1
fi

# Check if tests directory exists
if [[ ! -d "tests" ]]; then
    print_error "Tests directory not found. Please run this script from the project root."
    exit 1
fi

print_status "Starting test execution..."
print_status "Test type: $TEST_TYPE"
print_status "Verbose: $VERBOSE"
print_status "Coverage: $COVERAGE"

# Build pytest arguments
PYTEST_ARGS=""
if [[ "$VERBOSE" == "true" ]]; then
    PYTEST_ARGS="$PYTEST_ARGS -v"
fi

if [[ "$COVERAGE" == "true" ]]; then
    PYTEST_ARGS="$PYTEST_ARGS --cov=src --cov-report=html --cov-report=term-missing"
fi

# Run tests based on type
case $TEST_TYPE in
    unit)
        print_status "Running unit tests..."
        python -m pytest tests/unit/ $PYTEST_ARGS
        ;;
    integration)
        print_status "Running integration tests..."
        python -m pytest tests/integration/ $PYTEST_ARGS
        ;;
    e2e)
        print_status "Running end-to-end tests..."
        python -m pytest tests/e2e/ $PYTEST_ARGS
        ;;
    quick)
        print_status "Running quick tests..."
        if [[ -f "tests/scripts/quick_test.sh" ]]; then
            bash tests/scripts/quick_test.sh
        else
            print_error "Quick test script not found"
            exit 1
        fi
        ;;
    ubuntu)
        print_status "Running Ubuntu tests..."
        if [[ -f "tests/scripts/test_ubuntu22.sh" ]]; then
            bash tests/scripts/test_ubuntu22.sh
        else
            print_error "Ubuntu test script not found"
            exit 1
        fi
        ;;
    mysql)
        print_status "Running MySQL connectivity check..."
        if [[ -f "tests/scripts/check_mysql.sh" ]]; then
            bash tests/scripts/check_mysql.sh
        else
            print_error "MySQL check script not found"
            exit 1
        fi
        ;;
    list)
        print_status "Listing available tests..."
        python tests/run_tests.py list
        ;;
    all)
        print_status "Running all tests..."
        python tests/run_tests.py all
        ;;
    *)
        print_error "Unknown test type: $TEST_TYPE"
        show_usage
        exit 1
        ;;
esac

# Check exit status
if [[ $? -eq 0 ]]; then
    print_success "All tests completed successfully!"
else
    print_error "Some tests failed!"
    exit 1
fi 