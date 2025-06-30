@echo off
REM Complete nginx setup script for Windows
REM This script sets up all necessary components for nginx to work properly

echo === Nginx Complete Setup Script ===
echo This script will set up all necessary components for nginx
echo.

REM Create necessary directories
echo [INFO] Creating necessary directories...
if not exist "logs" mkdir logs
if not exist "ssl" mkdir ssl
if not exist "config\conf.d" mkdir config\conf.d

REM Generate SSL certificates if they don't exist
if not exist "ssl\default.crt" (
    echo [INFO] Generating SSL certificates...
    if exist "generate_ssl.bat" (
        call generate_ssl.bat
    ) else (
        echo [ERROR] generate_ssl.bat not found. Please run generate_ssl.bat manually.
        pause
        exit /b 1
    )
) else (
    echo [INFO] SSL certificates already exist.
)

REM Check if Docker is available
echo [INFO] Checking Docker availability...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Docker found. Testing nginx configuration in container...
    
    REM Create a temporary container to test configuration
    docker run --rm -v "%cd%\config:/etc/nginx:ro" nginx:stable nginx -t >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] Nginx configuration is valid in Docker container.
    ) else (
        echo [ERROR] Nginx configuration is invalid in Docker container.
        pause
        exit /b 1
    )
) else (
    echo [WARNING] Docker not found. Skipping container configuration test.
)

REM Create a simple health check file
echo [INFO] Creating health check file...
echo Nginx is running > logs\health.txt
echo Last updated: %date% %time% >> logs\health.txt

REM Create startup script
echo [INFO] Creating startup script...
(
echo @echo off
echo echo Starting nginx with Docker Compose...
echo docker-compose down
echo docker-compose up -d --build
echo.
echo echo Nginx container started!
echo echo Check logs with: docker-compose logs -f nginx
echo echo Stop with: docker-compose down
echo pause
) > start_nginx.bat

REM Create a stop script
echo [INFO] Creating stop script...
(
echo @echo off
echo echo Stopping nginx...
echo docker-compose down
echo echo Nginx stopped!
echo pause
) > stop_nginx.bat

REM Create a restart script
echo [INFO] Creating restart script...
(
echo @echo off
echo echo Restarting nginx...
echo docker-compose down
echo docker-compose up -d --build
echo echo Nginx restarted!
echo pause
) > restart_nginx.bat

REM Display final information
echo.
echo === Setup Complete ===
echo.
echo Nginx setup is complete! Here's what was configured:
echo.
echo 📁 Directories created:
echo   - logs\ (for nginx logs^)
echo   - ssl\ (for SSL certificates^)
echo   - config\conf.d\ (for site configurations^)
echo.
echo 🔐 SSL Certificates:
echo   - Generated self-signed certificates for all domains
echo   - For production, replace with proper certificates
echo.
echo 📝 Scripts created:
echo   - start_nginx.bat (start nginx^)
echo   - stop_nginx.bat (stop nginx^)
echo   - restart_nginx.bat (restart nginx^)
echo.
echo 🚀 To start nginx:
echo   start_nginx.bat
echo.
echo 📋 To check status:
echo   docker-compose ps
echo.
echo 📊 To view logs:
echo   docker-compose logs -f nginx
echo.
echo ⚠️  Important notes:
echo   - SSL certificates are self-signed (development only^)
echo   - Add domains to C:\Windows\System32\drivers\etc\hosts for local testing
echo   - For production, use proper SSL certificates
echo.

echo [INFO] Setup completed successfully!
pause 