@echo off
echo 🔐 Generating self-signed SSL certificate for app.soject.com...

REM Create ssl directory if it doesn't exist
if not exist "ssl" mkdir ssl

REM Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 ^
    -keyout ssl\app.soject.com.key ^
    -out ssl\app.soject.com.crt ^
    -subj "/C=US/ST=State/L=City/O=Organization/CN=app.soject.com"

if %ERRORLEVEL% EQU 0 (
    echo ✅ SSL certificate generated successfully!
    echo 📁 Certificate files:
    echo    - ssl\app.soject.com.crt
    echo    - ssl\app.soject.com.key
    echo.
    echo ⚠️  Note: This is a self-signed certificate for development only.
    echo    For production, use Let's Encrypt or a commercial certificate.
    echo.
    echo 🔍 To verify the certificate:
    echo    openssl x509 -in ssl\app.soject.com.crt -text -noout
) else (
    echo ❌ Failed to generate SSL certificate
    echo Please ensure OpenSSL is installed and available in your PATH
)

pause 