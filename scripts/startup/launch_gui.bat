@echo off
REM Launch script for ServerAssistant GUI (Windows)

echo 🚀 Starting ServerAssistant GUI...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..

echo 📁 Project root: %PROJECT_ROOT%

REM Change to project root
cd /d "%PROJECT_ROOT%"

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if textual is installed
python -c "import textual" >nul 2>&1
if errorlevel 1 (
    echo 📦 Installing textual...
    pip install textual>=0.52.0
)

REM Check if config file exists
if not exist "config.json" (
    echo ❌ config.json not found in project root
    pause
    exit /b 1
)

REM Launch the GUI
echo 🎯 Launching GUI...
python gui_main.py

echo �� GUI closed
pause 