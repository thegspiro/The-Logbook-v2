#!/bin/bash
################################################################################
# The Logbook - Wiki Migration Script
#
# This script automatically migrates all documentation to the GitHub Wiki
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       The Logbook - GitHub Wiki Migration Script          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main script
print_header

# Get directories
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI_DIR="../The-Logbook-v2.wiki"

echo ""
print_info "Repository directory: $REPO_DIR"
print_info "Wiki directory: $WIKI_DIR"
echo ""

# Check if wiki is cloned
if [ ! -d "$WIKI_DIR" ]; then
    print_warning "Wiki repository not found locally"
    echo ""
    print_info "You need to clone the wiki repository first:"
    echo ""
    echo "1. Enable wiki on GitHub (if not already enabled):"
    echo "   - Go to https://github.com/thegspiro/The-Logbook-v2/settings"
    echo "   - Check 'Wikis' under Features"
    echo ""
    echo "2. Create the first page (if wiki is empty):"
    echo "   - Go to https://github.com/thegspiro/The-Logbook-v2/wiki"
    echo "   - Click 'Create the first page'"
    echo "   - Title: Home"
    echo "   - Content: Coming soon!"
    echo "   - Click 'Save Page'"
    echo ""
    echo "3. Clone the wiki repository:"
    echo "   cd .."
    echo "   git clone https://github.com/thegspiro/The-Logbook-v2.wiki.git"
    echo "   cd The-Logbook-v2"
    echo ""
    read -p "Press Enter when wiki is cloned and ready..."

    # Check again
    if [ ! -d "$WIKI_DIR" ]; then
        print_error "Wiki repository still not found. Exiting."
        exit 1
    fi
fi

print_success "Wiki repository found"

# Confirm migration
echo ""
print_warning "This will copy all documentation to the wiki repository"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Migration cancelled"
    exit 0
fi

echo ""
print_info "Starting migration..."
echo ""

# Copy wiki structure
print_info "Copying wiki structure files..."
cp "$REPO_DIR/wiki/Home.md" "$WIKI_DIR/"
cp "$REPO_DIR/wiki/_Sidebar.md" "$WIKI_DIR/"
print_success "Wiki structure copied"

# Copy deployment guides
print_info "Copying deployment guides..."
cp "$REPO_DIR/docs/RASPBERRY_PI.md" "$WIKI_DIR/Raspberry-Pi-Guide.md"
cp "$REPO_DIR/docs/UNRAID.md" "$WIKI_DIR/Unraid-Guide.md"
cp "$REPO_DIR/unraid/PORTAINER_INSTALL.md" "$WIKI_DIR/Portainer-Guide.md"
cp "$REPO_DIR/unraid/COMPOSE_INSTALL.md" "$WIKI_DIR/Docker-Compose-Deployment.md"
cp "$REPO_DIR/DEPLOYMENT.md" "$WIKI_DIR/Manual-Installation.md"
print_success "Deployment guides copied (5 files)"

# Copy quick start guides
print_info "Copying quick start guides..."
cp "$REPO_DIR/raspberry-pi/README.md" "$WIKI_DIR/Raspberry-Pi-Deployment.md"
cp "$REPO_DIR/unraid/README.md" "$WIKI_DIR/Unraid-Deployment.md"
print_success "Quick start guides copied (2 files)"

# Copy management documentation
print_info "Copying management documentation..."
cp "$REPO_DIR/scripts/README.md" "$WIKI_DIR/Backup-and-Restore.md"
print_success "Management docs copied"

# Copy main README
print_info "Copying main documentation..."
cp "$REPO_DIR/README.md" "$WIKI_DIR/Installation-Overview.md"
print_success "Main docs copied"

# Create additional pages
print_info "Creating additional wiki pages..."

# FAQ page
cat > "$WIKI_DIR/FAQ.md" <<'EOF'
# Frequently Asked Questions

## General

### What is The Logbook?
The Logbook is an open-source intranet platform designed specifically for volunteer fire departments. It provides personnel management, incident reporting, equipment tracking, training coordination, and communications tools.

### Is it really free?
Yes! The Logbook is 100% free and open-source under the MIT License. You can use it, modify it, and deploy it without any licensing costs.

### Can I customize it?
Absolutely! You can customize:
- Theme colors (primary and secondary)
- Department name and branding
- All module configurations
- Security settings
- Email templates (future)

## Deployment

### Which platform should I choose?
- **Raspberry Pi**: Best for budget-conscious departments ($35-108 one-time cost)
- **Unraid**: Best if you already have an Unraid server
- **Portainer**: Best if you want advanced GUI management
- **Cloud VPS**: Best for remote access and scalability

See our [Installation Overview](Installation-Overview) for detailed comparison.

### How much does it cost to run?
**Raspberry Pi**: $5-12/year in electricity
**Unraid**: Minimal additional cost
**Cloud VPS**: $10-50/month depending on size

### Can I run it offline?
Yes! The Logbook is designed for self-hosting and works completely offline. You control all data.

## Technical

### What are the minimum requirements?
- **RAM**: 2GB minimum (1GB possible on Raspberry Pi 3B+ with swap)
- **Storage**: 10GB minimum
- **Docker**: Version 20.10 or newer
- **Network**: Ethernet recommended (WiFi works)

See [System Requirements](System-Requirements) for details.

### Is my data secure?
Yes! The Logbook uses:
- Argon2 password hashing
- Encrypted credentials storage
- HTTPS support
- CSRF protection
- SQL injection prevention
- Session management

See [Security Best Practices](Security-Best-Practices).

### Can I backup my data?
Yes! We provide automated backup scripts that backup:
- PostgreSQL database
- User-uploaded media
- Static files
- Configuration

See [Backup and Restore](Backup-and-Restore).

## Support

### Where can I get help?
- Check the [Troubleshooting](Troubleshooting) guide
- Search [GitHub Issues](https://github.com/thegspiro/The-Logbook-v2/issues)
- Ask in [GitHub Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)
- Read platform-specific guides

### How do I report a bug?
1. Check if it's already reported in [Issues](https://github.com/thegspiro/The-Logbook-v2/issues)
2. If not, create a new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - Platform details (Pi model, Unraid version, etc.)
   - Relevant logs

### Can I contribute?
Yes! We welcome contributions. See our [Contributing Guide](Contributing).

## Updates

### How do I update The Logbook?
Use our automated update script:
```bash
cd ~/The-Logbook-v2
./scripts/update.sh
```

See [Updates and Upgrades](Updates-and-Upgrades) for details.

### Will my data be safe during updates?
Yes! The update script:
1. Creates automatic backup
2. Pulls latest code
3. Rebuilds containers
4. Runs migrations
5. Verifies health

If update fails, you can restore from the pre-update backup.

## Performance

### How many users can it handle?
Depends on hardware:
- **Pi 5 (8GB)**: 50+ users
- **Pi 4 (4GB)**: 20-50 users
- **Pi 4 (2GB)**: 10-20 users
- **Pi 3B+ (1GB)**: <10 users
- **Cloud VPS (4GB)**: 100+ users

See [Performance Tuning](Performance-Tuning).

### Why is it slow on my Raspberry Pi?
Common causes:
- Using SD card instead of SSD
- Insufficient cooling (thermal throttling)
- Not enough swap configured
- Too many Gunicorn workers

See [Performance Issues](Performance-Issues).

---

**Don't see your question?** Ask in [GitHub Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)!
EOF

# System Requirements page
cat > "$WIKI_DIR/System-Requirements.md" <<'EOF'
# System Requirements

## Raspberry Pi

### Supported Models
- ✅ Raspberry Pi 5 (all RAM variants)
- ✅ Raspberry Pi 4 (2GB, 4GB, 8GB)
- ✅ Raspberry Pi 3B+ (1GB)
- ❌ Raspberry Pi Zero (insufficient resources)
- ❌ Raspberry Pi 2 or older (outdated)

### Minimum Specs
- **RAM**: 1GB (requires 4GB swap)
- **Storage**: 64GB microSD or USB SSD
- **Network**: WiFi or Ethernet
- **Power**: Official power supply

### Recommended Specs
- **Model**: Raspberry Pi 4 (4GB) or Pi 5 (8GB)
- **RAM**: 4GB+
- **Storage**: 128-256GB USB 3.0 SSD
- **Network**: Gigabit Ethernet
- **Cooling**: Heatsink or fan
- **Power**: Official power supply with UPS

See [Raspberry Pi Guide](Raspberry-Pi-Guide) for details.

## Unraid

### Minimum Specs
- **Unraid**: Version 6.9 or newer
- **RAM**: 4GB total (2GB available for Docker)
- **Storage**: 10GB free on cache or array
- **Docker**: Built-in Unraid Docker

### Recommended Specs
- **RAM**: 8GB+ total
- **Storage**: 20GB+ on cache drive (SSD)
- **Docker**: Latest version via Unraid
- **Plugins**: Docker Compose Manager or Portainer

See [Unraid Guide](Unraid-Guide) for details.

## Cloud VPS

### Minimum Specs
- **RAM**: 2GB
- **Storage**: 20GB SSD
- **CPU**: 1 vCPU (2+ recommended)
- **Bandwidth**: 1TB/month
- **OS**: Ubuntu 22.04 LTS or Debian 11+

### Recommended Specs
- **RAM**: 4GB+
- **Storage**: 40GB SSD
- **CPU**: 2+ vCPU
- **Bandwidth**: 2TB/month
- **Backup**: Automated snapshots

### Tested Providers
- DigitalOcean (Droplets)
- Linode (Shared CPU)
- Vultr (Cloud Compute)
- Hetzner Cloud
- AWS EC2 (t3.small or larger)

## Bare Metal Server

### Minimum Specs
- **RAM**: 4GB
- **Storage**: 50GB
- **CPU**: 2 cores @ 2GHz
- **OS**: Ubuntu 22.04 LTS, Debian 11+, CentOS 8+

### Recommended Specs
- **RAM**: 8GB+
- **Storage**: 100GB SSD
- **CPU**: 4+ cores
- **Network**: Gigabit NIC
- **Redundancy**: RAID for data protection

## Software Requirements

### Required
- **Docker**: 20.10 or newer
- **Docker Compose**: 1.29 or newer
- **Git**: 2.30 or newer (for installation)

### Optional but Recommended
- **Portainer**: Latest CE version (for GUI management)
- **Nginx Proxy Manager**: For SSL/reverse proxy
- **Unattended Upgrades**: For automatic security updates

## Network Requirements

### Ports
- **80** (HTTP): Web interface
- **443** (HTTPS): Secure web interface (optional)
- **8000** (Django): Application server (internal)
- **5432** (PostgreSQL): Database (internal)

### Bandwidth
- **Minimum**: 1 Mbps upload/download
- **Recommended**: 10+ Mbps
- **With media**: 100+ Mbps recommended

### DNS (Optional)
- Domain name for HTTPS (recommended)
- Dynamic DNS if using home connection

## Browser Requirements

### Supported Browsers
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

### Not Supported
- ❌ Internet Explorer (all versions)
- ❌ Very old browsers (pre-2020)

## Storage Recommendations

### Raspberry Pi
**Option 1**: microSD Card (Budget)
- Class 10, A2 rating
- SanDisk Extreme or Samsung EVO
- 64GB minimum, 128GB recommended

**Option 2**: USB SSD (Recommended)
- USB 3.0+
- 128GB minimum, 256GB recommended
- 5-10x faster than SD card
- Much longer lifespan

### Unraid
- **Cache Drive**: SSD for appdata (recommended)
- **Array**: Parity-protected storage for backups
- **10GB+**: Application and database
- **Size based on usage**: Media and documents

### Cloud
- **SSD Only**: HDD too slow
- **20GB minimum**: OS + application
- **Scale as needed**: Add storage for growth

## Comparison

| Platform | Min RAM | Min Storage | Cost | Best For |
|----------|---------|-------------|------|----------|
| **Pi 3B+** | 1GB | 64GB | $68 | Very small (<10 users) |
| **Pi 4 (2GB)** | 2GB | 64GB | $68 | Small (10-20 users) |
| **Pi 4 (4GB)** | 4GB | 128GB | $108 | Medium (20-50 users) |
| **Pi 5 (8GB)** | 8GB | 256GB | $212 | Large (50+ users) |
| **Unraid** | 4GB | 10GB | Varies | Existing server users |
| **Cloud VPS** | 2GB | 20GB | $10-15/mo | Remote access |
| **Bare Metal** | 4GB | 50GB | $500+ | Maximum performance |

---

**Need help choosing?** See [Installation Overview](Installation-Overview) for guidance.
EOF

# Troubleshooting page
cat > "$WIKI_DIR/Troubleshooting.md" <<'EOF'
# Troubleshooting Guide

Common issues and solutions for The Logbook.

## Deployment Issues

### Containers Won't Start

**Symptoms**:
- Docker containers exit immediately
- Status shows "Exited (1)"
- Can't access web interface

**Check**:
```bash
docker-compose logs
docker-compose ps
```

**Solutions**:
1. **Port conflicts**: Change ports in `.env`
2. **Insufficient resources**: Check RAM with `free -h`
3. **Disk full**: Check with `df -h`, clean up with `docker system prune`
4. **Permissions**: Ensure user has docker access

### Database Won't Start

**Symptoms**:
- Only database container exits
- "database container exited" in logs

**Solutions**:
1. Check health: `docker-compose exec db pg_isready -U logbook_user`
2. Check logs: `docker-compose logs db`
3. Verify credentials in `.env` match
4. Restart: `docker-compose restart db`
5. Check storage: Ensure PostgreSQL has write access

See [Platform-Specific Troubleshooting](#platform-specific).

## Performance Issues

### Slow Response Times

**Raspberry Pi**:
1. Check temperature: `vcgencmd measure_temp` (should be <80°C)
2. Check throttling: `vcgencmd get_throttled`
3. Enable swap if RAM <4GB
4. Switch to SSD if using SD card
5. Add cooling (heatsink or fan)

**General**:
1. Check resources: `docker stats`
2. Reduce worker count in `.env`
3. Optimize PostgreSQL settings
4. Check network latency

See [Performance Tuning](Performance-Tuning).

### Out of Memory

**Symptoms**:
- Containers crash randomly
- "OOMKilled" in logs
- System becomes unresponsive

**Solutions**:
1. Enable swap: See [Raspberry Pi Guide](Raspberry-Pi-Guide#enable-swap)
2. Reduce memory limits in `.env`
3. Reduce worker count
4. Restart containers: `docker-compose restart`

## Network Issues

### Can't Access Web Interface

**Check**:
1. Containers running: `docker-compose ps`
2. Ports open: `sudo netstat -tuln | grep -E '80|443'`
3. Firewall: `sudo ufw status`
4. URL correct: `http://server-ip` not `https://`

**Solutions**:
1. Add IP to `DJANGO_ALLOWED_HOSTS` in `.env`
2. Open firewall ports: `sudo ufw allow 80/tcp`
3. Check nginx logs: `docker-compose logs nginx`
4. Restart stack: `docker-compose restart`

### SSL/HTTPS Not Working

**Requirements**:
- Valid domain name
- SSL certificate files
- Port 443 open

**Solutions**:
1. Verify certificate paths in nginx config
2. Check certificate validity: `openssl x509 -in cert.pem -text -noout`
3. Ensure `SESSION_COOKIE_SECURE=True` in `.env`
4. Check nginx SSL configuration

## Platform-Specific

### Raspberry Pi

**SD Card Corruption**:
- **Prevention**: Use quality SD cards, add UPS, switch to SSD
- **Recovery**: Restore from backup, reflash SD card

**Temperature Throttling**:
- **Check**: `vcgencmd measure_temp`
- **Solution**: Add heatsink/fan, improve case ventilation
- **Target**: Keep below 80°C

**Power Issues**:
- **Symptom**: Random reboots, "under-voltage" in logs
- **Solution**: Use official power supply, add UPS

See [Raspberry Pi Guide](Raspberry-Pi-Guide#troubleshooting).

### Unraid

**Docker Network Issues**:
- Restart Docker: Settings → Docker → Disable/Enable
- Recreate network: `docker network prune`

**Permission Errors**:
```bash
chown -R nobody:users /mnt/user/appdata/logbook
chmod -R 755 /mnt/user/appdata/logbook
```

**Out of Space on Cache**:
- Move to array: `mv /mnt/cache/appdata/logbook /mnt/user/appdata/logbook`

See [Unraid Guide](Unraid-Guide#troubleshooting).

### Portainer

**Stack Won't Deploy**:
- Check YAML syntax at yamllint.com
- Verify environment variables are set
- Check Portainer logs

**Can't Access Console**:
- Container must be running
- Try `/bin/sh` instead of `/bin/bash`

See [Portainer Guide](Portainer-Guide#troubleshooting).

## Data Issues

### Database Connection Errors

**Symptoms**:
- "could not connect to server" in logs
- "FATAL: password authentication failed"

**Solutions**:
1. Verify credentials:
   ```bash
   cat .env | grep POSTGRES
   ```
2. Check database is healthy:
   ```bash
   docker-compose exec db pg_isready -U logbook_user
   ```
3. Restart database:
   ```bash
   docker-compose restart db
   ```

### Lost Data

**Recovery**:
1. Stop containers: `docker-compose down`
2. Restore from backup: `./scripts/restore.sh`
3. Verify restoration
4. Restart: `docker-compose up -d`

See [Backup and Restore](Backup-and-Restore).

## Update Issues

### Update Failed

**Rollback**:
1. Stop containers: `docker-compose down`
2. Find pre-update backup: `ls -la ~/backups/logbook/`
3. Restore: `./scripts/restore.sh`
4. Start: `docker-compose up -d`

### Migration Errors

**Check**:
```bash
docker-compose logs onboarding
```

**Retry**:
```bash
docker-compose exec onboarding python manage.py migrate --fake
docker-compose exec onboarding python manage.py migrate
```

See [Updates and Upgrades](Updates-and-Upgrades).

## Getting Logs

### All Logs
```bash
docker-compose logs
```

### Specific Container
```bash
docker-compose logs onboarding
docker-compose logs db
docker-compose logs nginx
```

### Follow Logs (Real-time)
```bash
docker-compose logs -f
```

### Last 100 Lines
```bash
docker-compose logs --tail=100
```

### Save Logs to File
```bash
docker-compose logs > logbook-logs.txt
```

## When to Ask for Help

Try these first:
1. Check this troubleshooting guide
2. Search [GitHub Issues](https://github.com/thegspiro/The-Logbook-v2/issues)
3. Check platform-specific guides
4. Review logs for error messages

If still stuck:
1. Gather information:
   - Platform (Pi model, Unraid version, etc.)
   - Docker/Compose versions
   - Full error logs
   - Steps to reproduce
2. Search existing issues
3. Create new issue with all details

See [Getting Help](Getting-Help).

---

**Still having issues?** [Ask for help](Getting-Help) with full details!
EOF

print_success "Additional pages created (3 files)"

# Commit changes
cd "$WIKI_DIR"

print_info "Staging changes in wiki repository..."
git add .

print_info "Creating commit..."
git commit -m "Complete documentation migration to wiki

Migrated files:
- Wiki structure (Home, Sidebar)
- Deployment guides (5 guides)
- Quick start guides (2 guides)
- Platform-specific documentation (Raspberry Pi, Unraid, Portainer)
- Management documentation (backups, scripts)
- Main project documentation
- Additional pages (FAQ, System Requirements, Troubleshooting)

Total: 350+ pages of comprehensive documentation"

echo ""
print_warning "Ready to push to GitHub"
read -p "Push changes to GitHub wiki? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Pushing to GitHub..."
    git push origin master
    echo ""
    print_success "Wiki migration complete!"
    echo ""
    print_info "View your wiki at:"
    echo "https://github.com/thegspiro/The-Logbook-v2/wiki"
else
    print_info "Changes committed locally but not pushed"
    print_info "To push later, run:"
    echo "  cd $WIKI_DIR"
    echo "  git push origin master"
fi

echo ""
print_success "Migration script complete!"
echo ""
print_info "Next steps:"
echo "1. Visit https://github.com/thegspiro/The-Logbook-v2/wiki"
echo "2. Verify all pages appear correctly"
echo "3. Update main README.md with wiki links"
echo "4. Announce wiki to users"
echo ""
