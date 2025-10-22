#!/bin/bash 

# HNG13 DevOps Stage 1: Automated Deployment Script
# This script deploys a Dockerized application to a remote server
# with Nginx reverse proxy and SSL configuration.
# Author: Vianney Kimuri

# Exit on any error
set -e

# Script configuration
SCRIPT_DIR="$(pwd)"
LOGS_DIR="./logs"
LOG_FILE="${LOGS_DIR}/deploy_$(date +%Y%m%d_%H%M%S).log"

# Default values
DEFAULT_BRANCH="main"
DEFAULT_PORT="5000"
APP_NAME="hng13-devops-app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
GITHUB_REPO=""
PAT=""
GIT_BRANCH=""
SSH_USER=""
SSH_HOST=""
SSH_KEY_PATH=""
APP_PORT=""
CLEANUP_MODE=false

# Create log directory if it doesn't exist
if [ ! -d "$LOGS_DIR" ]; then
    echo -e "${BLUE}Creating log directory...${NC}"
    mkdir -p "$LOGS_DIR"
fi

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Ensure log directory exists before writing
    mkdir -p "$LOGS_DIR"
    echo "$timestamp - $message" | tee -a "$LOG_FILE"
}

# Function to log errors
log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Ensure log directory exists before writing
    mkdir -p "$LOGS_DIR"
    echo -e "${RED}$timestamp - ERROR: $message${NC}" | tee -a "$LOG_FILE"
}

# Function to print section headers
print_section() {
    local section="$1"
    echo ""
    echo -e "${BLUE}=== $section ===${NC}"
    echo ""
}

# Function to check if input is empty
check_input() {
    local value="$1"
    local name="$2"
    
    if [ -z "$value" ]; then
        log_error "$name is required but not provided"
        exit 1
    fi
}

# Function to validate Git URL (basic check)
validate_git_url() {
    local url="$1"
    if [[ "$url" == https://github.com/* ]]; then
        return 0
    else
        log_error "Invalid GitHub URL format. Expected: https://github.com/username/repository"
        exit 1
    fi
}

# Function to validate IP address (basic check)
validate_ip() {
    local ip="$1"
    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        log_error "Invalid IP address format: $ip"
        exit 1
    fi
}

# Function to check if SSH key exists
check_ssh_key() {
    local key_path="$1"
    
    if [ ! -f "$key_path" ]; then
        log_error "SSH key file not found: $key_path"
        exit 1
    fi
}

# Function to get repository name from URL
get_repo_name() {
    local url="$1"
    echo "$url" | sed 's/.*\///' | sed 's/\.git$//'
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [--cleanup] [--help]"
    echo ""
    echo "Options:"
    echo "  --cleanup    Remove existing deployment"
    echo "  --help       Show this help message"
    echo ""
    echo "This script will ask for:"
    echo "  - GitHub repository URL"
    echo "  - Personal Access Token (PAT)"
    echo "  - Branch name (default: main)"
    echo "  - Server username and IP"
    echo "  - SSH key path"
    echo "  - Application port (default: 5000)"
}

# Function to cleanup deployment
cleanup_deployment() {
    print_section "CLEANUP MODE"
    
    log_message "Starting cleanup..."
    
    # Get server details
    read -p "Enter server username: " SSH_USER
    read -p "Enter server IP address: " SSH_HOST
    read -p "Enter SSH key path: " SSH_KEY_PATH
    
    # Basic validation
    check_input "$SSH_USER" "Server username"
    check_input "$SSH_HOST" "Server IP address"
    check_input "$SSH_KEY_PATH" "SSH key path"
    validate_ip "$SSH_HOST"
    check_ssh_key "$SSH_KEY_PATH"
    
    # SSH options
    SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"
    
    log_message "Connecting to server for cleanup..."
    
    # Cleanup commands
    ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
        echo 'Stopping containers...'
        docker-compose down 2>/dev/null || true
        docker stop $APP_NAME 2>/dev/null || true
        docker rm $APP_NAME 2>/dev/null || true
        
        echo 'Removing Docker images...'
        docker rmi \$(docker images -q) 2>/dev/null || true
        
        echo 'Removing Nginx config...'
        sudo rm -f /etc/nginx/sites-enabled/app
        sudo rm -f /etc/nginx/sites-available/app
        sudo nginx -s reload 2>/dev/null || true
        
        echo 'Removing deployment directory...'
        rm -rf /home/$SSH_USER/deployment
        
        echo 'Cleanup completed!'
    "
    
    log_message "Cleanup completed successfully!"
    exit 0
}

# Check command line arguments
if [ "$1" = "--cleanup" ]; then
    cleanup_deployment
elif [ "$1" = "--help" ]; then
    show_usage
    exit 0
fi

# Start main deployment
print_section "HNG13 DEVOPS DEPLOYMENT SCRIPT"

log_message "Starting deployment..."

# Get user input
print_section "GETTING DEPLOYMENT DETAILS"

echo -e "${BLUE}Repository Details:${NC}"
read -p "GitHub repository URL: " GITHUB_REPO
read -s -p "Personal Access Token (PAT): " PAT
echo ""
read -p "Branch name [$DEFAULT_BRANCH]: " GIT_BRANCH

echo -e "\n${BLUE}Server Details:${NC}"
read -p "Server username: " SSH_USER
read -p "Server IP address: " SSH_HOST
read -p "SSH key path: " SSH_KEY_PATH
read -p "Application port [$DEFAULT_PORT]: " APP_PORT

# Set defaults
if [ -z "$GIT_BRANCH" ]; then
    GIT_BRANCH="$DEFAULT_BRANCH"
fi
if [ -z "$APP_PORT" ]; then
    APP_PORT="$DEFAULT_PORT"
fi

# Validate inputs
print_section "VALIDATING INPUTS"

log_message "Checking inputs..."

check_input "$GITHUB_REPO" "GitHub repository URL"
check_input "$PAT" "Personal Access Token"
check_input "$SSH_USER" "Server username"
check_input "$SSH_HOST" "Server IP address"
check_input "$SSH_KEY_PATH" "SSH key path"

validate_git_url "$GITHUB_REPO"
validate_ip "$SSH_HOST"
check_ssh_key "$SSH_KEY_PATH"

log_message "All inputs are valid!"

# Clone repository
print_section "CLONING REPOSITORY"

# Get repository name
REPO_NAME=$(get_repo_name "$GITHUB_REPO")
LOCAL_REPO_DIR="./$REPO_NAME"

log_message "Repository: $REPO_NAME"

# Remove existing directory if it exists
if [ -d "$LOCAL_REPO_DIR" ]; then
    log_message "Removing existing directory..."
    rm -rf "$LOCAL_REPO_DIR"
fi

# Clone repository with PAT
log_message "Cloning repository..."
AUTHENTICATED_URL=$(echo "$GITHUB_REPO" | sed "s|https://|https://${PAT}@|")
git clone -b "$GIT_BRANCH" "$AUTHENTICATED_URL" "$LOCAL_REPO_DIR"

cd "$LOCAL_REPO_DIR"

# Check for required files
log_message "Checking for Docker files..."

if [ -f "docker-compose.yml" ]; then
    log_message "Found docker-compose.yml"
    USE_COMPOSE=true
elif [ -f "Dockerfile" ]; then
    log_message "Found Dockerfile"
    USE_COMPOSE=false
else
    log_error "No Dockerfile or docker-compose.yml found!"
    exit 1
fi

log_message "Repository ready!"

# Test SSH connection
print_section "TESTING SSH CONNECTION"

SSH_OPTS="-i $SSH_KEY_PATH -o StrictHostKeyChecking=no"

log_message "Testing connection to $SSH_USER@$SSH_HOST..."

# Test SSH
if ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "echo 'SSH OK'" >/dev/null 2>&1; then
    log_message "SSH connection successful!"
else
    log_error "SSH connection failed!"
    log_error "Check your server IP, username, and SSH key"
    exit 1
fi

# Test sudo
log_message "Testing sudo access..."
if ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "sudo echo 'Sudo OK'" >/dev/null 2>&1; then
    log_message "Sudo access confirmed!"
else
    log_error "Sudo access failed!"
    log_error "Make sure user has sudo privileges"
    exit 1
fi

# Setup remote server
print_section "SETTING UP REMOTE SERVER"

log_message "Installing required software..."

# Install Docker, Nginx, and other tools
ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
    echo 'Updating packages...'
    sudo apt-get update -y
    
    echo 'Installing Docker...'
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    echo 'Installing Docker Compose...'
    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo 'Installing Nginx...'
    sudo apt-get install -y nginx
    
    echo 'Adding user to docker group...'
    sudo usermod -aG docker $SSH_USER
    
    echo 'Starting services...'
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    echo 'Setup complete!'
"

log_message "Remote server setup completed!"

# Transfer files
print_section "TRANSFERRING FILES"

REMOTE_DIR="/home/$SSH_USER/deployment"

log_message "Copying files to server..."

# Create directory on server
ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_DIR"

# Copy files using rsync (we're currently in the cloned directory)
rsync -avz --exclude='.git' --exclude='logs' -e "ssh $SSH_OPTS" "./" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/"

log_message "Files transferred successfully!"

# Deploy application
print_section "DEPLOYING APPLICATION"

log_message "Starting deployment..."

# Deploy using Docker or Docker Compose
if [ "$USE_COMPOSE" = true ]; then
    log_message "Using Docker Compose..."
    ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
        cd $REMOTE_DIR
        echo 'Stopping old containers...'
        docker-compose down 2>/dev/null || true
        echo 'Starting new containers...'
        docker-compose up -d --build
        echo 'Waiting for app to start...'
        sleep 15
        echo 'Checking if app is running...'
        if docker-compose ps | grep -q 'Up'; then
            echo 'Docker Compose deployment successful!'
        else
            echo 'Deployment failed!'
            docker-compose logs
            exit 1
        fi
    "
else
    log_message "Using Docker build..."
    ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
        cd $REMOTE_DIR
        echo 'Stopping old container...'
        docker stop $APP_NAME 2>/dev/null || true
        docker rm $APP_NAME 2>/dev/null || true
        echo 'Building new image...'
        docker build -t $APP_NAME .
        echo 'Starting container...'
        docker run -d --name $APP_NAME -p $APP_PORT:5000 $APP_NAME
        echo 'Waiting for app to start...'
        sleep 15
        echo 'Checking if app is running...'
        if docker ps | grep -q $APP_NAME; then
            echo 'Docker deployment successful!'
        else
            echo 'Deployment failed!'
            docker logs $APP_NAME
            exit 1
        fi
    "
fi

log_message "Application deployed successfully!"

# Configure Nginx
print_section "CONFIGURING NGINX"

log_message "Setting up reverse proxy..."

# Create Nginx config and SSL certificate
ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
    echo 'Creating Nginx configuration...'
    sudo tee /etc/nginx/sites-available/app > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/app.crt;
    ssl_certificate_key /etc/nginx/ssl/app.key;
    
    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    echo 'Creating SSL directory...'
    sudo mkdir -p /etc/nginx/ssl
    
    echo 'Generating SSL certificate...'
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/app.key \
        -out /etc/nginx/ssl/app.crt \
        -subj '/C=US/ST=State/L=City/O=Organization/CN=localhost'
    
    echo 'Enabling site...'
    sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    echo 'Testing configuration...'
    sudo nginx -t
    
    echo 'Reloading Nginx...'
    sudo systemctl reload nginx
    
    echo 'Nginx configured!'
"

log_message "Nginx configuration completed!"

# Test deployment
print_section "TESTING DEPLOYMENT"

log_message "Testing the deployment..."

# Test the application
ssh $SSH_OPTS "$SSH_USER@$SSH_HOST" "
    echo 'Checking Docker...'
    if systemctl is-active --quiet docker; then
        echo 'Docker is running'
    else
        echo 'Docker is not running!'
        exit 1
    fi
    
    echo 'Checking containers...'
    if [ -f '$REMOTE_DIR/docker-compose.yml' ]; then
        if docker-compose -f $REMOTE_DIR/docker-compose.yml ps | grep -q 'Up'; then
            echo 'Docker Compose containers are running'
        else
            echo 'Containers are not running!'
            exit 1
        fi
    else
        if docker ps | grep -q $APP_NAME; then
            echo 'Docker container is running'
        else
            echo 'Container is not running!'
            exit 1
        fi
    fi
    
    echo 'Checking Nginx...'
    if systemctl is-active --quiet nginx; then
        echo 'Nginx is running'
    else
        echo 'Nginx is not running!'
        exit 1
    fi
    
    echo 'Testing application...'
    sleep 5
    if curl -f http://localhost:$APP_PORT/api/health >/dev/null 2>&1; then
        echo 'Application is responding!'
    else
        echo 'Application is not responding!'
        exit 1
    fi
    
    echo 'All tests passed!'
"

log_message "Deployment test successful!"

# Show summary
print_section "DEPLOYMENT COMPLETE"

echo -e "${GREEN}✓ DEPLOYMENT SUCCESSFUL!${NC}"
echo ""
echo -e "${BLUE}Your application is now running at:${NC}"
echo -e "  HTTP:  http://$SSH_HOST (redirects to HTTPS)"
echo -e "  HTTPS: https://$SSH_HOST"
echo -e "  Health: https://$SSH_HOST/api/health"
echo ""
echo -e "${BLUE}To manage your deployment:${NC}"
echo -e "  View logs: ssh $SSH_OPTS $SSH_USER@$SSH_HOST 'cd $REMOTE_DIR && docker-compose logs -f'"
echo -e "  Restart: ssh $SSH_OPTS $SSH_USER@$SSH_HOST 'cd $REMOTE_DIR && docker-compose restart'"
echo -e "  Cleanup: ./deploy.sh --cleanup"
echo ""
echo -e "${BLUE}Log file: $LOG_FILE${NC}"
echo ""

log_message "Deployment completed successfully!"
