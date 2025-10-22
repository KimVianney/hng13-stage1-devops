#!/usr/bin/env python3
"""
Simple Flask Web Application for HNG13 DevOps Stage 1
A production-ready sample application for automated deployment
"""

from flask import Flask, jsonify, render_template_string
from datetime import datetime
import os
import socket

app = Flask(__name__)

# HTML template for the home page
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HNG13 DevOps - Stage 1</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 40px;
            max-width: 600px;
            width: 100%;
            animation: slideIn 0.5s ease-out;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
            text-align: center;
        }
        
        .subtitle {
            color: #667eea;
            text-align: center;
            font-size: 1.2em;
            margin-bottom: 30px;
            font-weight: 500;
        }
        
        .status {
            background: #f0f4ff;
            border-left: 4px solid #667eea;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .status-item:last-child {
            border-bottom: none;
        }
        
        .label {
            font-weight: 600;
            color: #555;
        }
        
        .value {
            color: #667eea;
            font-family: 'Courier New', monospace;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            font-weight: 600;
            margin-top: 20px;
        }
        
        .api-link {
            display: block;
            background: #667eea;
            color: white;
            text-decoration: none;
            padding: 12px 24px;
            border-radius: 8px;
            text-align: center;
            margin-top: 20px;
            transition: background 0.3s;
        }
        
        .api-link:hover {
            background: #764ba2;
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #888;
            font-size: 0.9em;
        }
        
        .badge {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.8em;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 HNG13 DevOps</h1>
        <div class="subtitle">Stage 1 - Automated Deployment</div>
        
        <div class="success">
            ✅ Application Successfully Deployed!
        </div>
        
        <div class="status">
            <div class="status-item">
                <span class="label">Status:</span>
                <span class="value"><span class="badge">RUNNING</span></span>
            </div>
            <div class="status-item">
                <span class="label">Hostname:</span>
                <span class="value">{{ hostname }}</span>
            </div>
            <div class="status-item">
                <span class="label">Server Time:</span>
                <span class="value">{{ current_time }}</span>
            </div>
            <div class="status-item">
                <span class="label">Port:</span>
                <span class="value">{{ port }}</span>
            </div>
            <div class="status-item">
                <span class="label">Environment:</span>
                <span class="value">{{ environment }}</span>
            </div>
        </div>
        
        <a href="/api/health" class="api-link">📊 Check Health API</a>
        <a href="/api/info" class="api-link">ℹ️ View System Info</a>
        
        <div class="footer">
            <p>Deployed with ❤️ using Docker & Nginx</p>
            <p style="margin-top: 5px;">HNG Internship 13.0 | DevOps Track</p>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    """Home page with deployment status"""
    return render_template_string(
        HTML_TEMPLATE,
        hostname=socket.gethostname(),
        current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        port=os.getenv('PORT', '5000'),
        environment=os.getenv('ENVIRONMENT', 'production')
    )

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'hng13-devops-stage1',
        'version': '1.0.0'
    }), 200

@app.route('/api/info')
def info():
    """System information endpoint"""
    return jsonify({
        'application': 'HNG13 DevOps Stage 1',
        'hostname': socket.gethostname(),
        'timestamp': datetime.now().isoformat(),
        'port': os.getenv('PORT', '5000'),
        'environment': os.getenv('ENVIRONMENT', 'production'),
        'python_version': os.sys.version,
        'status': 'running'
    }), 200

@app.route('/api/status')
def status():
    """Simple status check"""
    return jsonify({
        'status': 'ok',
        'message': 'Application is running successfully'
    }), 200

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested endpoint does not exist',
        'status': 404
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'status': 500
    }), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    print(f"Starting HNG13 DevOps Application...")
    print(f"Running on port {port}")
    print(f"Debug mode: {debug}")
    
    app.run(
        host='0.0.0.0',
        port=port,
        debug=debug
    )

