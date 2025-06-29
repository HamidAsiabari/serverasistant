# Transfer and Run on Ubuntu Server

This guide will help you transfer the Docker Service Manager project to your Ubuntu server and run it successfully.

## Step 1: Prepare Files on Windows

The line endings have already been fixed. If you need to fix them again, run:

```powershell
.\fix_line_endings.bat
```

## Step 2: Transfer Files to Ubuntu Server

### Option A: Using SCP (Secure Copy)
```bash
# From your Windows machine, transfer the entire project
scp -r C:\Users\Administrator\Desktop\serverimp admin1@your-server-ip:~/

# Or transfer specific files
scp -r C:\Users\Administrator\Desktop\serverimp\* admin1@your-server-ip:~/serverimp/
```

### Option B: Using SFTP
```bash
# Connect to your server
sftp admin1@your-server-ip

# Upload the project
put -r C:\Users\Administrator\Desktop\serverimp
```

### Option C: Using Git (Recommended)
```bash
# On your Windows machine, initialize git and push to a repository
git init
git add .
git commit -m "Initial commit"
git remote add origin your-repo-url
git push -u origin main

# On Ubuntu server, clone the repository
git clone your-repo-url
cd serverimp
```

## Step 3: Prepare Files on Ubuntu Server

After transferring, run the preparation script:

```bash
# Make the script executable
chmod +x prepare_for_linux.sh

# Run the preparation script
./prepare_for_linux.sh
```

## Step 4: Run the Installation Test

```bash
# Run the comprehensive test
./test_ubuntu22.sh

# Or run the quick test
./quick_test_ubuntu22.sh

# Or run the Python test
python3 test_installation.py
```

## Step 5: Start Services

```bash
# Start all services
python3 main.py start-all --config test_config_ubuntu22.json

# Check status
python3 main.py status --config test_config_ubuntu22.json

# Start monitoring
python3 monitor.py --config test_config_ubuntu22.json
```

## Troubleshooting

### Permission Issues
If you encounter permission issues:

```bash
# Fix permissions
./fix_permissions.sh

# Or manually
sudo chown -R $USER:$USER .
chmod +x *.sh *.py
```

### Line Ending Issues
If you still have line ending issues:

```bash
# Fix line endings
dos2unix *.py *.sh
# Or
sed -i 's/\r$//' *.py *.sh
```

### Docker Issues
If Docker is not working:

```bash
# Check Docker status
sudo systemctl status docker

# Start Docker if not running
sudo systemctl start docker

# Add user to docker group (if not already done)
sudo usermod -aG docker $USER

# Log out and log back in
exit
# Then reconnect to your server
```

### Python Virtual Environment Issues
If the virtual environment has issues:

```bash
# Remove existing venv
rm -rf venv

# Create new venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Expected Output

After running the test script, you should see:

```
==========================================
Ubuntu 22.04 Docker Service Manager Test
==========================================
[INFO] Checking system requirements...
[SUCCESS] Ubuntu 22.04 detected
[SUCCESS] Memory: 8GB
[SUCCESS] Disk space: 50GB
[SUCCESS] Internet connectivity: OK

[INFO] Fixing permissions...
[SUCCESS] Permissions fixed

[INFO] Installing system dependencies...
[SUCCESS] System dependencies installed

[INFO] Installing Docker...
[SUCCESS] Docker installed successfully

[INFO] Installing Docker Compose...
[SUCCESS] Docker Compose installed successfully

[INFO] Setting up Python environment...
[SUCCESS] Python environment setup complete

[INFO] Testing Docker installation...
[SUCCESS] Docker is working

[INFO] Testing configuration...
[SUCCESS] Configuration file is valid JSON
[SUCCESS] Docker Manager test passed

[INFO] Testing services...
[SUCCESS] MySQL database started
[SUCCESS] PostgreSQL/Redis started
[SUCCESS] Web application started
[SUCCESS] Web application health check passed

==========================================
Test Summary
==========================================
✅ System Requirements: Checked
✅ Permissions: Fixed
✅ System Dependencies: Installed
✅ Docker: Installed and tested
✅ Docker Compose: Installed and tested
✅ Python Environment: Setup complete
✅ Configuration: Validated
✅ Services: Tested

[SUCCESS] Ubuntu 22.04 test completed successfully!
```

## Service URLs

After successful installation, you can access:

- **Web Application**: http://your-server-ip:8080
- **phpMyAdmin**: http://your-server-ip:8082
- **PostgreSQL**: your-server-ip:5432
- **Redis**: your-server-ip:6379

## Next Steps

1. **Log out and log back in** for Docker group changes to take effect
2. **Start all services**: `python3 main.py start-all --config test_config_ubuntu22.json`
3. **Monitor services**: `python3 monitor.py --config test_config_ubuntu22.json`
4. **Check logs**: `tail -f logs/docker_manager_$(date +%Y%m%d).log`

## Support

If you encounter any issues:

1. Check the log files in the `logs/` directory
2. Run `docker ps` to see running containers
3. Run `docker logs <container-name>` to see container logs
4. Check the troubleshooting section above 