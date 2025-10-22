# HNG13 DevOps Stage 1: Automated Deployment Script

A production-grade Bash script that automates the setup, deployment, and configuration of a Dockerized application on a remote Linux server with Nginx reverse proxy.

## Table of Contents

- [Overview](#overview)
- [Sample Application](#sample-application)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Script Usage](#deployment-script-usage)
- [API Endpoints](#api-endpoints)
- [Configuration](#configuration)

## Overview

This project demonstrates a complete DevOps workflow including:
- **Automated deployment** via Bash scripting
- **Containerization** with Docker
- **Reverse proxy** configuration with Nginx
- **Production-ready** Flask web application
- **Health monitoring** and logging
- **Security best practices**

## Sample Application

The included sample application is a **Flask-based web service** that provides:

### Features
- Beautiful, responsive web interface
- RESTful API endpoints
- Health check endpoints for monitoring
- System information display
- Production-ready with Gunicorn WSGI server
- Proper error handling (404, 500)
- Docker health checks
- Security hardening (non-root user)

### Technology Stack
- **Backend**: Python 3.11 + Flask 3.0
- **WSGI Server**: Gunicorn
- **Container**: Docker with multi-stage optimization
- **Orchestration**: Docker Compose
- **Web Server**: Nginx (reverse proxy)

## ✨ Features

### Deployment Script (`deploy.sh`)
- Secure authentication with PAT (Personal Access Token)
- Automatic Git repository cloning and updates
- Docker and Docker Compose installation
- Nginx reverse proxy configuration
- Comprehensive validation and health checks
- Detailed logging with timestamps
- Idempotent operations (safe to re-run)
- Error handling with trap functions
- Optional cleanup mode

##  Prerequisites

### Local Development
- Docker (v20.10+)
- Docker Compose (v2.0+)
- Python 3.11+ (for local testing without Docker)
- Git

### Remote Server
- Linux server (Ubuntu 24.04+ recommended)
- SSH access with key-based authentication
- sudo privileges
- Open ports: 80 (HTTP), 443 (HTTPS), 5000 (app)

### For Deployment Script
- Bash 4.0+
- Git with PAT (Personal Access Token)
- SSH client
- Network connectivity to remote server

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/hng13-stage1-devops.git
cd hng13-stage1-devops
```

### 2. Test Locally with Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# Or build and run manually
docker build -t hng13-app .
docker run -d -p 5000:5000 --name hng13-app hng13-app

# Access the application
open http://localhost:5000
```

### 3. Test Locally without Docker

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py

# Access at http://localhost:5000
```

### 4. Deploy to Remote Server

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

Follow the interactive prompts to provide:
- GitHub repository URL
- Personal Access Token (PAT)
- Branch name (default: main)
- SSH username
- Server IP address
- SSH key path
- Application port (default: 5000)

## 📖 Deployment Script Usage

### Basic Deployment

```bash
./deploy.sh
```

### With Cleanup Option (removes existing deployment)

```bash
./deploy.sh --cleanup
```

### Script Flow

1. **Input Collection**: Gathers repository and server details
2. **Repository Clone**: Clones/updates the Git repository
3. **Validation**: Verifies Dockerfile presence
4. **SSH Connection**: Tests remote server connectivity
5. **Environment Setup**: Installs Docker, Compose, Nginx
6. **File Transfer**: Syncs project files to server
7. **Container Deployment**: Builds and runs Docker containers
8. **Nginx Configuration**: Sets up reverse proxy
9. **Health Validation**: Confirms successful deployment
10. **Logging**: Records all operations

## 🧪 Testing Locally

### Test with Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Check container status
docker-compose ps

# Stop services
docker-compose down
```

### Test API Endpoints

```bash
# Health check
curl http://localhost:5000/api/health

# System info
curl http://localhost:5000/api/info

# Status check
curl http://localhost:5000/api/status
```

### Expected Responses

**Health Check** (`/api/health`):
```json
{
  "status": "healthy",
  "timestamp": "2025-10-22T12:00:00.000000",
  "service": "hng13-devops-stage1",
  "version": "1.0.0"
}
```

**System Info** (`/api/info`):
```json
{
  "application": "HNG13 DevOps Stage 1",
  "hostname": "container-id",
  "timestamp": "2025-10-22T12:00:00.000000",
  "port": "5000",
  "environment": "production",
  "status": "running"
}
```

## 🔌 API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/` | GET | Home page with UI | HTML |
| `/api/health` | GET | Health check | JSON |
| `/api/info` | GET | System information | JSON |
| `/api/status` | GET | Simple status check | JSON |

## ⚙️ Configuration

### Environment Variables

Create a `.env` file for custom configuration (optional):

```bash
# Application
PORT=5000
ENVIRONMENT=production
DEBUG=False

# Gunicorn
WORKERS=4
TIMEOUT=60
```

### Docker Compose Override

For local development, create `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  web:
    environment:
      - DEBUG=True
      - ENVIRONMENT=development
    volumes:
      - ./app.py:/app/app.py
```

### Nginx Configuration (Generated by deploy.sh)

The deployment script automatically creates an Nginx configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 👤 Author

**Your Name**
- GitHub: [@KimVianney](https://github.com/KimVianney)
- HNG13 DevOps Track