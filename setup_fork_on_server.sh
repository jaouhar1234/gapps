#!/bin/bash

# Setup script to deploy YOUR fork on Ubuntu server
# This script handles the case where official version is already running

SERVER="vps-72cad608.vps.ovh.net"
USER="ubuntu"  # OVH cloud user
BACKUP_DIR="/opt/gapps_official_backup"
DEPLOY_DIR="/opt/gapps"
REPO_URL="https://github.com/jaouhar1234/gapps.git"
BRANCH="claude/session-011CUZS6TekTatPWzDNK71Tn"

echo "======================================"
echo "Setting up YOUR fork on $SERVER"
echo "======================================"

# Function to run commands on remote server
run_remote() {
    ssh $USER@$SERVER "$@"
}

echo "Step 1: Checking current deployment..."
run_remote "
if [ -f /opt/gapps/docker-compose.yml ]; then
    echo 'Found existing deployment at /opt/gapps'
    cd /opt/gapps
    sudo docker-compose down
    echo 'Stopped containers'
else
    echo 'No existing deployment found at /opt/gapps'
fi
"

echo "Step 2: Installing Git if needed..."
run_remote "which git || sudo apt update && sudo apt install -y git"

echo "Step 3: Backing up old deployment (if exists)..."
run_remote "
if [ -d $DEPLOY_DIR ]; then
    if [ ! -d $DEPLOY_DIR/.git ]; then
        echo 'Backing up non-git deployment...'
        sudo mv $DEPLOY_DIR $BACKUP_DIR
        echo 'Backup created at $BACKUP_DIR'
    elif [ -d $DEPLOY_DIR/.git ]; then
        cd $DEPLOY_DIR
        CURRENT_REMOTE=\$(git remote get-url origin 2>/dev/null || echo 'none')
        if [[ \$CURRENT_REMOTE != *'jaouhar1234'* ]]; then
            echo 'Found official repo, backing up...'
            cd /opt
            sudo mv $DEPLOY_DIR $BACKUP_DIR
            echo 'Backup created at $BACKUP_DIR'
        else
            echo 'YOUR fork already exists, updating...'
        fi
    fi
fi
"

echo "Step 4: Cloning/updating YOUR fork..."
run_remote "
if [ ! -d $DEPLOY_DIR ]; then
    echo 'Cloning YOUR fork...'
    cd /opt
    sudo git clone $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
    sudo git checkout $BRANCH
else
    echo 'Updating YOUR fork...'
    cd $DEPLOY_DIR
    sudo git fetch origin
    sudo git checkout $BRANCH
    sudo git pull origin $BRANCH
fi
"

echo "Step 5: Installing Docker if needed..."
run_remote "
if ! command -v docker &> /dev/null; then
    echo 'Installing Docker...'
    curl -fsSL https://get.docker.com | sudo sh
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo 'Docker already installed'
fi
"

echo "Step 6: Installing Docker Compose if needed..."
run_remote "
if ! command -v docker-compose &> /dev/null; then
    echo 'Installing Docker Compose...'
    sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo 'Docker Compose already installed'
fi
"

echo "Step 7: Building Docker image from YOUR fork's source code..."
run_remote "cd $DEPLOY_DIR && sudo docker-compose build --no-cache"

echo "Step 8: Starting containers..."
run_remote "cd $DEPLOY_DIR && sudo docker-compose up -d"

echo "Step 9: Checking status..."
run_remote "cd $DEPLOY_DIR && sudo docker-compose ps"

echo "Step 10: Configuring firewall..."
run_remote "sudo ufw allow 8000/tcp 2>/dev/null || echo 'Firewall rule already exists or ufw not available'"

echo ""
echo "======================================"
echo "✅ Deployment Complete!"
echo "======================================"
echo ""
echo "Your application is now running YOUR fork's code:"
echo "  URL: http://$SERVER:8000"
echo "  Fork: https://github.com/jaouhar1234/gapps"
echo "  Branch: $BRANCH"
echo ""
echo "Verification:"
run_remote "cd $DEPLOY_DIR && git remote -v"
run_remote "cd $DEPLOY_DIR && git branch"
echo ""
echo "View logs:"
echo "  ssh $USER@$SERVER 'cd $DEPLOY_DIR && sudo docker-compose logs -f app'"
echo ""
echo "Old deployment backed up at: $BACKUP_DIR"
echo "======================================"
