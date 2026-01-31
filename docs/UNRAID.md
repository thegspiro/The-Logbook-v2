# The Logbook - Unraid Deployment Guide

This guide covers deploying The Logbook on Unraid servers, including installation, configuration, backups, and maintenance.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Initial Setup](#initial-setup)
4. [Configuration](#configuration)
5. [Backups](#backups)
6. [Updates](#updates)
7. [Monitoring](#monitoring)
8. [Troubleshooting](#troubleshooting)
9. [Unraid-Specific Tips](#unraid-specific-tips)

---

## Prerequisites

### System Requirements

- **Unraid Version**: 6.9 or newer
- **RAM**: Minimum 2GB available
- **Storage**: Minimum 5GB free space (10GB+ recommended)
- **CPU**: Any modern x64 processor

### Required Unraid Apps/Plugins

Install from Community Applications:

1. **Docker Compose Manager** (recommended) OR **Portainer**
2. **User Scripts** (optional, for automated backups)
3. **CA Backup/Restore Appdata** (optional, additional backup solution)

### Network Configuration

The Logbook requires the following ports:

- **80** (HTTP) - Web interface
- **443** (HTTPS) - Secure web interface (optional)
- **5432** (PostgreSQL) - Database (internal only)
- **8000** (Django) - Application server (internal only)

If these ports are already in use, you can modify them in `docker-compose.yml`.

---

## Installation Methods

### Method 1: Automated Script (Recommended for Beginners)

The easiest way to get started:

1. **Access Unraid Terminal**
   - Via SSH: `ssh root@your-unraid-ip`
   - Or use the Unraid web terminal

2. **Navigate to your apps directory**
   ```bash
   cd /mnt/user/appdata
   ```

3. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/The-Logbook-v2.git
   cd The-Logbook-v2
   ```

4. **Run the setup script**
   ```bash
   chmod +x scripts/unraid-setup.sh
   ./scripts/unraid-setup.sh
   ```

5. **Follow the prompts** to configure your installation

The script will:
- Check system requirements
- Generate secure credentials
- Configure environment variables
- Deploy Docker containers
- Run database migrations
- Provide next steps

### Method 2: Docker Compose Manager Plugin

For users who prefer a GUI:

1. **Install Docker Compose Manager** from Community Applications

2. **Clone the repository**
   ```bash
   cd /mnt/user/appdata
   git clone https://github.com/yourusername/The-Logbook-v2.git
   ```

3. **Create environment file**
   ```bash
   cd The-Logbook-v2
   cp .env.example .env
   nano .env  # Edit with your settings
   ```

4. **Open Docker Compose Manager** in Unraid UI

5. **Add new stack**:
   - Name: `the-logbook`
   - Compose file: `/mnt/user/appdata/The-Logbook-v2/docker-compose.yml`
   - Click "Compose Up"

### Method 3: Portainer

Using Portainer for container management:

1. **Install Portainer** from Community Applications

2. **Clone the repository** (same as above)

3. **Configure .env file** (same as above)

4. **In Portainer**:
   - Go to "Stacks"
   - Click "Add stack"
   - Name: `the-logbook`
   - Upload `docker-compose.yml` or paste its contents
   - Add environment variables from `.env`
   - Deploy

### Method 4: Individual Docker Containers

For advanced users who want granular control:

See `docs/MANUAL_DOCKER.md` for detailed instructions on deploying each container separately via Unraid's Docker interface.

---

## Initial Setup

### 1. Access the Onboarding Wizard

After deployment, access the application:

```
http://your-unraid-ip
```

or

```
http://tower.local  # If using Unraid default hostname
```

### 2. Complete 8-Step Onboarding

The wizard will guide you through:

**Step 1: Organization Setup**
- Fire department name
- Primary and secondary colors (hex codes)
- Logo upload (optional)

**Step 2: Email Configuration**
- SMTP server details
- Email credentials (encrypted)
- Test email functionality

**Step 3: Security Settings**
- Session timeout (recommended: 60 minutes)
- Password requirements (min 12 characters)
- Two-factor authentication (optional)
- Allowed email domains

**Step 4: File Storage**
- **Local Storage** (recommended for Unraid)
  - Files stored in Docker volumes
  - Backed up with Unraid's array
- **AWS S3** (optional)
  - Scalable cloud storage
  - Requires AWS credentials

**Step 5: External Integrations** (future)
- Placeholder for external services
- API connections

**Step 6: User Roles**
- Review permission levels
- Configure default roles

**Step 7: Preferences**
- Time zone
- Date/time formats
- Notification settings

**Step 8: Review & Complete**
- Verify all settings
- Complete setup

### 3. Create Admin Account

After onboarding:

```bash
docker-compose exec onboarding python manage.py createsuperuser
```

Follow the prompts to create your first admin user.

### 4. Access Admin Panel

Navigate to:
```
http://your-unraid-ip/admin
```

Login with your admin credentials.

---

## Configuration

### Environment Variables

Key settings in `.env`:

```bash
# Django Settings
DJANGO_SECRET_KEY=<generated-secret-key>
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=192.168.1.100,tower.local,localhost

# Database
POSTGRES_DB=logbook_db
POSTGRES_USER=logbook_user
POSTGRES_PASSWORD=<strong-password>

# Theme
PRIMARY_COLOR=#DC2626
SECONDARY_COLOR=#1F2937

# Application
APP_NAME=The Logbook
```

### Customizing Ports

If ports 80/443 are in use, edit `docker-compose.yml`:

```yaml
services:
  nginx:
    ports:
      - "8080:80"    # Change to 8080 instead of 80
      - "8443:443"   # Change to 8443 instead of 443
```

### Persistent Storage

The Logbook uses Docker volumes for data persistence:

- `logbook_postgres_data` - Database files
- `logbook_media_volume` - User uploads
- `logbook_static_volume` - CSS/JS assets

These volumes are stored in `/mnt/user/appdata/docker/volumes/`

### Unraid Array Mapping

To map volumes to the Unraid array instead:

Edit `docker-compose.yml`:

```yaml
volumes:
  postgres_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/user/appdata/logbook/database

  media_volume:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/user/appdata/logbook/media
```

---

## Backups

### Automated Backup Script

The Logbook includes a comprehensive backup script.

#### Setup Automated Backups with User Scripts

1. **Install User Scripts** plugin

2. **Create new script** in Unraid UI:
   - Name: `Backup The Logbook`
   - Schedule: Daily at 2:00 AM

3. **Add script content**:
   ```bash
   #!/bin/bash
   cd /mnt/user/appdata/The-Logbook-v2
   ./scripts/backup.sh
   ```

4. **Save and enable**

#### Manual Backup

Run anytime:

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh
```

Backups are saved to: `/mnt/user/backups/logbook/`

#### Backup Contents

Each backup includes:
- PostgreSQL database dump (compressed)
- Media files (user uploads)
- Static files
- Configuration files (sanitized)
- Restore instructions

#### Retention Policy

By default, backups older than 30 days are automatically deleted.

Change retention:
```bash
RETENTION_DAYS=7 ./scripts/backup.sh
```

### Restoring from Backup

1. **Stop containers**:
   ```bash
   docker-compose down
   ```

2. **Restore database**:
   ```bash
   gunzip -c /mnt/user/backups/logbook/latest/database.sql.gz | \
     docker-compose exec -T db psql -U logbook_user logbook_db
   ```

3. **Restore media**:
   ```bash
   docker run --rm \
     -v logbook_media_volume:/data \
     -v /mnt/user/backups/logbook/latest:/backup \
     alpine tar xzf /backup/media.tar.gz -C /data
   ```

4. **Restart**:
   ```bash
   docker-compose up -d
   ```

### Unraid-Specific Backup Options

#### CA Backup/Restore Appdata

The Logbook's appdata is compatible with Unraid's backup plugin:

1. Install **CA Backup/Restore Appdata**
2. Add `/mnt/user/appdata/The-Logbook-v2` to backup list
3. Configure schedule

#### Flash Drive Backup

For critical configuration:

```bash
cp /mnt/user/appdata/The-Logbook-v2/.env /boot/config/logbook-env.backup
```

---

## Updates

### Automated Update Script

The Logbook includes a safe update script.

#### Running Updates

```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/update.sh
```

The script will:
1. Create pre-update backup
2. Pull latest code
3. Rebuild containers
4. Run migrations
5. Restart services
6. Verify health

#### Update Schedule

Recommended update frequency:
- **Security updates**: Immediately
- **Feature updates**: Monthly
- **Major versions**: As needed (review changelog)

### Manual Updates

If you prefer manual control:

```bash
cd /mnt/user/appdata/The-Logbook-v2

# Backup first
./scripts/backup.sh

# Pull updates
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build

# Run migrations
docker-compose exec onboarding python manage.py migrate
docker-compose exec onboarding python manage.py collectstatic --noinput
```

---

## Monitoring

### Container Status

Check if containers are running:

```bash
docker-compose ps
```

Expected output:
```
NAME                    STATUS
logbook_db              Up (healthy)
logbook_onboarding      Up
logbook_nginx           Up
```

### View Logs

Real-time logs:
```bash
docker-compose logs -f
```

Specific service:
```bash
docker-compose logs -f onboarding  # Application
docker-compose logs -f db          # Database
docker-compose logs -f nginx       # Web server
```

### Resource Usage

Monitor resource consumption:

```bash
docker stats logbook_onboarding logbook_db logbook_nginx
```

### Health Checks

Database health:
```bash
docker-compose exec onboarding python manage.py check --database default
```

Application health:
```bash
docker-compose exec onboarding python manage.py check
```

### Unraid Dashboard

To add The Logbook to your Unraid dashboard:

1. Go to **Settings** → **Docker**
2. Find The Logbook containers
3. Click on the container icon
4. Select **Edit**
5. Set **WebUI**: `http://[IP]:[PORT:80]`

---

## Troubleshooting

### Containers Won't Start

**Check logs**:
```bash
docker-compose logs
```

**Common causes**:
- Port conflicts: Change ports in `docker-compose.yml`
- Insufficient resources: Check RAM/disk space
- Docker network issues: Restart Docker service

**Solution**:
```bash
docker-compose down
docker network prune -f
docker-compose up -d
```

### Can't Access Web Interface

**Verify containers are running**:
```bash
docker-compose ps
```

**Check firewall**:
- Ensure Unraid firewall allows port 80
- Check router port forwarding if accessing remotely

**Check allowed hosts**:
```bash
# Edit .env
DJANGO_ALLOWED_HOSTS=192.168.1.100,tower.local,localhost,*
```

### Database Connection Errors

**Check database is healthy**:
```bash
docker-compose exec db pg_isready -U logbook_user
```

**Verify credentials**:
```bash
# Ensure .env matches docker-compose.yml
cat .env | grep POSTGRES
```

**Restart database**:
```bash
docker-compose restart db
```

### Static Files Not Loading

**Collect static files**:
```bash
docker-compose exec onboarding python manage.py collectstatic --noinput
```

**Check nginx configuration**:
```bash
docker-compose exec nginx nginx -t
```

### Out of Disk Space

**Check Docker volumes**:
```bash
docker system df
```

**Clean up unused resources**:
```bash
docker system prune -a --volumes
```

**Move to larger disk** (see Configuration section)

---

## Unraid-Specific Tips

### Best Practices

1. **Store appdata on cache drive** for better performance
   - Appdata path: `/mnt/cache/appdata/The-Logbook-v2`

2. **Store backups on array** for redundancy
   - Backup path: `/mnt/user/backups/logbook/`

3. **Use Unraid notifications** to monitor containers
   - Install Community Applications → Notifications Agent

4. **Enable Docker log rotation**
   - Settings → Docker → Enable log rotation

### Performance Optimization

**For cache drives (SSD)**:
- Store appdata on cache
- Use `preferscache` for media uploads

**For arrays (HDD)**:
- Store backups on array
- Use `preferarray` share settings

**Memory**:
- Allocate 2GB minimum
- 4GB recommended for larger departments

### Integration with Unraid Features

**VPN Integration**:
If using a VPN container, you can route The Logbook through it:

```yaml
network_mode: "container:vpn_container_name"
```

**Reverse Proxy**:
Use Nginx Proxy Manager or Swag for:
- SSL/TLS certificates
- Custom domains
- Multiple applications

**Notifications**:
Configure The Logbook to use Unraid's notification system for alerts.

### Security on Unraid

**Firewall**:
- Enable Unraid firewall
- Only allow necessary ports
- Use VPN for remote access

**User Access**:
- Don't expose to internet directly
- Use VPN or Cloudflare Tunnel
- Enable 2FA in The Logbook

**Backups**:
- Schedule regular backups
- Test restore procedure
- Keep offsite backups

---

## Support

### Resources

- **Main Documentation**: [README.md](../README.md)
- **Deployment Guide**: [DEPLOYMENT.md](../DEPLOYMENT.md)
- **GitHub Issues**: [Report bugs](https://github.com/yourusername/The-Logbook-v2/issues)
- **Unraid Forums**: [Community support](https://forums.unraid.net)

### Getting Help

When requesting help, include:

1. **Unraid version**: `uname -a`
2. **Docker version**: `docker --version`
3. **Container logs**: `docker-compose logs`
4. **Error messages**: Full text
5. **Steps to reproduce**: What you did

---

## Quick Reference

### Essential Commands

```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# View logs
docker-compose logs -f

# Restart
docker-compose restart

# Backup
./scripts/backup.sh

# Update
./scripts/update.sh

# Create admin user
docker-compose exec onboarding python manage.py createsuperuser

# Database migrations
docker-compose exec onboarding python manage.py migrate

# Collect static files
docker-compose exec onboarding python manage.py collectstatic --noinput

# Shell access
docker-compose exec onboarding /bin/bash
```

### File Locations

- **Application**: `/mnt/user/appdata/The-Logbook-v2`
- **Backups**: `/mnt/user/backups/logbook/`
- **Docker volumes**: `/mnt/user/appdata/docker/volumes/logbook_*`
- **Logs**: `docker-compose logs` (in-memory)

---

**Happy logging! Stay safe out there!** 🔥🚒
