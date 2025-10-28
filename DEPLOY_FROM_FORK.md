# Deploying Your Fork (jaouhar1234/gapps) to Ubuntu Server

This guide explains how to deploy **YOUR fork** of Gapps to your Ubuntu server, building from **your source code** instead of using the official Docker Hub image.

## Important: This Uses YOUR Code

- **Your Fork**: https://github.com/jaouhar1234/gapps
- **Branch**: claude/session-011CUZS6TekTatPWzDNK71Tn (or main)
- **NOT** using the official `bmarsh13/gapps` Docker image
- **Builds from source code** in your repository

---

## Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Deploy your fork to the server
./deploy_to_server.sh
```

This will:
1. SSH into vps-72cad608.vps.ovh.net
2. Clone/update YOUR fork from GitHub
3. Build Docker image from YOUR source code
4. Start the application

### Option 2: Manual Deployment

```bash
# SSH into your server
ssh root@vps-72cad608.vps.ovh.net

# Install Docker (if not installed)
curl -fsSL https://get.docker.com | sh
systemctl start docker && systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone YOUR fork
cd /opt
git clone https://github.com/jaouhar1234/gapps.git
cd gapps

# Checkout your development branch (or main)
git checkout claude/session-011CUZS6TekTatPWzDNK71Tn

# Build and start from YOUR source code
docker-compose build --no-cache
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f

# Open firewall
ufw allow 8000/tcp
```

---

## Development Workflow

### 1. Make Changes Locally

```bash
cd /home/user/gapps

# Make sure you're on the right branch
git checkout claude/session-011CUZS6TekTatPWzDNK71Tn

# Edit your code
nano app/routes/main.py

# Test locally (optional)
docker-compose up -d
docker-compose logs -f
```

### 2. Commit and Push to Your Fork

```bash
# Add your changes
git add .

# Commit
git commit -m "Description of your changes"

# Push to YOUR fork
git push -u origin claude/session-011CUZS6TekTatPWzDNK71Tn
```

### 3. Deploy to Server

```bash
# Run the deployment script
./deploy_to_server.sh
```

Or manually on the server:

```bash
ssh root@vps-72cad608.vps.ovh.net

cd /opt/gapps

# Pull latest changes from YOUR fork
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn

# Rebuild from YOUR source code
docker-compose build --no-cache
docker-compose up -d

# Check logs
docker-compose logs -f app
```

---

## Understanding the Build Process

### What's Different from Official Version?

**Official Version (what we DON'T use):**
```yaml
services:
  app:
    image: bmarsh13/gapps:3.4.3  # Pre-built image from Docker Hub
```

**Your Fork (what we DO use):**
```yaml
services:
  app:
    image: gapps-jaouhar1234:latest  # Built from YOUR source code
    build:
      context: .                     # Uses your local code
      dockerfile: Dockerfile          # Builds fresh image
```

### Build Process

1. **Clones/pulls YOUR fork** from GitHub
2. **Reads Dockerfile** in your repository
3. **Installs dependencies** from your `requirements.txt`
4. **Copies your application code** into the container
5. **Builds a custom image** tagged as `gapps-jaouhar1234:latest`
6. **Runs YOUR version** of the application

---

## Configuration

### Change Deployment Branch

Edit `deploy_to_server.sh`:

```bash
# Deploy from main branch instead of development branch
BRANCH="main"
```

### Change Server Details

Edit `deploy_to_server.sh`:

```bash
SERVER="your-server-address.com"
DEPLOY_DIR="/opt/gapps"
```

### Environment Variables

Create `.env` file on the server:

```bash
ssh root@vps-72cad608.vps.ovh.net
cd /opt/gapps
nano .env
```

Add:
```bash
POSTGRES_PASSWORD=your_secure_password
SECRET_KEY=your_secret_key
VERSION=1.0.0
# Add any other variables
```

---

## Useful Commands

### On Your Server

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f app

# Restart application
docker-compose restart app

# Rebuild from latest code
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn
docker-compose build --no-cache
docker-compose up -d

# Stop everything
docker-compose down

# Stop and remove volumes (WARNING: deletes database!)
docker-compose down -v

# Access app container
docker exec -it app bash

# Access database
docker exec -it postgres psql -U db1 -d db1

# View environment variables
docker exec -it app env
```

### On Your Local Machine

```bash
# Check which branch you're on
git branch

# Pull latest from your fork
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn

# View commit history
git log --oneline -10

# Deploy to server
./deploy_to_server.sh
```

---

## Troubleshooting

### Build Fails

```bash
# Check Docker build logs
ssh root@vps-72cad608.vps.ovh.net
cd /opt/gapps
docker-compose build

# If there are Python dependency issues, check requirements.txt
cat requirements.txt
```

### Application Won't Start

```bash
# Check application logs
docker-compose logs app

# Check database connection
docker-compose logs postgres

# Restart everything
docker-compose down
docker-compose up -d
```

### "Cannot connect to database"

```bash
# Check database is running
docker ps

# Check database logs
docker logs postgres

# Verify connection string
docker exec -it app env | grep SQLALCHEMY
```

### Changes Not Appearing

```bash
# Make sure you pulled latest code
git pull origin claude/session-011CUZS6TekTatPWzDNK71Tn

# Rebuild with no cache
docker-compose build --no-cache
docker-compose up -d

# Force recreate containers
docker-compose up -d --force-recreate
```

---

## Database Persistence

Your database data is now persistent! Even if you restart or rebuild containers, your data will be preserved.

**Volume location:**
- Volume name: `gapps_postgres`
- Mount point: `/data/postgres` inside container

**Backup database:**
```bash
ssh root@vps-72cad608.vps.ovh.net
docker exec postgres pg_dump -U db1 db1 > backup_$(date +%Y%m%d).sql
```

**Restore database:**
```bash
ssh root@vps-72cad608.vps.ovh.net
cat backup_20250101.sql | docker exec -i postgres psql -U db1 -d db1
```

---

## Security Recommendations

### 1. Change Default Passwords

```bash
# On server, edit .env
nano /opt/gapps/.env

# Add:
POSTGRES_PASSWORD=strong_random_password_here
SECRET_KEY=another_random_key_here
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

### 2. Set Up HTTPS

```bash
# Install Nginx and Certbot
apt install -y nginx certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d vps-72cad608.vps.ovh.net

# Nginx will automatically configure HTTPS
```

### 3. Firewall Configuration

```bash
# Allow only necessary ports
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8000/tcp  # Or remove if using Nginx reverse proxy
ufw enable
```

---

## Production vs Development

### Development Branch Deployment
```bash
# In deploy_to_server.sh
BRANCH="claude/session-011CUZS6TekTatPWzDNK71Tn"

# Characteristics:
# - Latest features and changes
# - May be unstable
# - Good for testing
```

### Main Branch Deployment
```bash
# In deploy_to_server.sh
BRANCH="main"

# Characteristics:
# - Stable code
# - Production-ready
# - Recommended for live environments
```

---

## Next Steps

1. ✅ **Fork is configured** to build from YOUR source code
2. ✅ **Database persistence** is enabled
3. ✅ **Deployment script** is ready

**To deploy now:**
```bash
./deploy_to_server.sh
```

**To develop locally first:**
```bash
docker-compose up -d
# Make changes, test, then deploy
```

---

## Support

- Your Fork: https://github.com/jaouhar1234/gapps
- Official Docs: https://web-gapps.pages.dev/docs
- Discord: https://discord.gg/9unhWAqadg
