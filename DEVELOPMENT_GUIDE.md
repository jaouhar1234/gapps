# Gapps Development Guide

This guide will help you set up your development environment for Gapps.

## Quick Start Options

### Option 1: Deploy to Ubuntu Server (Recommended for Production-like Environment)

**Prerequisites:**
- SSH access to your Ubuntu server (vps-72cad608.vps.ovh.net)
- Root or sudo access

**Deployment Steps:**

1. Ensure you have SSH keys set up:
```bash
ssh-copy-id root@vps-72cad608.vps.ovh.net
```

2. Run the deployment script:
```bash
./deploy_to_server.sh
```

3. Access your application:
```
http://vps-72cad608.vps.ovh.net:8000
```

**Manual Deployment (if script doesn't work):**

```bash
# SSH into your server
ssh root@vps-72cad608.vps.ovh.net

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone your fork
cd /opt
git clone https://github.com/jaouhar1234/gapps.git
cd gapps
git checkout claude/session-011CUZS6TekTatPWzDNK71Tn

# Start the application
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f

# Open firewall
ufw allow 8000/tcp
```

---

### Option 2: Local Development with Docker

**Prerequisites:**
- Docker installed
- Docker Compose installed

**Setup Steps:**

1. Install Docker (if not installed):
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

2. Start the development environment:
```bash
cd /home/user/gapps
docker-compose up -d
```

3. View logs:
```bash
docker-compose logs -f
```

4. Access the application:
```
http://localhost:8000
```

**Making Changes:**
- Edit files in your local repository
- Changes to Python code require restart: `docker-compose restart app`
- Database changes require migration (see below)

---

### Option 3: Local Development WITHOUT Docker

**Prerequisites:**
- Python 3.9+
- PostgreSQL 12+
- libpq-dev

**Setup Steps:**

1. Install PostgreSQL:
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib libpq-dev
sudo systemctl start postgresql
```

2. Create database:
```bash
sudo -u postgres psql << EOF
CREATE USER db1 WITH PASSWORD 'db1';
CREATE DATABASE db1 OWNER db1;
GRANT ALL PRIVILEGES ON DATABASE db1 TO db1;
EOF
```

3. Configure environment:
```bash
cd /home/user/gapps

# Edit .env file
nano .env

# Uncomment these lines:
# POSTGRES_HOST=localhost
# POSTGRES_USER=db1
# POSTGRES_PASSWORD=db1
# POSTGRES_DB=db1
# SQLALCHEMY_DATABASE_URI=postgresql://db1:db1@localhost/db1
```

4. Install Python dependencies:
```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

5. Run the application:
```bash
source venv/bin/activate
export FLASK_CONFIG=development
bash run.sh
```

6. Access the application:
```
http://localhost:5000
```

---

## Development Workflow

### Working with Git

```bash
# Make sure you're on your development branch
git checkout claude/session-011CUZS6TekTatPWzDNK71Tn

# Pull latest changes
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn

# Make your changes
# ... edit files ...

# Commit changes
git add .
git commit -m "Your commit message"

# Push to your fork
git push -u origin claude/session-011CUZS6TekTatPWzDNK71Tn
```

### Database Migrations

When you change database models:

**With Docker:**
```bash
docker exec -it app bash
python3 manage.py db migrate -m "Description of changes"
python3 manage.py db upgrade
exit
```

**Without Docker:**
```bash
source venv/bin/activate
python3 manage.py db migrate -m "Description of changes"
python3 manage.py db upgrade
```

### Resetting the Database

**WARNING: This deletes all data!**

**With Docker:**
```bash
export RESET_DB=yes
docker-compose restart app
unset RESET_DB
```

**Without Docker:**
```bash
export RESET_DB=yes
bash run.sh
# Stop with Ctrl+C after initialization
unset RESET_DB
```

---

## Testing Your Changes

### Running Tests

```bash
# With Docker
docker exec -it app pytest

# Without Docker
source venv/bin/activate
pytest
```

### Manual Testing Checklist

1. Login functionality
2. Create a new tenant
3. Add frameworks
4. Create controls
5. Upload files
6. Export data

---

## Troubleshooting

### Cannot connect to database

Check your connection string:
```bash
# With Docker
docker exec -it app env | grep SQLALCHEMY

# Without Docker
echo $SQLALCHEMY_DATABASE_URI
```

### Port already in use

```bash
# Find what's using port 8000
sudo lsof -i :8000

# Kill the process
sudo kill -9 <PID>
```

### Docker container won't start

```bash
# Check logs
docker-compose logs app

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Permission denied errors

```bash
# Fix file permissions
sudo chown -R $USER:$USER /home/user/gapps
```

---

## Remote Development on Server

### SSH into server and develop:

```bash
ssh root@vps-72cad608.vps.ovh.net

cd /opt/gapps
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn

# Make changes
nano app/routes/main.py

# Restart app
docker-compose restart app

# View logs
docker-compose logs -f app
```

---

## Useful Commands

### Docker Commands
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f app

# Restart specific service
docker-compose restart app

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Rebuild and start
docker-compose up -d --build

# Execute command in container
docker exec -it app bash
```

### Git Commands
```bash
# Check current branch
git branch

# Check status
git status

# View changes
git diff

# View commit history
git log --oneline -10

# Switch branches
git checkout main
git checkout claude/session-011CUZS6TekTatPWzDNK71Tn
```

### Database Commands
```bash
# Connect to PostgreSQL (with Docker)
docker exec -it postgres psql -U db1 -d db1

# Connect to PostgreSQL (without Docker)
psql -U db1 -d db1

# List tables
\dt

# Describe table
\d+ table_name

# Exit psql
\q
```

---

## Environment Variables

Key environment variables you can configure in `.env`:

```bash
# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_USER=db1
POSTGRES_PASSWORD=db1
POSTGRES_DB=db1
SQLALCHEMY_DATABASE_URI=postgresql://db1:db1@localhost/db1

# Flask Configuration
FLASK_CONFIG=development  # or production
SECRET_KEY=your-secret-key-here

# Application Configuration
VERSION=1.0.0
RESET_DB=no
GUNICORN_WORKERS=2

# File Storage (Optional)
# AWS S3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_S3_BUCKET=your-bucket

# Google Cloud Storage
GCS_BUCKET_NAME=your-bucket
```

---

## Next Steps

1. Choose your development environment (local or server)
2. Set up the environment following the instructions above
3. Make your changes
4. Test locally
5. Commit and push to your fork
6. Deploy to production server when ready

---

## Support

- **Documentation**: https://web-gapps.pages.dev/docs
- **Discord**: https://discord.gg/9unhWAqadg
- **GitHub**: https://github.com/jaouhar1234/gapps
