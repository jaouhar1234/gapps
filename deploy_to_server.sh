#!/bin/bash

# Deployment script for Gapps to Ubuntu Server
# This script deploys YOUR FORK (jaouhar1234/gapps) to the server
# NOT the official bmarsh9/gapps version
# Server: vps-72cad608.vps.ovh.net

SERVER="vps-72cad608.vps.ovh.net"
DEPLOY_DIR="/opt/gapps"
REPO_URL="https://github.com/jaouhar1234/gapps.git"
BRANCH="claude/session-011CUZS6TekTatPWzDNK71Tn"
# You can change to "main" if you want to deploy from main branch

echo "======================================"
echo "Deploying Gapps to $SERVER"
echo "======================================"

# Function to run commands on remote server
run_remote() {
    ssh root@$SERVER "$@"
}

# Check if SSH connection works
echo "Testing SSH connection..."
if ! run_remote "echo 'Connection successful'"; then
    echo "ERROR: Cannot connect to server. Please check your SSH keys."
    exit 1
fi

# Install Docker if not present
echo "Checking Docker installation..."
run_remote "which docker || (curl -fsSL https://get.docker.com | sh && systemctl start docker && systemctl enable docker)"

# Install Docker Compose if not present
echo "Checking Docker Compose installation..."
run_remote "which docker-compose || curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose"

# Clone or update repository
echo "Setting up repository..."
run_remote "
if [ -d $DEPLOY_DIR ]; then
    cd $DEPLOY_DIR
    git fetch origin
    git checkout $BRANCH
    git pull origin $BRANCH
else
    git clone -b $BRANCH $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
fi
"

# Build and start the application from YOUR fork
echo "Building and starting application from YOUR fork..."
echo "This will build the Docker image from source code in your fork"
run_remote "cd $DEPLOY_DIR && docker-compose down && docker-compose build --no-cache && docker-compose up -d"

# Check status
echo "Checking application status..."
run_remote "cd $DEPLOY_DIR && docker-compose ps"

# Configure firewall
echo "Configuring firewall..."
run_remote "ufw allow 8000/tcp || echo 'Firewall rule already exists or ufw not installed'"

echo "======================================"
echo "Deployment complete!"
echo "Access your application at: http://$SERVER:8000"
echo "======================================"
echo ""
echo "Useful commands:"
echo "  View logs: ssh root@$SERVER 'cd $DEPLOY_DIR && docker-compose logs -f'"
echo "  Restart: ssh root@$SERVER 'cd $DEPLOY_DIR && docker-compose restart'"
echo "  Stop: ssh root@$SERVER 'cd $DEPLOY_DIR && docker-compose down'"
