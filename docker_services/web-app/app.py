#!/usr/bin/env python3
"""
Example Flask web application for Docker Service Manager
Updated for MySQL database connection and comprehensive health checks
"""

from flask import Flask, jsonify, request
import os
import time
import requests
import json
from datetime import datetime
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'database': os.getenv('DB_NAME', 'myapp'),
    'user': os.getenv('DB_USER', 'myapp_user'),
    'password': os.getenv('DB_PASSWORD', 'myapp_password'),
    'charset': 'utf8mb4',
    'autocommit': True
}

def get_db_connection():
    """Get database connection."""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Database connection error: {e}")
        return None

def check_database_health():
    """Check database health."""
    try:
        connection = get_db_connection()
        if connection and connection.is_connected():
            cursor = connection.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            connection.close()
            return True, "Database connection successful"
        else:
            return False, "Database connection failed"
    except Error as e:
        return False, f"Database error: {e}"

@app.route('/')
def index():
    """Main page."""
    return jsonify({
        'message': 'Hello from Docker Service Manager!',
        'timestamp': datetime.now().isoformat(),
        'service': 'web-app',
        'version': '1.0.0',
        'environment': os.getenv('NODE_ENV', 'development'),
        'host': os.getenv('HOSTNAME', 'unknown'),
        'uptime': time.time(),
        'database_host': os.getenv('DB_HOST', 'localhost'),
        'database_name': os.getenv('DB_NAME', 'myapp')
    })

@app.route('/health')
def health():
    """Health check endpoint."""
    # Check database health
    db_healthy, db_message = check_database_health()
    
    # Check other dependencies
    checks = {
        'database': {
            'status': 'healthy' if db_healthy else 'unhealthy',
            'message': db_message
        },
        'web_server': {
            'status': 'healthy',
            'message': 'Flask server is running'
        }
    }
    
    # Overall health status
    overall_healthy = all(check['status'] == 'healthy' for check in checks.values())
    
    return jsonify({
        'status': 'healthy' if overall_healthy else 'unhealthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'web-app',
        'checks': checks,
        'uptime': time.time()
    })

@app.route('/info')
def info():
    """Service information."""
    return jsonify({
        'service': 'web-app',
        'version': '1.0.0',
        'environment': os.getenv('NODE_ENV', 'development'),
        'host': os.getenv('HOSTNAME', 'unknown'),
        'uptime': time.time(),
        'database': {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': os.getenv('DB_PORT', 3306),
            'name': os.getenv('DB_NAME', 'myapp'),
            'user': os.getenv('DB_USER', 'myapp_user')
        }
    })

@app.route('/database/test')
def test_database():
    """Test database connection and basic operations."""
    try:
        connection = get_db_connection()
        if not connection or not connection.is_connected():
            return jsonify({
                'status': 'error',
                'message': 'Database connection failed'
            }), 500
        
        cursor = connection.cursor()
        
        # Test basic query
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM products")
        product_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM orders")
        order_count = cursor.fetchone()[0]
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'status': 'success',
            'message': 'Database test successful',
            'data': {
                'users_count': user_count,
                'products_count': product_count,
                'orders_count': order_count
            }
        })
        
    except Error as e:
        return jsonify({
            'status': 'error',
            'message': f'Database test failed: {e}'
        }), 500

@app.route('/database/users')
def get_users():
    """Get users from database."""
    try:
        connection = get_db_connection()
        if not connection or not connection.is_connected():
            return jsonify({
                'status': 'error',
                'message': 'Database connection failed'
            }), 500
        
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, username, email, created_at FROM users LIMIT 10")
        users = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'status': 'success',
            'data': users
        })
        
    except Error as e:
        return jsonify({
            'status': 'error',
            'message': f'Failed to get users: {e}'
        }), 500

@app.route('/database/products')
def get_products():
    """Get products from database."""
    try:
        connection = get_db_connection()
        if not connection or not connection.is_connected():
            return jsonify({
                'status': 'error',
                'message': 'Database connection failed'
            }), 500
        
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT id, name, description, price, category FROM products LIMIT 10")
        products = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'status': 'success',
            'data': products
        })
        
    except Error as e:
        return jsonify({
            'status': 'error',
            'message': f'Failed to get products: {e}'
        }), 500

@app.route('/system/status')
def system_status():
    """System status information."""
    import psutil
    
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'system': {
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_percent': psutil.disk_usage('/').percent
        },
        'environment': {
            'python_version': os.sys.version,
            'flask_version': Flask.__version__,
            'hostname': os.getenv('HOSTNAME', 'unknown'),
            'environment': os.getenv('NODE_ENV', 'development')
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 