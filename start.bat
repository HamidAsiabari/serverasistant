@echo off
REM Simple startup script for ServerAssistant (Windows)
REM This script just launches the application without environment setup

cd /d "%~dp0"

REM Check if virtual environment exists and activate it
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
    echo Virtual environment activated
)

REM Launch ServerAssistant
if exist "serverassistant.py" (
    python serverassistant.py %*
) else if exist "src\main.py" (
    python src\main.py %*
) else (
    echo ERROR: No ServerAssistant found!
    exit /b 1
) 