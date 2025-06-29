@echo off
REM ServerAssistant Startup Script for Windows
REM This script handles first-time setup and launches ServerAssistant

setlocal enabledelayedexpansion

REM Get the directory where this script is located and navigate to project root
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%\..\.."
cd /d "%PROJECT_ROOT%"

echo ==========================================
echo     ServerAssistant Startup Script
echo          (Organized Structure)
echo ==========================================
echo.

REM Virtual environment setup
set "VENV_DIR=%PROJECT_ROOT%\venv"
set "VENV_ACTIVATE=%VENV_DIR%\Scripts\activate.bat"

REM Check if this is first-time setup
set "FIRST_TIME_FILE=%PROJECT_ROOT%\.first_time_setup_complete"

if not exist "%FIRST_TIME_FILE%" (
    echo [INFO] First-time setup detected!
    goto :first_time_setup
) else (
    echo [SUCCESS] Previous setup detected. Skipping installation.
    goto :launch
)

:first_time_setup
echo [INFO] Starting first-time setup...

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install Python 3.7+ first.
    pause
    exit /b 1
)
echo [SUCCESS] Python found

REM Check if virtual environment exists
if exist "%VENV_DIR%" (
    echo [SUCCESS] Virtual environment found
) else (
    echo [INFO] Creating virtual environment...
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [SUCCESS] Virtual environment created
)

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker not found. Please install Docker first.
    pause
    exit /b 1
)
echo [SUCCESS] Docker found

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose not found. Please install Docker Compose first.
    pause
    exit /b 1
)
echo [SUCCESS] Docker Compose found

REM Check if Docker daemon is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker daemon is not running. Please start Docker first.
    pause
    exit /b 1
)
echo [SUCCESS] Docker daemon is running

REM Install Python dependencies
echo [INFO] Installing Python dependencies...
call "%VENV_ACTIVATE%"
pip install --upgrade pip
if exist "requirements.txt" (
    pip install -r requirements.txt
    echo [SUCCESS] Python dependencies installed
) else (
    echo [WARNING] requirements.txt not found, skipping Python dependencies
)

REM Install additional dependencies for organized structure
pip install tabulate psutil colorama
echo [SUCCESS] Additional dependencies installed

REM Install system dependencies
if exist "scripts\setup\install_requirements.ps1" (
    echo [INFO] Installing system dependencies...
    powershell -ExecutionPolicy Bypass -File scripts\setup\install_requirements.ps1
    echo [SUCCESS] System dependencies installed
) else (
    echo [WARNING] install_requirements.ps1 not found, skipping system dependencies
)

REM Fix line endings and permissions
if exist "scripts\maintenance\fix_line_endings.ps1" (
    echo [INFO] Fixing line endings...
    powershell -ExecutionPolicy Bypass -File scripts\maintenance\fix_line_endings.ps1
    echo [SUCCESS] Line endings fixed
)

REM Setup persistent storage
if exist "example_services\gitlab\setup_persistent_storage.sh" (
    echo [INFO] Setting up GitLab persistent storage...
    REM Note: This would need to be adapted for Windows or use WSL
    echo [INFO] GitLab storage setup skipped (requires Linux/WSL)
)

if exist "example_services\mail-server\setup_persistent_storage.sh" (
    echo [INFO] Setting up mail server persistent storage...
    REM Note: This would need to be adapted for Windows or use WSL
    echo [INFO] Mail server storage setup skipped (requires Linux/WSL)
)

REM Setup Nginx
if exist "example_services\nginx\setup_nginx.sh" (
    echo [INFO] Setting up Nginx...
    REM Note: This would need to be adapted for Windows or use WSL
    echo [INFO] Nginx setup skipped (requires Linux/WSL)
)

REM Generate SSL certificates
if exist "example_services\nginx\generate_ssl.sh" (
    echo [INFO] Generating SSL certificates...
    REM Note: This would need to be adapted for Windows or use WSL
    echo [INFO] SSL generation skipped (requires Linux/WSL)
)

REM Mark first-time setup as complete
echo %date% %time%: First-time setup completed successfully > "%FIRST_TIME_FILE%"
echo [SUCCESS] First-time setup completed!

:launch
echo [INFO] Launching ServerAssistant (Organized Structure)...
echo.

REM Try organized structure first
if exist "src\main.py" (
    call "%VENV_ACTIVATE%"
    python src\main.py
) else if exist "serverassistant.py" (
    REM Fallback to refactored serverassistant.py
    call "%VENV_ACTIVATE%"
    python serverassistant.py
) else (
    echo [ERROR] No ServerAssistant found!
    pause
    exit /b 1
)

pause 