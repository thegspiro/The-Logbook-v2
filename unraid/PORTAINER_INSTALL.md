# The Logbook - Portainer Deployment Guide

Complete guide for deploying The Logbook using Portainer on Unraid and other Docker hosts.

## Table of Contents

1. [What is Portainer?](#what-is-portainer)
2. [Installing Portainer](#installing-portainer)
3. [Deploying The Logbook Stack](#deploying-the-logbook-stack)
4. [Managing Your Deployment](#managing-your-deployment)
5. [Monitoring and Logs](#monitoring-and-logs)
6. [Updates and Maintenance](#updates-and-maintenance)
7. [Troubleshooting](#troubleshooting)

---

## What is Portainer?

Portainer is a lightweight container management UI that makes it easy to deploy and manage Docker containers through a web interface. It's perfect for users who prefer a GUI over command-line operations.

**Benefits:**
- ✅ User-friendly web interface
- ✅ Stack deployment with docker-compose
- ✅ Environment variable management
- ✅ Real-time container logs and stats
- ✅ Built-in console access
- ✅ Template library
- ✅ Multi-host support

---

## Installing Portainer

### On Unraid

**Method 1: Community Applications (Recommended)**

1. Open Unraid web interface
2. Go to **Apps** → **Community Applications**
3. Search for "**Portainer**"
4. Click on **Portainer-CE** (Community Edition)
5. Configure settings:
   - **Name**: Portainer
   - **WebUI Port**: 9000 (or 9443 for HTTPS)
   - **Data Path**: `/mnt/user/appdata/portainer`
6. Click **Apply**
7. Wait for installation to complete

**Method 2: Command Line**

```bash
docker run -d \
  --name=portainer \
  --restart=unless-stopped \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/user/appdata/portainer:/data \
  portainer/portainer-ce:latest
```

### On Other Systems

```bash
docker volume create portainer_data

docker run -d \
  --name=portainer \
  --restart=unless-stopped \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

### First-Time Setup

1. **Access Portainer**: `http://your-server-ip:9000` or `https://your-server-ip:9443`

2. **Create admin account**:
   - Username: `admin`
   - Password: (choose a strong password)
   - Confirm password

3. **Select environment**:
   - Choose "**Docker - Manage the local Docker environment**"
   - Click **Connect**

You're now ready to deploy The Logbook!

---

## Deploying The Logbook Stack

### Step 1: Prepare the Files

**Option A: Clone Repository to Server**

SSH into your server:

```bash
# For Unraid
cd /mnt/user/appdata
git clone https://github.com/thegspiro/The-Logbook-v2.git

# For other systems
cd /opt
git clone https://github.com/thegspiro/The-Logbook-v2.git
```

**Option B: Download ZIP**

1. Download: https://github.com/thegspiro/The-Logbook-v2/archive/refs/heads/main.zip
2. Extract to your server's appdata directory

### Step 2: Configure Environment Variables

Create your `.env` file:

```bash
# For Unraid
cd /mnt/user/appdata/The-Logbook-v2
cp unraid/.env.unraid.example .env
nano .env

# For other systems
cd /opt/The-Logbook-v2
cp .env.example .env
nano .env
```

**Required Changes:**

1. **Generate Django Secret Key**:
```bash
openssl rand -base64 50
```
Copy output to `DJANGO_SECRET_KEY` in `.env`

2. **Generate Database Password**:
```bash
openssl rand -base64 32
```
Copy output to `POSTGRES_PASSWORD` in `.env`

3. **Set Allowed Hosts**:
```bash
DJANGO_ALLOWED_HOSTS=your-server-ip,your-domain.com
```

4. **Customize (Optional)**:
```bash
APP_NAME=Station 45 Logbook
ORGANIZATION_NAME=Volunteer Fire Company 45
PRIMARY_COLOR=#DC2626
SECONDARY_COLOR=#1F2937
TZ=America/New_York
```

Save and exit (Ctrl+X, Y, Enter)

### Step 3: Deploy Stack in Portainer

#### Using Web Editor (Easiest)

1. **Access Portainer**: `http://your-server-ip:9000`

2. **Navigate to Stacks**:
   - Click **Stacks** in left sidebar
   - Click **Add stack** button

3. **Configure Stack**:
   - **Name**: `the-logbook`
   - **Build method**: Choose "**Web editor**"

4. **Paste Docker Compose Content**:

   Click the "**Web editor**" tab and paste the Portainer-optimized compose file:

   ```yaml
   version: '3.8'

   services:
     db:
       image: postgres:16-alpine
       container_name: logbook_db
       restart: unless-stopped
       volumes:
         - db_data:/var/lib/postgresql/data
       environment:
         - POSTGRES_DB=${POSTGRES_DB:-logbook_db}
         - POSTGRES_USER=${POSTGRES_USER:-logbook_user}
         - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
         - TZ=${TZ:-America/New_York}
       networks:
         - logbook_network
       healthcheck:
         test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-logbook_user}"]
         interval: 10s
         timeout: 5s
         retries: 5

     onboarding:
       image: ghcr.io/thegspiro/the-logbook:latest
       container_name: logbook_onboarding
       restart: unless-stopped
       volumes:
         - app_data:/app
         - static_data:/app/staticfiles
         - media_data:/app/media
       environment:
         - DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
         - DJANGO_DEBUG=${DJANGO_DEBUG:-False}
         - DJANGO_ALLOWED_HOSTS=${DJANGO_ALLOWED_HOSTS:-*}
         - POSTGRES_DB=${POSTGRES_DB:-logbook_db}
         - POSTGRES_USER=${POSTGRES_USER:-logbook_user}
         - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
         - POSTGRES_HOST=db
         - POSTGRES_PORT=5432
         - APP_NAME=${APP_NAME:-The Logbook}
         - PRIMARY_COLOR=${PRIMARY_COLOR:-#DC2626}
         - SECONDARY_COLOR=${SECONDARY_COLOR:-#1F2937}
         - TZ=${TZ:-America/New_York}
       depends_on:
         db:
           condition: service_healthy
       networks:
         - logbook_network
       ports:
         - "${APP_PORT:-8000}:8000"

     nginx:
       image: nginx:alpine
       container_name: logbook_nginx
       restart: unless-stopped
       volumes:
         - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
         - static_data:/static:ro
         - media_data:/media:ro
       ports:
         - "${HTTP_PORT:-80}:80"
         - "${HTTPS_PORT:-443}:443"
       depends_on:
         - onboarding
       networks:
         - logbook_network

   networks:
     logbook_network:
       driver: bridge

   volumes:
     db_data:
     app_data:
     static_data:
     media_data:
   ```

5. **Add Environment Variables**:

   Scroll down to "**Environment variables**" section

   Click "**+ add an environment variable**" and add each:

   | Name | Value |
   |------|-------|
   | `DJANGO_SECRET_KEY` | (paste generated key) |
   | `POSTGRES_PASSWORD` | (paste generated password) |
   | `DJANGO_ALLOWED_HOSTS` | your-server-ip,localhost |
   | `APP_NAME` | The Logbook |
   | `ORGANIZATION_NAME` | Your Fire Department |
   | `PRIMARY_COLOR` | #DC2626 |
   | `SECONDARY_COLOR` | #1F2937 |
   | `TZ` | America/New_York |
   | `HTTP_PORT` | 80 |
   | `HTTPS_PORT` | 443 |
   | `POSTGRES_DB` | logbook_db |
   | `POSTGRES_USER` | logbook_user |

6. **Deploy the Stack**:
   - Scroll to bottom
   - Click "**Deploy the stack**"
   - Wait for deployment (30-60 seconds)

#### Using Upload (Alternative)

1. **Navigate to Stacks** → **Add stack**

2. **Configure**:
   - **Name**: `the-logbook`
   - **Build method**: Choose "**Upload**"

3. **Upload File**:
   - Click "**Upload**"
   - Select `unraid/docker-compose.unraid.yml` from your local machine
   - Or select `/mnt/user/appdata/The-Logbook-v2/unraid/docker-compose.unraid.yml` if browsing server

4. **Load Environment Variables**:
   - Enable "**Load variables from .env file**"
   - Click "**Upload**"
   - Select your `.env` file

5. **Deploy**:
   - Click "**Deploy the stack**"

#### Using Repository (Advanced)

1. **Navigate to Stacks** → **Add stack**

2. **Configure**:
   - **Name**: `the-logbook`
   - **Build method**: Choose "**Repository**"

3. **Repository Settings**:
   - **Repository URL**: `https://github.com/thegspiro/The-Logbook-v2`
   - **Repository reference**: `refs/heads/main`
   - **Compose path**: `unraid/docker-compose.unraid.yml`

4. **Environment Variables**:
   - Add all required variables as shown above

5. **Deploy**:
   - Click "**Deploy the stack**"

### Step 4: Verify Deployment

1. **Check Stack Status**:
   - Go to **Stacks** in Portainer
   - Click on "**the-logbook**"
   - All containers should show "**running**" status (green)

2. **View Container List**:
   - Three containers should be running:
     - `logbook_db` (PostgreSQL)
     - `logbook_onboarding` (Django app)
     - `logbook_nginx` (Web server)

3. **Check Logs**:
   - Click on each container
   - Click "**Logs**" tab
   - Verify no errors

### Step 5: Access The Logbook

1. **Open Web Browser**: `http://your-server-ip`

2. **Complete Onboarding**:
   - Follow the 8-step setup wizard
   - Configure email, security, storage, etc.

3. **Create Admin User**:

   In Portainer:
   - Go to **Containers**
   - Click on `logbook_onboarding`
   - Click "**Console**" tab
   - Click "**Connect**"
   - Run:
   ```bash
   python manage.py createsuperuser
   ```
   - Enter username, email, password

4. **Access Admin Panel**: `http://your-server-ip/admin`

---

## Managing Your Deployment

### Starting/Stopping the Stack

**Via Portainer UI:**

1. Go to **Stacks**
2. Click on "**the-logbook**"
3. Use buttons:
   - **Stop** - Stop all containers
   - **Start** - Start all containers
   - **Restart** - Restart all containers

**Individual Containers:**

1. Go to **Containers**
2. Select container (checkbox)
3. Use top buttons: **Start**, **Stop**, **Restart**, **Kill**

### Editing Stack Configuration

1. **Go to Stacks** → **the-logbook**
2. Click "**Editor**" tab
3. Modify docker-compose.yml
4. Click "**Update the stack**"
5. Enable "**Re-pull image and redeploy**" if needed
6. Click "**Update**"

### Updating Environment Variables

1. **Go to Stacks** → **the-logbook**
2. Click "**Editor**" tab
3. Scroll to "**Environment variables**"
4. Modify or add variables
5. Click "**Update the stack**"

### Managing Volumes

**View Volumes:**

1. Go to **Volumes** in sidebar
2. You'll see:
   - `the-logbook_db_data` - Database
   - `the-logbook_app_data` - Application
   - `the-logbook_static_data` - Static files
   - `the-logbook_media_data` - User uploads

**Browse Volume Contents:**

1. Click on volume name
2. Click "**Browse**" button (if available)

**Backup Volume:**

1. Click on volume
2. Click "**Download**" (creates .tar backup)

---

## Monitoring and Logs

### Real-Time Container Stats

1. **Go to Containers**
2. Click on container name
3. View **Stats** section:
   - CPU usage
   - Memory usage
   - Network I/O
   - Block I/O

### Container Logs

**View Logs:**

1. Go to **Containers**
2. Click container name
3. Click "**Logs**" tab
4. Options:
   - **Auto-refresh** - Enable for real-time logs
   - **Wrap lines** - Better readability
   - **Timestamps** - Show log times
   - **Fetch** - Number of lines to show

**Download Logs:**

1. View logs as above
2. Scroll to bottom
3. Click "**Copy**" or use browser save

**Search Logs:**

1. View logs
2. Use browser search (Ctrl+F / Cmd+F)
3. Search for errors, keywords, etc.

### Stack Overview

1. **Go to Stacks** → **the-logbook**
2. View overview:
   - Stack status
   - Container count
   - Resource usage
   - Quick actions

### Health Checks

**Database Health:**

1. Go to **Containers** → **logbook_db**
2. Check "**Status**" shows "(healthy)" in green
3. If unhealthy, check logs

**Application Health:**

1. Go to **Containers** → **logbook_onboarding**
2. Click "**Console**"
3. Run:
   ```bash
   python manage.py check
   ```

---

## Updates and Maintenance

### Updating The Logbook

**Method 1: Via Portainer (Easiest)**

1. **Pull Latest Images**:
   - Go to **Stacks** → **the-logbook**
   - Click "**Editor**" tab
   - Enable "**Re-pull images**"
   - Click "**Update the stack**"

2. **Run Migrations**:
   - Go to **Containers** → **logbook_onboarding**
   - Click "**Console**"
   - Run:
   ```bash
   python manage.py migrate
   python manage.py collectstatic --noinput
   ```

**Method 2: Command Line (More Control)**

1. **Backup First**:
   ```bash
   cd /mnt/user/appdata/The-Logbook-v2
   ./scripts/backup.sh
   ```

2. **Update via Script**:
   ```bash
   ./scripts/update.sh
   ```

### Creating Backups

**Via Portainer:**

1. **Backup Volumes**:
   - Go to **Volumes**
   - Click on each volume
   - Click "**Download**"
   - Save .tar files

2. **Backup Database**:
   - Go to **Containers** → **logbook_db**
   - Click "**Console**"
   - Run:
   ```bash
   pg_dump -U logbook_user logbook_db > /tmp/backup.sql
   ```
   - Download from container

**Via Script (Recommended):**

1. **In Portainer Console** (logbook_onboarding container):
   ```bash
   cd /app
   bash /app/scripts/backup.sh
   ```

**Scheduled Backups:**

Use Unraid User Scripts or cron to schedule:

```bash
#!/bin/bash
docker exec logbook_onboarding bash -c "cd /app && ./scripts/backup.sh"
```

### Restoring from Backup

**Via Script:**

1. Access container console in Portainer
2. Run:
   ```bash
   cd /app
   ./scripts/restore.sh
   ```

**Manual Restore:**

1. **Stop Stack** in Portainer

2. **Restore Database**:
   - Upload backup.sql to container
   - In console:
   ```bash
   psql -U logbook_user logbook_db < /tmp/backup.sql
   ```

3. **Restore Volumes**:
   - Go to **Volumes**
   - Click volume
   - Click "**Upload**"
   - Select backup .tar file

4. **Start Stack**

---

## Troubleshooting

### Stack Won't Deploy

**Check Errors:**
1. Deployment will show error message
2. Common issues:
   - Missing environment variables
   - Port conflicts
   - Invalid YAML syntax

**Fix Port Conflicts:**
1. Edit stack
2. Change ports in environment variables:
   ```
   HTTP_PORT=8080
   HTTPS_PORT=8443
   ```

**Validate YAML:**
- Use online validator: http://www.yamllint.com/
- Check indentation (use spaces, not tabs)

### Containers Keep Restarting

**Check Logs:**
1. Go to **Containers**
2. Click failing container
3. View "**Logs**"
4. Look for error messages

**Common Causes:**
- Database not ready → Wait 30 seconds
- Missing environment variables → Add to stack
- Port already in use → Change ports
- Out of memory → Check stats

### Can't Access Web Interface

**Verify Containers Running:**
1. Go to **Containers**
2. All should show "**running**" (green)

**Check Ports:**
1. Go to **Containers** → **logbook_nginx**
2. Verify ports: `80:80` and `443:443`
3. If different, access with custom port

**Check Firewall:**
- Ensure firewall allows port 80
- For Unraid, check Settings → Network

**Check Allowed Hosts:**
1. Edit stack
2. Verify `DJANGO_ALLOWED_HOSTS` includes your IP

### Database Connection Errors

**Check Database Health:**
1. Go to **Containers** → **logbook_db**
2. Status should show "(healthy)"

**Verify Credentials:**
1. Go to **Stacks** → **the-logbook** → **Editor**
2. Check environment variables match:
   - `POSTGRES_PASSWORD`
   - `POSTGRES_USER`
   - `POSTGRES_DB`

**Restart Database:**
1. Go to **Containers**
2. Select `logbook_db`
3. Click "**Restart**"

### Can't Access Container Console

**Enable Console:**
1. Go to **Containers** → container
2. Click "**Console**" tab
3. Click "**Connect**"

**If Connect Fails:**
- Container may not have bash
- Try `/bin/sh` instead
- Or use "**Exec Console**" button

### Volumes Not Persisting

**Check Volume Mounts:**
1. Go to **Containers** → container
2. Scroll to "**Volumes**" section
3. Verify mounts are correct

**Recreate Stack:**
1. Go to **Stacks** → **the-logbook**
2. Click "**Delete this stack**"
3. Redeploy following instructions above

### Performance Issues

**Check Resource Usage:**
1. Go to **Containers**
2. View CPU/Memory for each container
3. If high:
   - Increase Docker resources
   - Check for errors in logs
   - Restart containers

**Optimize:**
- Use Unraid cache drive for database
- Allocate more RAM if available
- Check for runaway processes in logs

---

## Advanced Features

### Custom Networks

**Create Isolated Network:**

1. Go to **Networks**
2. Click "**Add network**"
3. Name: `logbook_network`
4. Driver: `bridge`
5. Click "**Create network**"

Then use in stack by referencing existing network.

### Stack Templates

**Save as Template:**

1. Deploy and configure stack perfectly
2. Go to **Stacks** → **the-logbook**
3. Click "**Editor**"
4. Copy entire YAML
5. Go to **App Templates**
6. Create custom template for reuse

### Webhooks (Auto-Update)

**Enable Webhook:**

1. Go to **Stacks** → **the-logbook**
2. Scroll to "**Webhook**"
3. Enable webhook
4. Copy webhook URL
5. Use in CI/CD or GitHub Actions for auto-deploy

### Access Control

**Restrict Access:**

1. Go to **Stacks** → **the-logbook**
2. Scroll to "**Access control**"
3. Select teams/users who can manage
4. Click "**Update the stack**"

---

## Portainer Tips and Tricks

### Keyboard Shortcuts

- `?` - Show keyboard shortcuts
- `/` - Focus search
- `Esc` - Close modals

### Quick Actions

**From Container List:**
- Click container name → Full details
- Click status → Quick stats
- Click port → Open in browser

**Bulk Operations:**
- Select multiple containers (checkboxes)
- Use top buttons for bulk actions

### Favorites

**Star Important Stacks:**
1. Go to **Stacks**
2. Click star icon next to stack name
3. Favorites appear at top

### Notifications

**Enable Notifications:**
1. Go to **Settings** → **Notifications**
2. Configure webhooks for:
   - Container stopped
   - Stack update
   - Health check failed

---

## Comparison: Portainer vs Docker Compose Manager

| Feature | Portainer | Docker Compose Manager |
|---------|-----------|------------------------|
| **Interface** | Modern web UI | Simpler interface |
| **Learning Curve** | Easy | Very easy |
| **Features** | Extensive | Basic |
| **Resource Usage** | Higher | Lower |
| **Multi-Host** | Yes | No |
| **Templates** | Yes | Limited |
| **Console Access** | Built-in | Via Docker |
| **Log Management** | Advanced | Basic |
| **Best For** | Power users | Simplicity |

**Recommendation:**
- **Use Portainer** if you: Manage multiple stacks, want advanced features, prefer rich UI
- **Use Docker Compose Manager** if you: Want simplicity, minimal resource usage, basic management

---

## Additional Resources

- **Portainer Documentation**: https://docs.portainer.io/
- **The Logbook Main Guide**: [README.md](../README.md)
- **Unraid Guide**: [docs/UNRAID.md](../docs/UNRAID.md)
- **Docker Compose Guide**: [unraid/COMPOSE_INSTALL.md](COMPOSE_INSTALL.md)
- **Scripts Guide**: [scripts/README.md](../scripts/README.md)

---

## Quick Reference

### Essential Portainer Locations

- **Access**: `http://your-server-ip:9000`
- **Stacks**: Manage The Logbook deployment
- **Containers**: Individual container control
- **Volumes**: Data persistence
- **Networks**: Container networking
- **Logs**: Real-time and historical logs
- **Console**: Shell access to containers

### Essential Commands (In Container Console)

```bash
# Create admin user
python manage.py createsuperuser

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Django shell
python manage.py shell

# Check application health
python manage.py check

# Run backup (if scripts mounted)
./scripts/backup.sh
```

---

**Need Help?** Open an issue on [GitHub](https://github.com/thegspiro/The-Logbook-v2/issues)

**Stay Safe! 🔥🚒**
