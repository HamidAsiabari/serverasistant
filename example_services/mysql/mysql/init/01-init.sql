-- MySQL initialization script
-- This script runs when the MySQL container starts for the first time

-- Create additional databases if needed
CREATE DATABASE IF NOT EXISTS testdb;
CREATE DATABASE IF NOT EXISTS development;

-- Use the main application database
USE myapp;

-- Create sample tables
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
);

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_category (category),
    INDEX idx_price (price)
);

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Insert sample data
INSERT INTO users (username, email, password_hash) VALUES 
    ('admin', 'admin@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
    ('john_doe', 'john@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'),
    ('jane_smith', 'jane@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

INSERT INTO products (name, description, price, stock_quantity, category) VALUES 
    ('Laptop', 'High-performance laptop for development', 1299.99, 10, 'Electronics'),
    ('Mouse', 'Wireless optical mouse', 29.99, 50, 'Electronics'),
    ('Keyboard', 'Mechanical gaming keyboard', 89.99, 25, 'Electronics'),
    ('Monitor', '27-inch 4K monitor', 399.99, 15, 'Electronics'),
    ('Headphones', 'Noise-cancelling headphones', 199.99, 30, 'Electronics')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

-- Create a view for order summary
CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.id,
    u.username,
    o.total_amount,
    o.status,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.id;

-- Create stored procedure for getting user orders
DELIMITER //
CREATE PROCEDURE GetUserOrders(IN user_id_param INT)
BEGIN
    SELECT 
        o.id,
        o.total_amount,
        o.status,
        o.created_at
    FROM orders o
    WHERE o.user_id = user_id_param
    ORDER BY o.created_at DESC;
END //
DELIMITER ;

-- Grant permissions
GRANT ALL PRIVILEGES ON myapp.* TO 'myapp_user'@'%';
GRANT SELECT ON myapp.* TO 'myapp_user'@'%';
FLUSH PRIVILEGES; 