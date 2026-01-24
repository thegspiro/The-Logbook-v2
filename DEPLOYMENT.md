# Deployment Guide for The Logbook

This guide provides detailed instructions for deploying The Logbook in various environments.

## Table of Contents

1. [Production Deployment](#production-deployment)
2. [Unraid Deployment](#unraid-deployment)
3. [SSL/HTTPS Configuration](#ssl-https-configuration)
4. [Performance Optimization](#performance-optimization)
5. [Monitoring and Maintenance](#monitoring-and-maintenance)

## Production Deployment

### Prerequisites

- Linux server (Ubuntu 20.04+ or similar recommended)
- Docker Engine 20.10+
- Docker Compose 2.0+
- Domain name pointed to your server (for SSL)
- Minimum 2GB RAM, 10GB storage

### Step 1: Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Step 2: Clone and Configure

```bash
# Clone repository
git clone https://github.com/yourusername/The-Logbook-v2.git
cd The-Logbook-v2

# Create environment file
cp .env.example .env
nano .env
```

**Critical .env settings for production:**

```bash
# Security - CHANGE THESE!
DJANGO_SECRET_KEY=<generate-a-random-secret-key>
POSTGRES_PASSWORD=<strong-database-password>

# Production settings
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# SSL/HTTPS (when configured)
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

# Email (use real SMTP server)
EMAIL_HOST=smtp.yourdomain.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=noreply@yourdomain.com
EMAIL_HOST_PASSWORD=<email-password>
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### Step 3: Generate Secret Key

```bash
python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

Copy the output and paste it as `DJANGO_SECRET_KEY` in your `.env` file.

### Step 4: Deploy

```bash
# Build and start containers
docker-compose up -d --build

# Wait for services to be ready
docker-compose logs -f onboarding

# Create database migrations
docker-compose exec onboarding python manage.py makemigrations
docker-compose exec onboarding python manage.py migrate

# Create superuser
docker-compose exec onboarding python manage.py createsuperuser

# Collect static files
docker-compose exec onboarding python manage.py collectstatic --noinput
```

### Step 5: Verify Deployment

```bash
# Check container status
docker-compose ps

# All containers should show "Up" status
# Test the application
curl http://localhost
```

## Unraid Deployment

### Method 1: Docker Compose Manager

1. **Install Docker Compose Manager:**
   - Open Unraid web interface
   - Go to Apps > Search for "Docker Compose Manager"
   - Install the plugin

2. **Create Stack:**
   - Navigate to Docker Compose Manager
   - Click "Add New Stack"
   - Name: `the-logbook`
   - Paste contents of `docker-compose.yml`

3. **Configure Environment:**
   - Create a file at `/mnt/user/appdata/the-logbook/.env`
   - Copy `.env.example` and modify values
   - Set correct paths for Unraid

4. **Start Stack:**
   - Click "Compose Up"
   - Monitor logs in the interface

### Method 2: Portainer

1. **Install Portainer:**
   - Install from Unraid Community Applications

2. **Create Stack:**
   - Open Portainer web interface
   - Go to Stacks > Add Stack
   - Upload `docker-compose.yml`
   - Add environment variables
   - Deploy

### Method 3: Individual Docker Containers

Create three containers manually through Unraid Docker interface:

**PostgreSQL Container:**
- Repository: `postgres:16-alpine`
- Network Type: Custom (logbook_network)
- Add volume: `/mnt/user/appdata/the-logbook/postgres` → `/var/lib/postgresql/data`
- Add variables from `.env` (POSTGRES_*)

**Onboarding Container:**
- Build from Dockerfile or use pre-built image
- Network Type: Custom (logbook_network)
- Add volume: `/mnt/user/appdata/the-logbook/app` → `/app`
- Add volumes for static/media
- Add all Django environment variables

**Nginx Container:**
- Repository: `nginx:alpine`
- Port: 80 → 80, 443 → 443
- Network Type: Custom (logbook_network)
- Add volume: `/mnt/user/appdata/the-logbook/nginx.conf` → `/etc/nginx/nginx.conf`

## SSL/HTTPS Configuration

### Option 1: Let's Encrypt with Certbot

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com

# Certificates will be in /etc/letsencrypt/live/yourdomain.com/
```

### Option 2: Manual Certificate

If you have your own SSL certificate:

```bash
# Create ssl directory
mkdir -p ./nginx/ssl

# Copy your certificates
cp your-cert.pem ./nginx/ssl/cert.pem
cp your-key.pem ./nginx/ssl/key.pem
```

### Update Nginx Configuration

Edit `nginx/nginx.conf` and uncomment the SSL server block:

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # ... rest of configuration
}
```

### Update docker-compose.yml

Add SSL certificate volumes:

```yaml
nginx:
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./nginx/ssl:/etc/nginx/ssl:ro  # Add this line
    - static_volume:/static
    - media_volume:/media
```

### Update .env for HTTPS

```bash
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### Restart Services

```bash
docker-compose down
docker-compose up -d
```

## Performance Optimization

### 1. Database Performance

**Increase PostgreSQL memory:**

Add to `docker-compose.yml` under `db` service:

```yaml
db:
  command: postgres -c shared_buffers=256MB -c max_connections=200
```

**Regular maintenance:**

```bash
# Vacuum and analyze
docker-compose exec db psql -U logbook_user -d logbook_db -c "VACUUM ANALYZE;"

# Reindex
docker-compose exec db psql -U logbook_user -d logbook_db -c "REINDEX DATABASE logbook_db;"
```

### 2. Application Performance

**Increase Gunicorn workers:**

Edit `services/onboarding/Dockerfile`:

```dockerfile
CMD python manage.py migrate && \
    gunicorn onboarding_project.wsgi:application --bind 0.0.0.0:8000 --workers 5 --threads 2
```

**Enable caching** (add to settings.py):

```python
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
    }
}
```

Then add Redis to `docker-compose.yml`:

```yaml
redis:
  image: redis:alpine
  restart: unless-stopped
```

### 3. Static File Serving

For production, consider using a CDN or object storage for static files.

Configure S3 for static files in settings.py:

```python
if STORAGE_BACKEND == 's3':
    STATICFILES_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
```

## Monitoring and Maintenance

### Health Checks

Test application health:

```bash
curl http://localhost/health/
```

### Log Management

**View real-time logs:**

```bash
docker-compose logs -f --tail=100 onboarding
```

**Log rotation** (add to docker-compose.yml):

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Automated Backups

Create a backup script (`backup.sh`):

```bash
#!/bin/bash

BACKUP_DIR="/backups/logbook"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker-compose exec -T db pg_dump -U logbook_user logbook_db | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Backup media files
docker run --rm -v logbook_media_volume:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/media_$DATE.tar.gz /data

# Delete backups older than 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Make executable and add to cron:

```bash
chmod +x backup.sh
crontab -e
# Add line:
0 2 * * * /path/to/backup.sh >> /var/log/logbook_backup.log 2>&1
```

### Monitoring with Prometheus (Optional)

Add monitoring stack to `docker-compose.yml`:

```yaml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  depends_on:
    - prometheus
```

### Security Scanning

Regular security checks:

```bash
# Update dependencies
docker-compose exec onboarding pip list --outdated

# Check for vulnerabilities
docker-compose exec onboarding pip-audit
```

### Updates

Check for updates regularly:

```bash
cd The-Logbook-v2
git fetch
git pull origin main
docker-compose down
docker-compose up -d --build
docker-compose exec onboarding python manage.py migrate
```

## Firewall Configuration

Configure UFW (Ubuntu):

```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

## Troubleshooting Production Issues

### High CPU Usage

```bash
# Check container stats
docker stats

# Identify slow queries
docker-compose exec db psql -U logbook_user -d logbook_db -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

### Memory Issues

```bash
# Check memory usage
docker-compose exec onboarding free -h

# Restart services if needed
docker-compose restart onboarding
```

### Database Connection Pool Exhausted

Increase max_connections in PostgreSQL or reduce connection usage in Django settings.

## Production Checklist

Before going live:

- [ ] Changed DJANGO_SECRET_KEY
- [ ] Changed POSTGRES_PASSWORD
- [ ] Set DJANGO_DEBUG=False
- [ ] Configured DJANGO_ALLOWED_HOSTS
- [ ] SSL/HTTPS configured
- [ ] Email working correctly
- [ ] Backups configured and tested
- [ ] Firewall configured
- [ ] Created superuser account
- [ ] Tested all onboarding steps
- [ ] Monitoring set up
- [ ] Log rotation configured
- [ ] Security headers verified
- [ ] Performance tested under load

## Support

For deployment issues:
- Check logs: `docker-compose logs`
- Review [Troubleshooting Guide](README.md#troubleshooting)
- Open an issue on GitHub

---

**Good luck with your deployment!**
