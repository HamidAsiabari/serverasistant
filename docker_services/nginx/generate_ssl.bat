@echo off
REM Generate SSL certificates for nginx domains
REM This script creates self-signed certificates for development purposes

set SSL_DIR=.\ssl
set DOMAINS=default app.soject.com gitlab.soject.com docker.soject.com admin.soject.com mail.soject.com

REM Create SSL directory if it doesn't exist
if not exist "%SSL_DIR%" mkdir "%SSL_DIR%"

REM Generate certificates for each domain
for %%d in (%DOMAINS%) do (
    echo Generating SSL certificate for %%d...
    
    if "%%d"=="default" (
        REM Default certificate for unknown domains
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "%SSL_DIR%\default.key" -out "%SSL_DIR%\default.crt" -subj "/C=US/ST=State/L=City/O=Organization/CN=default"
    ) else (
        REM Domain-specific certificates
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "%SSL_DIR%\%%d.key" -out "%SSL_DIR%\%%d.crt" -subj "/C=US/ST=State/L=City/O=Organization/CN=%%d"
    )
    
    echo Certificate for %%d created successfully
)

echo All SSL certificates generated successfully!
echo Note: These are self-signed certificates for development use only.
echo For production, use proper SSL certificates from a trusted CA.
pause 