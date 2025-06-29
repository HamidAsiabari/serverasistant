# Mail Server - Complete Email Solution

This directory contains a complete mail server setup with Postfix (SMTP), Dovecot (IMAP/POP3), SpamAssassin (spam filtering), and Roundcube (webmail interface).

## 🚀 **Services Included**

- **📧 Postfix** - SMTP server (ports 25, 587)
- **📬 Dovecot** - IMAP/POP3 server (ports 110, 143, 993, 995)
- **🛡️ SpamAssassin** - Spam filtering
- **🌐 Roundcube** - Webmail interface (port 8083)
- **🗄️ MySQL** - Database for Roundcube

## 📋 **Quick Start**

### 1. Start Mail Server
```bash
# Using Docker Service Manager
./activate_env.sh python3 main.py start mail-server --config test_config_ubuntu22.json

# Or manually
cd example_services/mail-server
docker-compose up -d
```

### 2. Access Services
- **Webmail**: http://your-server-ip:8083
- **SMTP**: your-server-ip:25, 587
- **IMAP**: your-server-ip:143, 993
- **POP3**: your-server-ip:110, 995

### 3. Default Users
- **admin** / admin_password
- **user1** / user1_password
- **user2** / user2_password

## ⚙️ **Configuration**

### Postfix Configuration
- **File**: `postfix/config/main.cf`
- **Features**: SMTP, SMTP submission, TLS, authentication
- **Anti-spam**: RBL checks, content filtering

### Dovecot Configuration
- **File**: `dovecot/config/dovecot.conf`
- **Features**: IMAP, POP3, LMTP, SSL/TLS
- **Authentication**: PAM integration

### SpamAssassin Configuration
- **File**: `spamassassin/config/local.cf`
- **Features**: Bayesian filtering, RBL checks, auto-learning
- **Threshold**: 5.0 (adjustable)

### Roundcube Configuration
- **Database**: MySQL with auto-initialization
- **Features**: Modern webmail interface
- **Integration**: Full IMAP/SMTP support

## 🔧 **Setup Instructions**

### 1. Domain Configuration
Update the domain in configuration files:
```bash
# Replace 'example.com' with your actual domain
sed -i 's/example.com/yourdomain.com/g' postfix/config/main.cf
sed -i 's/example.com/yourdomain.com/g' dovecot/config/dovecot.conf
```

### 2. SSL Certificates
For production, replace self-signed certificates:
```bash
# Copy your SSL certificates
cp your-cert.pem postfix/config/
cp your-key.pem postfix/config/
cp your-cert.pem dovecot/config/
cp your-key.pem dovecot/config/
```

### 3. User Management
Add mail users:
```bash
# Add system users (for Dovecot authentication)
sudo useradd -m -s /bin/bash admin
sudo useradd -m -s /bin/bash user1
sudo useradd -m -s /bin/bash user2

# Set passwords
sudo passwd admin
sudo passwd user1
sudo passwd user2
```

## 📊 **Port Configuration**

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| Postfix | 25 | SMTP | Mail transfer |
| Postfix | 587 | SMTP | Mail submission |
| Dovecot | 110 | POP3 | Mail retrieval |
| Dovecot | 143 | IMAP | Mail retrieval |
| Dovecot | 993 | IMAPS | Secure IMAP |
| Dovecot | 995 | POP3S | Secure POP3 |
| Roundcube | 8083 | HTTP | Webmail interface |

## 🔒 **Security Features**

### Authentication
- SASL authentication with Dovecot
- TLS/SSL encryption
- Strong password policies

### Anti-Spam
- SpamAssassin integration
- RBL (Real-time Blackhole List) checks
- Bayesian filtering
- Auto-learning capabilities

### Network Security
- Firewall-friendly configuration
- Trusted network definitions
- Rate limiting

## 📧 **Email Client Configuration**

### Thunderbird/Outlook Settings
```
Incoming Mail (IMAP):
- Server: your-server-ip
- Port: 143 (or 993 for SSL)
- Username: your-username
- Password: your-password

Outgoing Mail (SMTP):
- Server: your-server-ip
- Port: 587
- Username: your-username
- Password: your-password
- Security: STARTTLS
```

### Mobile Configuration
```
IMAP Settings:
- Host: your-server-ip
- Port: 993
- Security: SSL/TLS
- Username: your-username

SMTP Settings:
- Host: your-server-ip
- Port: 587
- Security: STARTTLS
- Username: your-username
```

## 🛠️ **Troubleshooting**

### Check Service Status
```bash
# Check all containers
docker ps

# Check specific service logs
docker logs postfix
docker logs dovecot
docker logs spamassassin
docker logs roundcube
docker logs mail-db
```

### Common Issues

#### 1. Mail Not Sending
```bash
# Check Postfix logs
docker logs postfix | grep -i error

# Check network connectivity
telnet your-server-ip 25
telnet your-server-ip 587
```

#### 2. Mail Not Receiving
```bash
# Check Dovecot logs
docker logs dovecot | grep -i error

# Test IMAP connection
telnet your-server-ip 143
```

#### 3. Webmail Not Accessible
```bash
# Check Roundcube logs
docker logs roundcube | grep -i error

# Check database connection
docker exec mail-db mysql -u roundcube -p roundcube
```

#### 4. Spam Filtering Issues
```bash
# Check SpamAssassin logs
docker logs spamassassin | grep -i error

# Test spam filtering
echo "Subject: Test" | docker exec -i postfix sendmail admin@example.com
```

### Performance Tuning

#### Memory Optimization
```bash
# Adjust Postfix settings in main.cf
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 30
smtpd_client_recipient_rate_limit = 30
```

#### SpamAssassin Tuning
```bash
# Adjust threshold in local.cf
required_score 5.0  # Increase for stricter filtering
```

## 📈 **Monitoring**

### Log Monitoring
```bash
# Monitor all mail logs
tail -f postfix/logs/mail.log
tail -f dovecot/logs/dovecot.log
tail -f spamassassin/logs/spamd.log
```

### Health Checks
```bash
# Check service health
docker exec postfix postfix check
docker exec dovecot doveconf -n
docker exec spamassassin spamassassin --lint
```

## 🔄 **Backup and Restore**

### Backup
```bash
# Backup mail data
docker run --rm -v mail-server_mail_data:/data -v $(pwd):/backup alpine tar czf /backup/mail-backup.tar.gz -C /data .

# Backup database
docker exec mail-db mysqldump -u root -p roundcube > roundcube-backup.sql
```

### Restore
```bash
# Restore mail data
docker run --rm -v mail-server_mail_data:/data -v $(pwd):/backup alpine tar xzf /backup/mail-backup.tar.gz -C /data

# Restore database
docker exec -i mail-db mysql -u root -p roundcube < roundcube-backup.sql
```

## 📚 **Resources**

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Dovecot Documentation](https://doc.dovecot.org/)
- [SpamAssassin Documentation](https://spamassassin.apache.org/old/tests_3_3_x.html)
- [Roundcube Documentation](https://github.com/roundcube/roundcubemail/wiki)

## 🆘 **Support**

For issues:
1. Check service logs
2. Verify network connectivity
3. Test with telnet
4. Review configuration files
5. Check DNS settings 