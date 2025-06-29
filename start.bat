@echo off
REM Wrapper script for scripts/startup/start.bat
cd /d "%~dp0"
call "scripts\startup\start.bat" %* 