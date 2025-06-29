-- Roundcube database initialization
-- This script sets up the Roundcube database and user

-- Create Roundcube database if it doesn't exist
CREATE DATABASE IF NOT EXISTS roundcube CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create Roundcube user if it doesn't exist
CREATE USER IF NOT EXISTS 'roundcube'@'%' IDENTIFIED BY 'roundcube_password';

-- Grant privileges to Roundcube user
GRANT ALL PRIVILEGES ON roundcube.* TO 'roundcube'@'%';

-- Create additional mail users for testing
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin_password';
CREATE USER IF NOT EXISTS 'user1'@'%' IDENTIFIED BY 'user1_password';
CREATE USER IF NOT EXISTS 'user2'@'%' IDENTIFIED BY 'user2_password';

-- Grant mail privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON roundcube.* TO 'admin'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON roundcube.* TO 'user1'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON roundcube.* TO 'user2'@'%';

-- Flush privileges
FLUSH PRIVILEGES; 