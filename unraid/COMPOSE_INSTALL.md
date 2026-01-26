# The Logbook - Docker Compose Installation for Unraid

This guide shows you how to install The Logbook on Unraid using the Docker Compose Manager plugin.

## Prerequisites

- Unraid 6.9 or newer
- Docker Compose Manager plugin installed from Community Applications
- At least 2GB of available RAM
- 5GB+ of free disk space

## Installation Methods

Choose one of the following methods:

---

## Method 1: Docker Compose Manager Plugin (Recommended)

This is the easiest way to deploy The Logbook on Unraid with full stack management.

### Step 1: Install Docker Compose Manager

1. Open Unraid web interface
2. Go to **Apps** → **Community Applications**
3. Search for "Docker Compose Manager"
4. Click **Install**
5. Wait for installation to complete

### Step 2: Download The Logbook

SSH into your Unraid server or use the terminal:

```bash
# Navigate to appdata directory
cd /mnt/user/appdata

# Clone the repository
git clone https://github.com/thegspiro/The-Logbook-v2.git

# Enter the directory
cd The-Logbook-v2
```

### Step 3: Configure Environment Variables

```bash
# Copy the Unraid-specific environment template
cp unraid/.env.unraid.example .env

# Edit the configuration
nano .env
```

**Required Changes:**

1. Generate a Django secret key:
```bash
openssl rand -base64 50
```
Copy the output and paste it as `DJANGO_SECRET_KEY` in `.env`

2. Generate a database password:
```bash
openssl rand -base64 32
```
Copy the output and paste it as `POSTGRES_PASSWORD` in `.env`

3. Set your Unraid server IP:
```bash
# Find your Unraid IP
ip addr show | grep "inet " | grep -v 127.0.0.1
```
Add your IP to `DJANGO_ALLOWED_HOSTS` (e.g., `192.168.1.100,tower.local`)

4. Optionally customize:
   - `APP_NAME` - Your application name
   - `ORGANIZATION_NAME` - Your fire department name
   - `PRIMARY_COLOR` - Primary theme color
   - `SECONDARY_COLOR` - Secondary theme color
   - `TZ` - Your timezone

Save and exit (Ctrl+X, then Y, then Enter)

### Step 4: Deploy with Docker Compose Manager

1. **Open Docker Compose Manager**
   - In Unraid, go to **Docker** tab
   - Click **Compose Manager** at the bottom

2. **Add New Stack**
   - Click **Add New Stack**
   - Name: `logbook`
   - Compose file: Choose file → `/mnt/user/appdata/The-Logbook-v2/unraid/docker-compose.unraid.yml`
   - Environment file: Choose file → `/mnt/user/appdata/The-Logbook-v2/.env`

3. **Deploy the Stack**
   - Click **Compose Up**
   - Wait for all services to start (30-60 seconds)

4. **Verify Deployment**
   - All three containers should show "Up" status:
     - `logbook_db` (PostgreSQL)
     - `logbook_onboarding` (Django application)
     - `logbook_nginx` (Web server)

### Step 5: Complete Onboarding

1. **Access the application**
   - Open browser: `http://your-unraid-ip`
   - Or: `http://tower.local` (if using default hostname)

2. **Complete 8-step wizard**
   - Follow the onboarding process
   - Configure email, security, storage, etc.

3. **Create admin user**
   - SSH into Unraid
   - Run:
   ```bash
   cd /mnt/user/appdata/The-Logbook-v2
   docker-compose -f unraid/docker-compose.unraid.yml exec onboarding python manage.py createsuperuser
   ```
   - Enter username, email, and password

4. **Access admin panel**
   - Navigate to: `http://your-unraid-ip/admin`
   - Login with your admin credentials

---

## Method 2: Command Line Deployment

If you prefer the command line or want more control:

### Quick Start

```bash
# Navigate to installation directory
cd /mnt/user/appdata/The-Logbook-v2

# Use the automated setup script
chmod +x scripts/unraid-setup.sh
./scripts/unraid-setup.sh
```

The setup script will:
- Check system requirements
- Generate secure credentials
- Configure environment
- Deploy containers
- Run migrations

### Manual Command Line

```bash
# Configure environment
cp unraid/.env.unraid.example .env
nano .env  # Edit with your settings

# Start the stack
docker-compose -f unraid/docker-compose.unraid.yml up -d

# Wait for services to start
sleep 30

# Check status
docker-compose -f unraid/docker-compose.unraid.yml ps

# View logs
docker-compose -f unraid/docker-compose.unraid.yml logs -f
```

---

## Post-Installation

### Access Points

- **Web Interface**: `http://your-unraid-ip`
- **Admin Panel**: `http://your-unraid-ip/admin`
- **API** (future): `http://your-unraid-ip/api`

### Add to Unraid Dashboard

1. Go to **Docker** tab in Unraid
2. Find `logbook_nginx` container
3. Click **Edit**
4. Set **WebUI**: `http://[IP]:[PORT:80]`
5. Click **Apply**
6. You'll now see a clickable icon on the Docker page

### Setup Automated Backups

1. **Install User Scripts plugin** (from Community Applications)

2. **Create backup script**:
   - Go to **Settings** → **User Scripts**
   - Click **Add New Script**
   - Name: `Logbook Daily Backup`
   - Click **Edit Script**

3. **Add script content**:
```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh

# Optional: Send Unraid notification
if [ $? -eq 0 ]; then
    /usr/local/emhttp/webGui/scripts/notify -s "Logbook Backup Complete" -d "Backup successful" -i "normal"
else
    /usr/local/emhttp/webGui/scripts/notify -s "Logbook Backup FAILED" -d "Check logs!" -i "alert"
fi
```

4. **Set schedule**:
   - Click **Schedule**
   - Select: **Daily** at **2:00 AM**
   - Click **Apply**

### Setup Health Checks

Create another User Script for weekly health checks:

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2

# Run health check
docker-compose -f unraid/docker-compose.unraid.yml exec -T onboarding python manage.py check

if [ $? -ne 0 ]; then
    /usr/local/emhttp/webGui/scripts/notify -s "Logbook Health Check Failed" -d "Check the application immediately!" -i "alert"
fi
```

Schedule: **Weekly** on **Sunday** at **3:00 AM**

---

## Management Commands

### View Stack Status

```bash
cd /mnt/user/appdata/The-Logbook-v2
docker-compose -f unraid/docker-compose.unraid.yml ps
```

### View Logs

```bash
# All services
docker-compose -f unraid/docker-compose.unraid.yml logs -f

# Specific service
docker-compose -f unraid/docker-compose.unraid.yml logs -f onboarding
docker-compose -f unraid/docker-compose.unraid.yml logs -f db
docker-compose -f unraid/docker-compose.unraid.yml logs -f nginx
```

### Restart Services

```bash
# Restart all
docker-compose -f unraid/docker-compose.unraid.yml restart

# Restart specific service
docker-compose -f unraid/docker-compose.unraid.yml restart onboarding
```

### Stop Services

```bash
docker-compose -f unraid/docker-compose.unraid.yml down
```

### Start Services

```bash
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

### Update Application

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/update.sh
```

### Create Backup

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh
```

### Restore from Backup

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/restore.sh
```

---

## Port Configuration

If default ports are in use, change them in `.env`:

```bash
HTTP_PORT=8080      # Instead of 80
HTTPS_PORT=8443     # Instead of 443
APP_PORT=8001       # Instead of 8000
```

Then recreate the stack:

```bash
docker-compose -f unraid/docker-compose.unraid.yml down
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

---

## Storage Configuration

The Unraid compose file uses these default paths:

- **Application**: `/mnt/user/appdata/logbook/app`
- **Database**: `/mnt/user/appdata/logbook/database`
- **Media**: `/mnt/user/appdata/logbook/media`
- **Static**: `/mnt/user/appdata/logbook/static`
- **Backups**: `/mnt/user/backups/logbook`

### Cache vs Array

**Default (Recommended)**: `/mnt/user/appdata/logbook/`
- Uses cache drive if available
- Falls back to array if cache full
- Protected by parity

**Cache-Only**: `/mnt/cache/appdata/logbook/`
- Fastest performance
- Not protected by parity
- Use for non-critical data only

**Array-Only**: `/mnt/disk1/appdata/logbook/`
- Slower but parity protected
- No cache usage
- Use for maximum safety

To change, edit paths in `unraid/docker-compose.unraid.yml`

---

## SSL/HTTPS Configuration

### Option 1: Use Existing Reverse Proxy

If you already use Nginx Proxy Manager or Swag:

1. Configure your reverse proxy to forward to `logbook_nginx:80`
2. Set `DJANGO_ALLOWED_HOSTS` to include your domain
3. Enable these in `.env`:
   ```bash
   SESSION_COOKIE_SECURE=True
   CSRF_COOKIE_SECURE=True
   ```

### Option 2: Direct SSL in Nginx

1. Place SSL certificates in `/mnt/user/appdata/logbook/certs/`
2. Uncomment the certs volume in `docker-compose.unraid.yml`
3. Update `nginx/nginx.conf` with SSL configuration
4. Restart: `docker-compose restart nginx`

---

## Troubleshooting

### Containers Won't Start

**Check Docker Compose Manager logs**:
- Open Compose Manager
- Click on `logbook` stack
- View logs

**Common issues**:
- Ports already in use → Change ports in `.env`
- Missing `.env` file → Copy from `.env.unraid.example`
- Invalid credentials → Regenerate secrets

### Can't Access Web Interface

1. Verify containers are running:
   ```bash
   docker ps | grep logbook
   ```

2. Check if ports are open:
   ```bash
   netstat -tuln | grep -E '80|443'
   ```

3. Verify Unraid firewall settings

4. Check `DJANGO_ALLOWED_HOSTS` includes your IP

### Database Connection Errors

1. Check database is healthy:
   ```bash
   docker exec logbook_db pg_isready -U logbook_user
   ```

2. Verify credentials match in `.env`

3. Restart database:
   ```bash
   docker-compose -f unraid/docker-compose.unraid.yml restart db
   ```

### Permission Errors

Ensure Unraid user has access:

```bash
chown -R nobody:users /mnt/user/appdata/logbook
chmod -R 755 /mnt/user/appdata/logbook
```

---

## Uninstallation

To completely remove The Logbook:

### 1. Stop and Remove Containers

In Docker Compose Manager:
- Select `logbook` stack
- Click **Compose Down**
- Click **Delete Stack**

Or via command line:
```bash
cd /mnt/user/appdata/The-Logbook-v2
docker-compose -f unraid/docker-compose.unraid.yml down -v
```

### 2. Remove Application Files

```bash
rm -rf /mnt/user/appdata/The-Logbook-v2
rm -rf /mnt/user/appdata/logbook
```

### 3. Remove Backups (Optional)

```bash
rm -rf /mnt/user/backups/logbook
```

### 4. Remove Images (Optional)

```bash
docker image rm logbook_onboarding postgres:16-alpine nginx:alpine
```

---

## Support

- **Documentation**: [Main README](../README.md)
- **Unraid Guide**: [UNRAID.md](../docs/UNRAID.md)
- **Scripts Guide**: [Scripts README](../scripts/README.md)
- **Issues**: [GitHub Issues](https://github.com/thegspiro/The-Logbook-v2/issues)

---

## Quick Reference Card

### Essential Commands

```bash
# Navigate to installation
cd /mnt/user/appdata/The-Logbook-v2

# Start stack
docker-compose -f unraid/docker-compose.unraid.yml up -d

# Stop stack
docker-compose -f unraid/docker-compose.unraid.yml down

# Restart stack
docker-compose -f unraid/docker-compose.unraid.yml restart

# View logs
docker-compose -f unraid/docker-compose.unraid.yml logs -f

# Check status
docker-compose -f unraid/docker-compose.unraid.yml ps

# Update
./scripts/update.sh

# Backup
./scripts/backup.sh

# Restore
./scripts/restore.sh

# Create admin user
docker-compose -f unraid/docker-compose.unraid.yml exec onboarding python manage.py createsuperuser
```

---

**Stay Safe! 🔥🚒**
