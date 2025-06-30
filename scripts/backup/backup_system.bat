@echo off
setlocal enabledelayedexpansion

echo === Comprehensive Backup System ===

REM Configuration
set BACKUP_ROOT=.\backups
set DATE=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set DATE=%DATE: =0%
set BACKUP_NAME=server_backup_%DATE%
set BACKUP_DIR=%BACKUP_ROOT%\%BACKUP_NAME%
set RETENTION_DAYS=30

REM Create backup directory
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo [INFO] Starting comprehensive backup: %BACKUP_NAME%

REM Stop services gracefully
echo [WARNING] Stopping services for consistent backup...
docker-compose -f example_services\gitlab\docker-compose.yml down 2>nul
docker-compose -f example_services\mail-server\docker-compose.yml down 2>nul

REM Wait for graceful shutdown
timeout /t 10 /nobreak >nul

REM Backup GitLab data
echo [INFO] Backing up GitLab data...
if exist "example_services\gitlab\gitlab" (
    mkdir "%BACKUP_DIR%\gitlab" 2>nul
    tar -czf "%BACKUP_DIR%\gitlab\data.tar.gz" -C "example_services\gitlab" gitlab
    echo [INFO] ✓ GitLab data backed up successfully
) else (
    echo [WARNING] GitLab data directory not found
)

REM Backup mail server data
echo [INFO] Backing up mail server data...
if exist "example_services\mail-server\mail" (
    mkdir "%BACKUP_DIR%\mail" 2>nul
    tar -czf "%BACKUP_DIR%\mail\data.tar.gz" -C "example_services\mail-server" mail
    echo [INFO] ✓ Mail server data backed up successfully
) else (
    echo [WARNING] Mail server data directory not found
)

REM Backup MySQL data
echo [INFO] Backing up MySQL data...
if exist "example_services\mysql\mysql" (
    mkdir "%BACKUP_DIR%\mysql" 2>nul
    tar -czf "%BACKUP_DIR%\mysql\data.tar.gz" -C "example_services\mysql" mysql
    echo [INFO] ✓ MySQL data backed up successfully
) else (
    echo [WARNING] MySQL data directory not found
)

REM Backup PostgreSQL data
echo [INFO] Backing up PostgreSQL data...
if exist "example_services\database\postgres" (
    mkdir "%BACKUP_DIR%\postgres" 2>nul
    tar -czf "%BACKUP_DIR%\postgres\data.tar.gz" -C "example_services\database" postgres
    echo [INFO] ✓ PostgreSQL data backed up successfully
) else (
    echo [WARNING] PostgreSQL data directory not found
)

REM Backup Redis data
echo [INFO] Backing up Redis data...
if exist "example_services\database\redis" (
    mkdir "%BACKUP_DIR%\redis" 2>nul
    tar -czf "%BACKUP_DIR%\redis\data.tar.gz" -C "example_services\database" redis
    echo [INFO] ✓ Redis data backed up successfully
) else (
    echo [WARNING] Redis data directory not found
)

REM Backup configurations
echo [INFO] Backing up configuration files...
mkdir "%BACKUP_DIR%\configs" 2>nul

if exist "config.json" copy "config.json" "%BACKUP_DIR%\configs\" >nul
if exist "test_config_ubuntu22.json" copy "test_config_ubuntu22.json" "%BACKUP_DIR%\configs\" >nul

if exist "example_services\nginx\ssl" (
    mkdir "%BACKUP_DIR%\configs\ssl" 2>nul
    xcopy "example_services\nginx\ssl" "%BACKUP_DIR%\configs\ssl\" /E /I /Y >nul 2>nul
)

echo [INFO] ✓ Configuration files backed up

REM Create system information
echo [INFO] Creating system information...
mkdir "%BACKUP_DIR%\system_info" 2>nul

systeminfo > "%BACKUP_DIR%\system_info\system.txt"
docker --version >> "%BACKUP_DIR%\system_info\system.txt" 2>nul
docker-compose --version >> "%BACKUP_DIR%\system_info\system.txt" 2>nul

docker info > "%BACKUP_DIR%\system_info\docker_info.txt" 2>nul
docker ps -a > "%BACKUP_DIR%\system_info\containers.txt" 2>nul
docker volume ls > "%BACKUP_DIR%\system_info\volumes.txt" 2>nul
docker network ls > "%BACKUP_DIR%\system_info\networks.txt" 2>nul

echo [INFO] ✓ System information collected

REM Restart services
echo [INFO] Restarting services...
docker-compose -f example_services\gitlab\docker-compose.yml up -d 2>nul
docker-compose -f example_services\mail-server\docker-compose.yml up -d 2>nul

REM Create final archive
echo [INFO] Creating final backup archive...
cd "%BACKUP_ROOT%"
tar -czf "%BACKUP_NAME%.tar.gz" "%BACKUP_NAME%"

REM Calculate final size
for %%A in ("%BACKUP_NAME%.tar.gz") do set FINAL_SIZE=%%~zA

echo [INFO] ✓ Backup completed successfully!
echo [INFO] Backup location: %BACKUP_ROOT%\%BACKUP_NAME%.tar.gz
echo [INFO] Backup size: %FINAL_SIZE% bytes

REM Cleanup old backups
echo [INFO] Cleaning up old backups...
forfiles /p "%BACKUP_ROOT%" /s /m server_backup_*.tar.gz /d -%RETENTION_DAYS% /c "cmd /c del @path" 2>nul
forfiles /p "%BACKUP_ROOT%" /s /m server_backup_* /d -%RETENTION_DAYS% /c "cmd /c rmdir /s /q @path" 2>nul

echo [INFO] ✓ Old backups cleaned up
echo.
echo [SUCCESS] Backup process completed successfully!
pause 