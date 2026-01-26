# The Logbook - Unraid Deployment Files

This directory contains Unraid-specific deployment files and templates for easy installation.

## What's Included

### 📄 docker-compose.unraid.yml
**Unraid-optimized Docker Compose file**

Differences from the standard `docker-compose.yml`:
- ✅ Uses Unraid-specific paths (`/mnt/user/appdata/`)
- ✅ Maps volumes directly to array (no Docker volumes)
- ✅ Includes Unraid Docker labels for integration
- ✅ Optimized for Unraid cache/array architecture
- ✅ Compatible with Docker Compose Manager plugin
- ✅ Includes Unraid notification support

**Usage:**
```bash
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

---

### 🔧 .env.unraid.example
**Unraid-specific environment configuration template**

Features:
- Pre-configured with Unraid default paths
- Includes Unraid-specific settings
- Optimized for Unraid share structure
- Comments explain each option
- Backup and notification settings included

**Setup:**
```bash
cp unraid/.env.unraid.example .env
nano .env  # Edit with your settings
```

---

### 📋 logbook-template.xml
**Unraid Community Applications template**

This XML file allows The Logbook to be added to Unraid's Community Applications store.

**Features:**
- Pre-configured ports and paths
- User-friendly variable names
- Automatic WebUI integration
- Icon and description included
- Category: Productivity/Tools

**Note:** This template is for future Community Applications submission. For now, use Docker Compose Manager for installation.

---

### 📘 COMPOSE_INSTALL.md
**Complete installation guide for Unraid**

Comprehensive step-by-step guide covering:
- Docker Compose Manager installation
- Command-line installation
- Post-installation configuration
- Automated backup setup
- Health check automation
- Troubleshooting
- Management commands
- Quick reference

---

## Installation Quick Start

### Method 1: Automated Script (Easiest)

```bash
# SSH into Unraid
ssh root@your-unraid-ip

# Clone repository
cd /mnt/user/appdata
git clone https://github.com/thegspiro/The-Logbook-v2.git
cd The-Logbook-v2

# Run setup
chmod +x scripts/unraid-setup.sh
./scripts/unraid-setup.sh
```

### Method 2: Docker Compose Manager (Recommended)

1. **Install Docker Compose Manager** from Community Applications

2. **Clone and Configure**:
   ```bash
   cd /mnt/user/appdata
   git clone https://github.com/thegspiro/The-Logbook-v2.git
   cd The-Logbook-v2
   cp unraid/.env.unraid.example .env
   nano .env  # Edit configuration
   ```

3. **Deploy in Compose Manager**:
   - Open Docker Compose Manager in Unraid
   - Add New Stack: `logbook`
   - Compose file: `/mnt/user/appdata/The-Logbook-v2/unraid/docker-compose.unraid.yml`
   - Click "Compose Up"

4. **Complete Setup**:
   - Access: `http://your-unraid-ip`
   - Follow onboarding wizard

See [COMPOSE_INSTALL.md](COMPOSE_INSTALL.md) for detailed instructions.

---

## Key Differences: Standard vs Unraid

| Feature | Standard | Unraid Version |
|---------|----------|----------------|
| **Volumes** | Docker volumes | Direct path mapping |
| **Paths** | `/app`, `/var/lib/postgresql` | `/mnt/user/appdata/logbook/*` |
| **Compose File** | `docker-compose.yml` | `unraid/docker-compose.unraid.yml` |
| **Environment** | `.env.example` | `unraid/.env.unraid.example` |
| **Storage** | Docker managed | Unraid array/cache |
| **Integration** | Generic | Unraid labels & WebUI |
| **Backups** | Manual paths | `/mnt/user/backups/logbook` |

---

## File Structure After Installation

```
/mnt/user/appdata/
└── The-Logbook-v2/              # Git repository
    ├── unraid/                  # This directory
    │   ├── docker-compose.unraid.yml
    │   ├── .env.unraid.example
    │   ├── logbook-template.xml
    │   └── COMPOSE_INSTALL.md
    ├── .env                     # Your configuration
    └── ...

/mnt/user/appdata/logbook/       # Application data
├── app/                         # Django application
├── database/                    # PostgreSQL data
├── media/                       # User uploads
└── static/                      # CSS/JS/Images

/mnt/user/backups/logbook/       # Automated backups
├── logbook_backup_20240124/
├── logbook_backup_20240125/
└── latest -> logbook_backup_20240125/
```

---

## Configuration for Unraid

### Recommended Settings

```bash
# .env file for Unraid

# Use Unraid server IP
DJANGO_ALLOWED_HOSTS=192.168.1.100,tower.local

# Default ports (change if in use)
HTTP_PORT=80
HTTPS_PORT=443

# Local storage (uses Unraid array)
DEFAULT_STORAGE_BACKEND=local

# Backup to Unraid user share
BACKUP_DIR=/mnt/user/backups/logbook
RETENTION_DAYS=30

# Timezone
TZ=America/New_York
```

### Cache vs Array Storage

**Recommended (Default)**:
```
/mnt/user/appdata/logbook/
```
- Uses cache if available (fast)
- Falls back to array if cache full
- Protected by parity
- Best balance of speed and safety

**Cache-Only**:
```
/mnt/cache/appdata/logbook/
```
- Fastest performance
- NOT protected by parity
- Use only if you have frequent backups

**Array-Only**:
```
/mnt/disk1/appdata/logbook/
```
- Slower performance
- Protected by parity
- Maximum data safety
- Use for critical data

To change: Edit volume paths in `docker-compose.unraid.yml`

---

## Automated Maintenance

### Backup Automation

Create a User Script:

**Name**: `Logbook Daily Backup`
**Schedule**: Daily at 2:00 AM

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh

# Send notification
if [ $? -eq 0 ]; then
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Backup Complete" \
        -d "$(du -sh /mnt/user/backups/logbook/latest | cut -f1) backed up" \
        -i "normal"
fi
```

### Health Check Automation

**Name**: `Logbook Health Check`
**Schedule**: Weekly on Sunday at 3:00 AM

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
docker-compose -f unraid/docker-compose.unraid.yml exec -T onboarding python manage.py check

if [ $? -ne 0 ]; then
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Health Check Failed" \
        -d "Check application logs immediately" \
        -i "alert"
fi
```

### Update Automation

**Name**: `Logbook Monthly Update`
**Schedule**: Monthly on 1st at 1:00 AM

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/update.sh 2>&1 | tee /tmp/logbook-update.log

# Check if update was successful
if grep -q "Update Completed Successfully" /tmp/logbook-update.log; then
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Updated" \
        -d "Successfully updated to latest version" \
        -i "normal"
else
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Update Failed" \
        -d "Check logs: /tmp/logbook-update.log" \
        -i "alert"
fi
```

---

## Integration with Unraid Features

### Dashboard WebUI Icon

After deployment, add WebUI to Docker page:

1. Go to **Docker** tab
2. Find `logbook_nginx` container
3. Click **Edit**
4. Set **WebUI**: `http://[IP]:[PORT:80]`
5. Choose an icon or use default
6. Click **Apply**

### VPN Integration

To route The Logbook through a VPN container:

Edit `docker-compose.unraid.yml`:

```yaml
services:
  onboarding:
    network_mode: "container:vpn_container_name"
    # Remove ports section when using container network mode
```

### Reverse Proxy Integration

**With Nginx Proxy Manager**:
1. Add Proxy Host
2. Domain: `logbook.yourdomain.com`
3. Forward to: `logbook_nginx` / Port `80`
4. Enable SSL with Let's Encrypt

**With Swag**:
1. Create subdomain config
2. Point to `logbook_nginx:80`
3. Enable SSL

---

## Upgrading from Standard to Unraid Version

If you're using the standard `docker-compose.yml` and want to switch:

### 1. Backup Current Installation

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh
```

### 2. Stop Current Stack

```bash
docker-compose down
```

### 3. Configure Unraid Environment

```bash
cp unraid/.env.unraid.example .env
# Copy your existing settings to new .env
```

### 4. Deploy Unraid Stack

```bash
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

### 5. Migrate Data (if needed)

If switching from Docker volumes to direct paths:

```bash
# Copy database
docker run --rm \
  -v logbook_postgres_data:/source \
  -v /mnt/user/appdata/logbook/database:/dest \
  alpine sh -c "cp -r /source/* /dest/"

# Copy media
docker run --rm \
  -v logbook_media_volume:/source \
  -v /mnt/user/appdata/logbook/media:/dest \
  alpine sh -c "cp -r /source/* /dest/"
```

---

## Troubleshooting Unraid-Specific Issues

### "Cannot find docker-compose.yml"

You're in the wrong directory:

```bash
cd /mnt/user/appdata/The-Logbook-v2
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

### "Permission denied" on appdata

Fix permissions:

```bash
chown -R nobody:users /mnt/user/appdata/logbook
chmod -R 755 /mnt/user/appdata/logbook
```

### Ports Already in Use

Check what's using the port:

```bash
netstat -tuln | grep :80
```

Change ports in `.env`:

```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```

### Out of Space on Cache Drive

Move to array:

```bash
# Stop containers
docker-compose -f unraid/docker-compose.unraid.yml down

# Move data
mv /mnt/cache/appdata/logbook /mnt/user/appdata/logbook

# Start containers
docker-compose -f unraid/docker-compose.unraid.yml up -d
```

### Docker Compose Manager Not Found

Install from Community Applications:
1. **Apps** → **Community Applications**
2. Search: "Docker Compose Manager"
3. Click **Install**

---

## Additional Resources

- **[Main README](../README.md)** - Project overview and features
- **[Deployment Guide](../DEPLOYMENT.md)** - General deployment info
- **[Unraid Guide](../docs/UNRAID.md)** - Comprehensive Unraid documentation
- **[Scripts Documentation](../scripts/README.md)** - Backup, update, restore scripts
- **[Compose Install Guide](COMPOSE_INSTALL.md)** - Detailed installation steps

---

## Community Applications Submission

This template is being prepared for submission to Unraid Community Applications. Once approved, you'll be able to install The Logbook directly from the Apps page with one click!

**Current Status**: In development
**Estimated Availability**: After initial testing and refinement

---

## Support

**Found an issue?** [Report it on GitHub](https://github.com/thegspiro/The-Logbook-v2/issues)

**Need help?** Check the [Unraid Guide](../docs/UNRAID.md) or ask in [Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)

**Want to contribute?** See [Contributing Guidelines](../README.md#contributing)

---

**Built for the firefighting community by the firefighting community. Stay Safe! 🔥🚒**
