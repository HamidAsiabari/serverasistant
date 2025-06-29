@echo off
setlocal enabledelayedexpansion

echo === Nginx Reverse Proxy Setup ===

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker first.
    exit /b 1
)

REM Check if docker-compose is available
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] docker-compose is not installed. Please install it first.
    exit /b 1
)

REM Create necessary directories
echo [INFO] Creating directories...
if not exist "ssl" mkdir ssl
if not exist "logs" mkdir logs
if not exist "config\conf.d" mkdir config\conf.d

REM Generate SSL certificates
echo [INFO] Generating SSL certificates...
if exist "generate_ssl.sh" (
    echo [WARNING] SSL generation script found but this is Windows. Please run generate_ssl.sh on Linux or manually create certificates.
) else (
    echo [WARNING] generate_ssl.sh not found. Please create SSL certificates manually.
    echo.
    echo To create certificates manually:
    echo 1. Install OpenSSL for Windows
    echo 2. Run commands like:
    echo    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ssl\app.soject.com.key -out ssl\app.soject.com.crt -subj "/C=US/ST=State/L=City/O=Organization/CN=app.soject.com"
    echo.
)

REM Create Docker networks if they don't exist
echo [INFO] Creating Docker networks...
for %%n in (web_network mail_network gitlab_network portainer_network) do (
    docker network ls | findstr "%%n" >nul 2>&1
    if errorlevel 1 (
        echo [INFO] Creating network: %%n
        docker network create %%n
    ) else (
        echo [INFO] Network %%n already exists
    )
)

REM Test Nginx configuration
echo [INFO] Testing Nginx configuration...
docker-compose config >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker Compose configuration is invalid
    exit /b 1
) else (
    echo [INFO] Docker Compose configuration is valid
)

REM Create hosts file entry helper
echo [INFO] Creating hosts file helper...
(
echo @echo off
echo REM Helper script to add domains to hosts file
echo.
echo set HOSTS_FILE=C:\Windows\System32\drivers\etc\hosts
echo set DOMAINS=app.soject.com admin.soject.com docker.soject.com gitlab.soject.com mail.soject.com
echo.
echo echo Adding domains to %%HOSTS_FILE%% ^(requires admin privileges^):
echo.
echo for %%d in ^(%%DOMAINS%%^) do ^(
echo     findstr "%%d" "%%HOSTS_FILE%%" ^>nul 2^>^&1
echo     if errorlevel 1 ^(
echo         echo 127.0.0.1 %%d ^>^> "%%HOSTS_FILE%%"
echo         echo Added: %%d
echo     ^) else ^(
echo         echo Already exists: %%d
echo     ^)
echo ^)
echo.
echo echo Hosts file updated successfully!
) > add_to_hosts.bat

REM Create startup script
echo [INFO] Creating startup script...
(
echo @echo off
echo REM Start Nginx reverse proxy
echo.
echo echo Starting Nginx reverse proxy...
echo docker-compose up -d
echo.
echo echo Nginx is starting up...
echo echo You can access your services at:
echo echo   - Web App: https://app.soject.com
echo echo   - Database Admin: https://admin.soject.com
echo echo   - Docker Management: https://docker.soject.com
echo echo   - GitLab: https://gitlab.soject.com
echo echo   - Webmail: https://mail.soject.com
echo echo.
echo echo Note: Make sure to add these domains to your hosts file first:
echo echo   Run add_to_hosts.bat as Administrator
echo echo.
echo echo For production: Configure these domains in Cloudflare to point to your server IP
) > start_nginx.bat

REM Create stop script
echo [INFO] Creating stop script...
(
echo @echo off
echo REM Stop Nginx reverse proxy
echo.
echo echo Stopping Nginx reverse proxy...
echo docker-compose down
echo.
echo echo Nginx stopped successfully!
) > stop_nginx.bat

REM Create logs script
echo [INFO] Creating logs script...
(
echo @echo off
echo REM View Nginx logs
echo.
echo echo Nginx container logs:
echo docker-compose logs -f nginx
) > view_logs.bat

echo [INFO] Nginx setup completed successfully!
echo.
echo Next steps:
echo 1. Add domains to your hosts file: Run add_to_hosts.bat as Administrator
echo 2. Start Nginx: start_nginx.bat
echo 3. View logs: view_logs.bat
echo 4. Stop Nginx: stop_nginx.bat
echo.
echo For production deployment:
echo - Configure these domains in Cloudflare:
echo   * app.soject.com -^> YOUR_SERVER_IP
echo   * admin.soject.com -^> YOUR_SERVER_IP
echo   * docker.soject.com -^> YOUR_SERVER_IP
echo   * gitlab.soject.com -^> YOUR_SERVER_IP
echo   * mail.soject.com -^> YOUR_SERVER_IP
echo - Replace self-signed certificates with trusted certificates
echo - Set up proper firewall rules
echo.
echo [WARNING] Remember: These are self-signed certificates for development/testing only!

pause 