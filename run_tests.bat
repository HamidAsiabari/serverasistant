@echo off
REM Test Runner Script for ServerAssistant (Windows)
REM This script provides a simple way to run tests from the project root

setlocal enabledelayedexpansion

REM Set colors for output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Function to print colored output
:print_status
echo %BLUE%[INFO]%NC% %~1
goto :eof

:print_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
goto :eof

REM Function to show usage
:show_usage
echo Usage: %~nx0 [OPTIONS] [TEST_TYPE]
echo.
echo TEST_TYPE:
echo   unit         Run unit tests only
echo   integration  Run integration tests only
echo   e2e          Run end-to-end tests only
echo   quick        Run quick validation tests
echo   ubuntu       Run Ubuntu-specific tests
echo   mysql        Run MySQL connectivity check
echo   all          Run all tests (default)
echo   list         List all available tests
echo.
echo OPTIONS:
echo   -v, --verbose    Verbose output
echo   -c, --coverage   Generate coverage report
echo   -h, --help       Show this help message
echo.
echo Examples:
echo   %~nx0                    # Run all tests
echo   %~nx0 unit               # Run unit tests only
echo   %~nx0 -v integration     # Run integration tests with verbose output
echo   %~nx0 -c e2e             # Run e2e tests with coverage
goto :eof

REM Parse command line arguments
set "TEST_TYPE=all"
set "VERBOSE=false"
set "COVERAGE=false"

:parse_args
if "%~1"=="" goto :end_parse
if "%~1"=="-v" (
    set "VERBOSE=true"
    shift
    goto :parse_args
)
if "%~1"=="--verbose" (
    set "VERBOSE=true"
    shift
    goto :parse_args
)
if "%~1"=="-c" (
    set "COVERAGE=true"
    shift
    goto :parse_args
)
if "%~1"=="--coverage" (
    set "COVERAGE=true"
    shift
    goto :parse_args
)
if "%~1"=="-h" (
    call :show_usage
    exit /b 0
)
if "%~1"=="--help" (
    call :show_usage
    exit /b 0
)
if "%~1"=="unit" (
    set "TEST_TYPE=unit"
    shift
    goto :parse_args
)
if "%~1"=="integration" (
    set "TEST_TYPE=integration"
    shift
    goto :parse_args
)
if "%~1"=="e2e" (
    set "TEST_TYPE=e2e"
    shift
    goto :parse_args
)
if "%~1"=="quick" (
    set "TEST_TYPE=quick"
    shift
    goto :parse_args
)
if "%~1"=="ubuntu" (
    set "TEST_TYPE=ubuntu"
    shift
    goto :parse_args
)
if "%~1"=="mysql" (
    set "TEST_TYPE=mysql"
    shift
    goto :parse_args
)
if "%~1"=="all" (
    set "TEST_TYPE=all"
    shift
    goto :parse_args
)
if "%~1"=="list" (
    set "TEST_TYPE=list"
    shift
    goto :parse_args
)
call :print_error "Unknown option: %~1"
call :show_usage
exit /b 1

:end_parse

REM Check if we're in the right directory
if not exist "config.json" (
    call :print_error "This script must be run from the project root directory"
    exit /b 1
)

REM Check if tests directory exists
if not exist "tests" (
    call :print_error "Tests directory not found. Please run this script from the project root."
    exit /b 1
)

call :print_status "Starting test execution..."
call :print_status "Test type: %TEST_TYPE%"
call :print_status "Verbose: %VERBOSE%"
call :print_status "Coverage: %COVERAGE%"

REM Build pytest arguments
set "PYTEST_ARGS="
if "%VERBOSE%"=="true" (
    set "PYTEST_ARGS=%PYTEST_ARGS% -v"
)

if "%COVERAGE%"=="true" (
    set "PYTEST_ARGS=%PYTEST_ARGS% --cov=src --cov-report=html --cov-report=term-missing"
)

REM Run tests based on type
if "%TEST_TYPE%"=="unit" (
    call :print_status "Running unit tests..."
    python -m pytest tests\unit\ %PYTEST_ARGS%
    goto :check_exit
)

if "%TEST_TYPE%"=="integration" (
    call :print_status "Running integration tests..."
    python -m pytest tests\integration\ %PYTEST_ARGS%
    goto :check_exit
)

if "%TEST_TYPE%"=="e2e" (
    call :print_status "Running end-to-end tests..."
    python -m pytest tests\e2e\ %PYTEST_ARGS%
    goto :check_exit
)

if "%TEST_TYPE%"=="quick" (
    call :print_status "Running quick tests..."
    if exist "tests\scripts\quick_test.sh" (
        bash tests\scripts\quick_test.sh
    ) else (
        call :print_error "Quick test script not found"
        exit /b 1
    )
    goto :check_exit
)

if "%TEST_TYPE%"=="ubuntu" (
    call :print_status "Running Ubuntu tests..."
    if exist "tests\scripts\test_ubuntu22.sh" (
        bash tests\scripts\test_ubuntu22.sh
    ) else (
        call :print_error "Ubuntu test script not found"
        exit /b 1
    )
    goto :check_exit
)

if "%TEST_TYPE%"=="mysql" (
    call :print_status "Running MySQL connectivity check..."
    if exist "tests\scripts\check_mysql.sh" (
        bash tests\scripts\check_mysql.sh
    ) else (
        call :print_error "MySQL check script not found"
        exit /b 1
    )
    goto :check_exit
)

if "%TEST_TYPE%"=="list" (
    call :print_status "Listing available tests..."
    python tests\run_tests.py list
    goto :check_exit
)

if "%TEST_TYPE%"=="all" (
    call :print_status "Running all tests..."
    python tests\run_tests.py all
    goto :check_exit
)

call :print_error "Unknown test type: %TEST_TYPE%"
call :show_usage
exit /b 1

:check_exit
REM Check exit status
if %ERRORLEVEL% EQU 0 (
    call :print_success "All tests completed successfully!"
) else (
    call :print_error "Some tests failed!"
    exit /b 1
) 