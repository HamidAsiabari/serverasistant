@echo off
REM Wrapper script for scripts/startup/setup.bat
cd /d "%~dp0"
call "scripts\startup\setup.bat" %* 