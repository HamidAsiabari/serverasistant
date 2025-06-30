@echo off
echo 🚀 Setting up Nginx Reverse Proxy Service...

REM Create necessary directories
echo 📁 Creating directories...
if not exist "logs" mkdir logs
if not exist "ssl" mkdir ssl
if not exist "conf.d" mkdir conf.d

REM Check if SSL certificates exist
if not exist "ssl\app.soject.com.crt" (
    echo 🔐 SSL certificates not found. Generating self-signed certificates...
    call generate_ssl.bat
) else (
    echo ✅ SSL certificates found
)

REM Test nginx configuration
echo 🧪 Testing nginx configuration...
docker-compose config >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Docker Compose configuration is valid
) else (
    echo ❌ Docker Compose configuration is invalid
    pause
    exit /b 1
)

echo.
echo 🎉 Nginx service setup complete!
echo.
echo 📋 Next steps:
echo    1. Add app.soject.com to your hosts file or DNS
echo    2. Start the service: docker-compose up -d
echo    3. Test the service: curl http://app.soject.com/health
echo.
echo 📚 For more information, see README.md
pause 