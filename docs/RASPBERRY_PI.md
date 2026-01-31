# The Logbook - Raspberry Pi Deployment Guide

Complete guide for deploying The Logbook on Raspberry Pi single-board computers.

## Table of Contents

1. [Introduction](#introduction)
2. [Hardware Requirements](#hardware-requirements)
3. [Operating System Setup](#operating-system-setup)
4. [Installing Docker](#installing-docker)
5. [Deploying The Logbook](#deploying-the-logbook)
6. [Performance Optimization](#performance-optimization)
7. [Security Hardening](#security-hardening)
8. [Backups](#backups)
9. [Troubleshooting](#troubleshooting)
10. [Maintenance](#maintenance)

---

## Introduction

The Logbook can run on Raspberry Pi, making it an affordable and energy-efficient solution for volunteer fire departments. This guide covers deployment on Raspberry Pi 3B+, 4, and 5.

**Why Raspberry Pi?**
- 💰 **Affordable**: $35-$80 hardware cost
- ⚡ **Energy Efficient**: ~5-10W power consumption
- 🔇 **Silent**: No fans (with proper cooling)
- 📦 **Compact**: Fits anywhere in the station
- 🌍 **Always-On**: Low electricity cost (~$5-10/year)
- 🔧 **Reliable**: Solid-state storage (with SSD)

**Limitations:**
- ⚠️ Limited RAM (1-8GB depending on model)
- ⚠️ Slower CPU than x86 servers
- ⚠️ ARM architecture (different from x86)
- ⚠️ SD card wear (use SSD recommended)

---

## Hardware Requirements

### Recommended Models

| Model | RAM | CPU | Best For | Price |
|-------|-----|-----|----------|-------|
| **Raspberry Pi 5 (8GB)** | 8GB | Cortex-A76 @ 2.4GHz | Large departments (50+ users) | ~$80 |
| **Raspberry Pi 4 (4GB)** | 4GB | Cortex-A72 @ 1.8GHz | Medium departments (20-50 users) | ~$55 |
| **Raspberry Pi 4 (2GB)** | 2GB | Cortex-A72 @ 1.8GHz | Small departments (<20 users) | ~$35 |
| **Raspberry Pi 3B+** | 1GB | Cortex-A53 @ 1.4GHz | Very small departments (<10 users) | ~$35 |

**⚠️ Not Recommended:**
- Raspberry Pi Zero (insufficient resources)
- Raspberry Pi 2 or older (outdated, slow)

### Additional Hardware Needed

**Required:**
- ✅ **Power Supply**: Official Raspberry Pi power supply (15W for Pi 4, 27W for Pi 5)
- ✅ **Storage**: 64GB+ microSD card (Class 10/A1) OR 128GB+ USB SSD (recommended)
- ✅ **Ethernet Cable**: For reliable networking
- ✅ **Case**: With passive or active cooling

**Recommended:**
- 🌡️ **Heatsinks or Fan**: To prevent thermal throttling
- 💾 **USB 3.0 SSD**: 128-256GB for better performance and longevity
- 🔌 **UPS**: Small UPS for power protection
- 🌐 **Ethernet**: WiFi works but ethernet is more stable

### Storage Recommendations

**Option 1: microSD Card (Budget)**
- ✅ SanDisk Extreme (A2, V30, U3)
- ✅ Samsung EVO Plus
- ✅ Minimum: 64GB, Recommended: 128GB
- ⚠️ Lifespan: 1-3 years with regular backups
- 💰 Cost: $10-25

**Option 2: USB SSD (Recommended)**
- ✅ Any USB 3.0+ SSD (SATA or NVMe in enclosure)
- ✅ Crucial MX500, Samsung 870 EVO, etc.
- ✅ Minimum: 128GB, Recommended: 256GB+
- ✅ Lifespan: 5-10+ years
- ✅ 5-10x faster than SD card
- 💰 Cost: $25-60

**Boot from SSD Setup** (Pi 4 and 5):
1. Update bootloader to support USB boot
2. Install OS directly to SSD
3. No SD card needed!

---

## Operating System Setup

### Step 1: Download Raspberry Pi OS

**Recommended:** Raspberry Pi OS Lite (64-bit)
- Lightweight (no desktop GUI)
- More resources for The Logbook
- 64-bit for better performance

**Download:**
- Raspberry Pi Imager: https://www.raspberrypi.com/software/
- Direct: https://www.raspberrypi.com/software/operating-systems/

### Step 2: Flash OS to Storage

**Using Raspberry Pi Imager:**

1. **Launch Raspberry Pi Imager**

2. **Choose OS:**
   - Raspberry Pi OS (other)
   - Raspberry Pi OS Lite (64-bit)

3. **Choose Storage:**
   - Select your microSD card or USB SSD

4. **Configure Settings** (click gear icon):
   - ✅ Enable SSH
   - ✅ Set username: `pi` (or custom)
   - ✅ Set password: (strong password)
   - ✅ Configure WiFi (if not using ethernet)
   - ✅ Set timezone
   - ✅ Set hostname: `logbook` (or custom)

5. **Write** and wait for completion

### Step 3: First Boot

1. **Insert storage** into Raspberry Pi
2. **Connect ethernet cable**
3. **Connect power supply**
4. **Wait 1-2 minutes** for first boot

### Step 4: Find IP Address

**Method 1: Check Router**
- Access router admin panel
- Look for device named "logbook" or "raspberrypi"

**Method 2: Network Scan**
```bash
# From another computer on same network
sudo nmap -sn 192.168.1.0/24  # Adjust to your network
```

**Method 3: Connect Monitor**
```bash
hostname -I
```

### Step 5: SSH into Raspberry Pi

```bash
ssh pi@192.168.1.XXX  # Replace with your Pi's IP
# Enter password when prompted
```

### Step 6: Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget vim
```

### Step 7: Configure Boot from SSD (Optional, Pi 4/5 Only)

If using USB SSD:

```bash
# Update bootloader
sudo rpi-eeprom-update
sudo rpi-eeprom-update -a  # Apply if needed
sudo reboot
```

After reboot, Pi will boot from USB SSD.

---

## Installing Docker

### Step 1: Install Docker

**Automated Script (Recommended):**

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**Add user to docker group:**

```bash
sudo usermod -aG docker $USER
```

**Log out and back in** for group changes to take effect:

```bash
exit
# SSH back in
ssh pi@192.168.1.XXX
```

### Step 2: Install Docker Compose

```bash
sudo apt install -y docker-compose
```

Or install latest version:

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 3: Verify Installation

```bash
docker --version
docker-compose --version
```

### Step 4: Test Docker

```bash
docker run hello-world
```

If successful, Docker is ready!

---

## Deploying The Logbook

### Step 1: Clone Repository

```bash
cd ~
git clone https://github.com/thegspiro/The-Logbook-v2.git
cd The-Logbook-v2
```

### Step 2: Create Environment File

```bash
cp .env.example .env
nano .env
```

**Critical Settings:**

```bash
# Generate secrets
DJANGO_SECRET_KEY=$(openssl rand -base64 50)
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Set allowed hosts
DJANGO_ALLOWED_HOSTS=192.168.1.XXX,logbook.local  # Your Pi's IP

# Application settings
APP_NAME=Station 45 Logbook
ORGANIZATION_NAME=Volunteer Fire Company 45
PRIMARY_COLOR=#DC2626
SECONDARY_COLOR=#1F2937
TZ=America/New_York

# Debug mode (False for production)
DJANGO_DEBUG=False

# Database settings (use defaults)
POSTGRES_DB=logbook_db
POSTGRES_USER=logbook_user
```

**Save and exit** (Ctrl+X, Y, Enter)

### Step 3: Adjust for Raspberry Pi

**For Pi 3B+ or Pi 4 (2GB)**, limit database memory:

Create `docker-compose.override.yml`:

```bash
nano docker-compose.override.yml
```

Add:

```yaml
version: '3.8'

services:
  db:
    command: postgres -c shared_buffers=128MB -c effective_cache_size=512MB
    shm_size: 256mb

  onboarding:
    environment:
      - GUNICORN_WORKERS=2  # Limit workers on low RAM
```

Save and exit.

### Step 4: Deploy Stack

```bash
docker-compose up -d --build
```

**Wait 2-5 minutes** for build (longer on Pi 3B+)

### Step 5: Check Status

```bash
docker-compose ps
```

All containers should show "Up" status.

### Step 6: View Logs

```bash
docker-compose logs -f
```

Wait until you see "Listening at: http://0.0.0.0:8000"

Press Ctrl+C to exit logs.

### Step 7: Run Migrations

```bash
docker-compose exec onboarding python manage.py migrate
docker-compose exec onboarding python manage.py collectstatic --noinput
```

### Step 8: Access The Logbook

**In browser:** `http://192.168.1.XXX` (your Pi's IP)

**Complete onboarding wizard** (8 steps)

### Step 9: Create Admin User

```bash
docker-compose exec onboarding python manage.py createsuperuser
```

Enter username, email, and password.

### Step 10: Access Admin Panel

`http://192.168.1.XXX/admin`

---

## Performance Optimization

### Enable Swap (Important for Low RAM)

**For Pi 4 (2GB) and Pi 3B+:**

```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
```

Change:
```
CONF_SWAPSIZE=2048  # 2GB swap for 2GB RAM Pi
```

For 1GB Pi:
```
CONF_SWAPSIZE=4096  # 4GB swap
```

**Restart swap:**

```bash
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Optimize PostgreSQL for ARM

Create `postgresql.conf` tuning file:

```bash
mkdir -p ~/The-Logbook-v2/postgres-config
nano ~/The-Logbook-v2/postgres-config/custom.conf
```

**For Pi 5 (8GB):**
```
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 64MB
maintenance_work_mem = 512MB
max_connections = 50
```

**For Pi 4 (4GB):**
```
shared_buffers = 1GB
effective_cache_size = 3GB
work_mem = 32MB
maintenance_work_mem = 256MB
max_connections = 30
```

**For Pi 4 (2GB) or Pi 3B+:**
```
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 128MB
max_connections = 20
```

Mount in `docker-compose.override.yml`:

```yaml
services:
  db:
    volumes:
      - ./postgres-config/custom.conf:/etc/postgresql/postgresql.conf
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
```

Restart:
```bash
docker-compose restart db
```

### Reduce Docker Logging

Add to `docker-compose.override.yml`:

```yaml
services:
  db:
    logging:
      options:
        max-size: "10m"
        max-file: "3"
  onboarding:
    logging:
      options:
        max-size: "10m"
        max-file: "3"
  nginx:
    logging:
      options:
        max-size: "10m"
        max-file: "3"
```

### Monitor Temperature

**Install monitoring:**
```bash
sudo apt install -y stress-ng
```

**Check temperature:**
```bash
vcgencmd measure_temp
```

Should stay below 80°C under load.

**Stress test:**
```bash
stress-ng --cpu 4 --timeout 60s --metrics-brief
vcgencmd measure_temp
```

If over 80°C, improve cooling (heatsink, fan, case).

### Optimize SD Card / SSD

**Reduce writes (if using SD card):**

```bash
sudo nano /etc/fstab
```

Add to tmpfs mounts:
```
tmpfs    /tmp            tmpfs    defaults,noatime,nosuid,size=100m    0 0
tmpfs    /var/tmp        tmpfs    defaults,noatime,nosuid,size=30m     0 0
tmpfs    /var/log        tmpfs    defaults,noatime,nosuid,mode=0755,size=100m    0 0
```

Reboot:
```bash
sudo reboot
```

**For SSD:** No special optimization needed!

---

## Security Hardening

### Change Default Password

```bash
passwd
```

### Update Hostname

```bash
sudo raspi-config
# System Options → Hostname → Set to "logbook"
```

### Configure Firewall

```bash
sudo apt install -y ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS (if using SSL)
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### Disable Unused Services

```bash
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
```

### Setup Automatic Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Select "Yes"

### Setup Fail2Ban (SSH Protection)

```bash
sudo apt install -y fail2ban

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Use SSH Keys (Recommended)

**From your computer:**

```bash
ssh-copy-id pi@192.168.1.XXX
```

**Disable password login:**

```bash
sudo nano /etc/ssh/sshd_config
```

Change:
```
PasswordAuthentication no
```

Restart SSH:
```bash
sudo systemctl restart sshd
```

---

## Backups

### Automated Backups

**Create backup script:**

```bash
nano ~/backup-logbook.sh
```

Add:

```bash
#!/bin/bash
cd ~/The-Logbook-v2
./scripts/backup.sh

# Optional: Copy to USB drive
if [ -d "/mnt/usb-backup" ]; then
    cp -r /home/pi/backups/logbook/latest /mnt/usb-backup/
fi
```

Make executable:
```bash
chmod +x ~/backup-logbook.sh
```

**Schedule with cron:**

```bash
crontab -e
```

Add:
```
0 2 * * * /home/pi/backup-logbook.sh >> /home/pi/backup.log 2>&1
```

Backups run daily at 2 AM.

### Backup to External USB Drive

**Mount USB drive:**

```bash
sudo mkdir /mnt/usb-backup
sudo mount /dev/sda1 /mnt/usb-backup  # Adjust device as needed
```

**Auto-mount on boot:**

```bash
# Find UUID
sudo blkid /dev/sda1

# Edit fstab
sudo nano /etc/fstab
```

Add:
```
UUID=XXXX-XXXX  /mnt/usb-backup  vfat  defaults,auto,users,rw,nofail  0  0
```

### Full System Backup

**Create SD card / SSD image:**

From another Linux computer:

```bash
sudo dd if=/dev/sdX of=~/pi-backup-$(date +%Y%m%d).img bs=4M status=progress
```

**Compress:**
```bash
gzip ~/pi-backup-$(date +%Y%m%d).img
```

Store safely!

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker-compose logs onboarding
docker-compose logs db
```

**Common issues:**
- Out of memory → Add swap, reduce workers
- Architecture mismatch → Use ARM-compatible images
- Storage full → Clean up: `docker system prune -a`

### Out of Memory

**Check memory:**
```bash
free -h
docker stats
```

**Solutions:**
- Add/increase swap
- Reduce Gunicorn workers
- Reduce database connections
- Restart containers: `docker-compose restart`

### Slow Performance

**Check CPU throttling:**
```bash
vcgencmd get_throttled
```

`throttled=0x0` = No throttling (good)
`throttled=0x50000` = Under-voltage or thermal throttling

**Solutions:**
- Better power supply (official recommended)
- Better cooling (heatsinks, fan)
- Optimize PostgreSQL (see Performance section)

### SD Card Corruption

**Symptoms:**
- Read-only filesystem
- Random errors
- Won't boot

**Prevention:**
- Use quality SD card (SanDisk Extreme, Samsung EVO)
- Add UPS for power protection
- Switch to SSD for reliability

**Recovery:**
- Backup → Restore to new SD card
- Or restore from full system image

### Can't Access Web Interface

**Check firewall:**
```bash
sudo ufw status
```

**Check containers:**
```bash
docker-compose ps
```

**Check network:**
```bash
ip addr show
```

**Test locally:**
```bash
curl localhost
```

### Database Connection Errors

**Check database health:**
```bash
docker-compose exec db pg_isready -U logbook_user
```

**Restart database:**
```bash
docker-compose restart db
```

**Check disk space:**
```bash
df -h
```

If full, clean up:
```bash
docker system prune -a
```

---

## Maintenance

### Regular Updates

**Monthly maintenance script:**

```bash
nano ~/monthly-maintenance.sh
```

Add:
```bash
#!/bin/bash
# Update system
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd ~/The-Logbook-v2
./scripts/update.sh

# Clean up
docker system prune -f

# Check disk space
df -h

# Check temperature
vcgencmd measure_temp
```

Make executable:
```bash
chmod +x ~/monthly-maintenance.sh
```

Run monthly:
```bash
./monthly-maintenance.sh
```

### Monitor Disk Usage

```bash
# Check overall usage
df -h

# Check Docker usage
docker system df

# Find large files
du -h ~ | sort -rh | head -20
```

### Monitor Performance

**Install monitoring tools:**

```bash
sudo apt install -y htop iotop
```

**Check resources:**
```bash
htop  # Interactive process viewer
docker stats  # Container resource usage
```

### Temperature Monitoring

**Create monitoring script:**

```bash
nano ~/check-temp.sh
```

Add:
```bash
#!/bin/bash
TEMP=$(vcgencmd measure_temp | sed 's/temp=//' | sed 's/°C//')
if (( $(echo "$TEMP > 75" | bc -l) )); then
    echo "WARNING: Temperature is ${TEMP}°C" | mail -s "Pi Temperature Alert" admin@example.com
fi
```

Schedule in crontab:
```
*/30 * * * * /home/pi/check-temp.sh
```

---

## Performance Benchmarks

Expected performance on different models:

| Model | Users | Response Time | DB Queries/s | Notes |
|-------|-------|---------------|--------------|-------|
| **Pi 5 (8GB)** | 50+ | <100ms | 500+ | Excellent, comparable to low-end x86 |
| **Pi 4 (4GB)** | 20-50 | <200ms | 300+ | Good for medium departments |
| **Pi 4 (2GB)** | 10-20 | <300ms | 200+ | Needs swap, adequate for small use |
| **Pi 3B+ (1GB)** | <10 | <500ms | 100+ | Limited, light use only |

---

## Power Consumption

| Model | Idle | Load | Annual Cost* |
|-------|------|------|--------------|
| **Pi 5** | 3-5W | 8-12W | ~$8-12 |
| **Pi 4** | 2-4W | 6-8W | ~$5-8 |
| **Pi 3B+** | 1-2W | 4-6W | ~$4-6 |

*Based on $0.12/kWh average US electricity cost

---

## Cost Breakdown

**Basic Setup (Pi 4, 4GB):**
- Raspberry Pi 4 (4GB): $55
- Power Supply: $8
- 128GB microSD: $15
- Case with Fan: $10
- **Total: ~$88**

**Recommended Setup (Pi 4, 4GB + SSD):**
- Raspberry Pi 4 (4GB): $55
- Power Supply: $8
- 256GB USB SSD: $35
- Case with Fan: $10
- **Total: ~$108**

**Premium Setup (Pi 5, 8GB + SSD + UPS):**
- Raspberry Pi 5 (8GB): $80
- 27W Power Supply: $12
- 512GB NVMe SSD + Enclosure: $65
- Active Cooling Case: $15
- Small UPS: $40
- **Total: ~$212**

Compare to:
- Budget Server: $500-1000
- Cloud Hosting: $10-50/month = $120-600/year

---

## Quick Reference

### Essential Commands

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update application
cd ~/The-Logbook-v2 && ./scripts/update.sh

# Backup
cd ~/The-Logbook-v2 && ./scripts/backup.sh

# Check temperature
vcgencmd measure_temp

# Check memory
free -h

# Check disk
df -h

# Monitor resources
htop
docker stats
```

### Useful File Locations

- **Installation**: `~/The-Logbook-v2`
- **Environment**: `~/The-Logbook-v2/.env`
- **Compose file**: `~/The-Logbook-v2/docker-compose.yml`
- **Overrides**: `~/The-Logbook-v2/docker-compose.override.yml`
- **Backups**: `~/backups/logbook/` or `/mnt/usb-backup/`
- **Logs**: `docker-compose logs`

---

## Additional Resources

- **Main README**: [../README.md](../README.md)
- **Deployment Guide**: [../DEPLOYMENT.md](../DEPLOYMENT.md)
- **Backup Scripts**: [../scripts/README.md](../scripts/README.md)
- **Raspberry Pi OS**: https://www.raspberrypi.com/software/
- **Docker on Pi**: https://docs.docker.com/engine/install/debian/

---

## Support

**Having issues?** Check:
1. This troubleshooting section
2. Docker logs: `docker-compose logs`
3. System logs: `sudo journalctl -xe`
4. GitHub Issues: https://github.com/thegspiro/The-Logbook-v2/issues

**Community:**
- Raspberry Pi Forums: https://forums.raspberrypi.com/
- The Logbook Discussions: https://github.com/thegspiro/The-Logbook-v2/discussions

---

**Built for the firefighting community, optimized for Raspberry Pi. Stay Safe! 🔥🚒**
