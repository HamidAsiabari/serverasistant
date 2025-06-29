# Docker Service Manager - Windows Installation Script
# Run this script as Administrator

param(
    [switch]$SkipDockerInstall,
    [switch]$SkipPythonInstall
)

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Docker Service Manager - Windows Installation" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Function to write colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Install Chocolatey if not present
Write-Status "Checking for Chocolatey..."
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Status "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Success "Chocolatey installed successfully"
} else {
    Write-Warning "Chocolatey is already installed"
}

# Install Python if not present
if (-not $SkipPythonInstall) {
    Write-Status "Installing Python..."
    if (!(Get-Command python -ErrorAction SilentlyContinue)) {
        choco install python -y
        refreshenv
        Write-Success "Python installed successfully"
    } else {
        Write-Warning "Python is already installed"
    }
} else {
    Write-Warning "Skipping Python installation"
}

# Install Git if not present
Write-Status "Installing Git..."
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    choco install git -y
    refreshenv
    Write-Success "Git installed successfully"
} else {
    Write-Warning "Git is already installed"
}

# Install Docker Desktop if not present
if (-not $SkipDockerInstall) {
    Write-Status "Installing Docker Desktop..."
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        choco install docker-desktop -y
        Write-Success "Docker Desktop installed successfully"
        Write-Warning "Please restart your computer and start Docker Desktop manually"
    } else {
        Write-Warning "Docker is already installed"
    }
} else {
    Write-Warning "Skipping Docker installation"
}

# Create virtual environment
Write-Status "Creating Python virtual environment..."
if (Test-Path "venv") {
    Write-Warning "Virtual environment already exists, removing..."
    Remove-Item -Recurse -Force "venv"
}

python -m venv venv
.\venv\Scripts\Activate.ps1

# Upgrade pip
Write-Status "Upgrading pip..."
python -m pip install --upgrade pip

# Install Python dependencies
Write-Status "Installing Python dependencies..."
pip install -r requirements.txt

# Create necessary directories
Write-Status "Creating necessary directories..."
if (!(Test-Path "logs")) { New-Item -ItemType Directory -Path "logs" }
if (!(Test-Path "reports")) { New-Item -ItemType Directory -Path "reports" }
if (!(Test-Path "services")) { New-Item -ItemType Directory -Path "services" }

# Create Windows batch files for easy startup
Write-Status "Creating Windows batch files..."

# Main startup script
@"
@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)

REM Start the manager
python main.py %*
pause
"@ | Out-File -FilePath "start.bat" -Encoding ASCII

# Monitor startup script
@"
@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)

REM Start the monitor
python monitor.py %*
pause
"@ | Out-File -FilePath "start_monitor.bat" -Encoding ASCII

# Test script
@"
@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat
python test_installation.py
pause
"@ | Out-File -FilePath "test_install.bat" -Encoding ASCII

Write-Success "Windows batch files created"

# Create Windows Task Scheduler entry (optional)
Write-Status "Creating Windows Task Scheduler entry..."
$TaskName = "DockerServiceManager"
$TaskDescription = "Docker Service Manager Monitor"
$ScriptPath = (Get-Location).Path
$PythonPath = "$ScriptPath\venv\Scripts\python.exe"
$MonitorScript = "$ScriptPath\monitor.py"

# Remove existing task if it exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# Create new task
$Action = New-ScheduledTaskAction -Execute $PythonPath -Argument $MonitorScript -WorkingDirectory $ScriptPath
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description $TaskDescription

Write-Success "Windows Task Scheduler entry created"

# Test installations
Write-Status "Testing installations..."

# Test Python
if (Get-Command python -ErrorAction SilentlyContinue) {
    Write-Success "Python is working"
} else {
    Write-Error "Python is not working"
    exit 1
}

# Test Docker (if installed)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker --version | Out-Null
        Write-Success "Docker is working"
    } catch {
        Write-Warning "Docker is installed but may not be running"
    }
} else {
    Write-Warning "Docker is not installed or not in PATH"
}

# Test Docker Compose
if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    try {
        docker-compose --version | Out-Null
        Write-Success "Docker Compose is working"
    } catch {
        Write-Warning "Docker Compose is installed but may not be working"
    }
} else {
    Write-Warning "Docker Compose is not installed or not in PATH"
}

Write-Success "Installation completed successfully!"
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "1. If Docker Desktop was installed, restart your computer"
Write-Host "2. Start Docker Desktop manually"
Write-Host "3. Test the installation:"
Write-Host "   .\test_install.bat"
Write-Host ""
Write-Host "4. Start using the manager:"
Write-Host "   .\start.bat status"
Write-Host "   .\start.bat start-all"
Write-Host "   .\start_monitor.bat"
Write-Host ""
Write-Host "5. Optional: The monitor will start automatically on boot"
Write-Host "   To disable: Task Scheduler > DockerServiceManager > Disable"
Write-Host ""
Write-Host "6. Check logs:"
Write-Host "   Get-Content logs\docker_manager_$(Get-Date -Format 'yyyyMMdd').log -Wait"
Write-Host "==========================================" -ForegroundColor Cyan 