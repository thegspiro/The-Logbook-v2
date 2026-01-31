# The Logbook - Raspberry Pi Deployment Files

This directory contains Raspberry Pi-specific deployment files and configuration optimized for ARM architecture and limited resources.

## What's Included

### 🐳 docker-compose.pi.yml
**Raspberry Pi optimized Docker Compose file**

Specifically designed for Raspberry Pi deployment:
- ✅ ARM architecture support (aarch64, armv7l, armv8)
- ✅ Resource limits for different Pi models
- ✅ Optimized PostgreSQL settings for ARM CPU
- ✅ Memory limits to prevent OOM on low-RAM Pis
- ✅ Reduced logging to save SD card/SSD wear
- ✅ Configurable worker counts for different models
- ✅ Health checks for monitoring

**Usage:**
```bash
docker-compose -f raspberry-pi/docker-compose.pi.yml up -d
```

---

### 🔧 .env.pi.example
**Raspberry Pi-specific environment configuration**

Features:
- Pre-configured settings for different Pi models (3B+, 4, 5)
- Resource limits commented for each model
- Performance tuning recommendations
- Swap configuration guidance
- Temperature monitoring tips
- Storage optimization notes

**Setup:**
```bash
cp raspberry-pi/.env.pi.example .env
nano .env  # Configure for your Pi model
```

---

### 🚀 setup-pi.sh
**Automated Raspberry Pi setup script**

Complete automation of entire installation process:
- ✅ Detects Raspberry Pi model automatically
- ✅ Checks system requirements (RAM, disk, architecture)
- ✅ Monitors temperature
- ✅ Installs Docker and Docker Compose
- ✅ Configures swap for low-RAM models
- ✅ Clones repository
- ✅ Generates secure secrets
- ✅ Configures environment for detected Pi model
- ✅ Builds and deploys containers
- ✅ Runs database migrations
- ✅ Creates backup scripts
- ✅ Provides clear next steps

**Usage:**
```bash
curl -fsSL https://raw.githubusercontent.com/thegspiro/The-Logbook-v2/main/raspberry-pi/setup-pi.sh -o setup-pi.sh
chmod +x setup-pi.sh
./setup-pi.sh
```

---

## Quick Start

### Method 1: Automated Script (Recommended for Beginners)

**One-command installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/thegspiro/The-Logbook-v2/main/raspberry-pi/setup-pi.sh | bash
```

Or download and run:

```bash
wget https://raw.githubusercontent.com/thegspiro/The-Logbook-v2/main/raspberry-pi/setup-pi.sh
chmod +x setup-pi.sh
./setup-pi.sh
```

The script will:
1. Detect your Pi model
2. Install all dependencies
3. Configure swap if needed
4. Deploy The Logbook
5. Provide next steps

---

### Method 2: Manual Installation

**Step-by-step for advanced users:**

1. **Update system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y git curl
   ```

2. **Install Docker:**
   ```bash
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

3. **Install Docker Compose:**
   ```bash
   sudo apt install -y docker-compose
   ```

4. **Clone repository:**
   ```bash
   cd ~
   git clone https://github.com/thegspiro/The-Logbook-v2.git
   cd The-Logbook-v2
   ```

5. **Configure environment:**
   ```bash
   cp raspberry-pi/.env.pi.example .env
   nano .env  # Edit configuration
   ```

6. **Deploy:**
   ```bash
   docker-compose -f raspberry-pi/docker-compose.pi.yml up -d --build
   ```

7. **Run migrations:**
   ```bash
   docker-compose -f raspberry-pi/docker-compose.pi.yml exec onboarding python manage.py migrate
   docker-compose -f raspberry-pi/docker-compose.pi.yml exec onboarding python manage.py collectstatic --noinput
   ```

8. **Access:** `http://your-pi-ip`

---

## Raspberry Pi Model Configurations

### Raspberry Pi 5 (8GB)

**Best performance, handles 50+ users**

Environment settings:
```bash
DB_MEMORY_LIMIT=2048m
APP_MEMORY_LIMIT=2048m
GUNICORN_WORKERS=6
PG_SHARED_BUFFERS=2GB
PG_CACHE_SIZE=6GB
```

No swap needed.

---

### Raspberry Pi 4 (4GB)

**Good performance, handles 20-50 users**

Environment settings:
```bash
DB_MEMORY_LIMIT=1024m
APP_MEMORY_LIMIT=1024m
GUNICORN_WORKERS=4
PG_SHARED_BUFFERS=1GB
PG_CACHE_SIZE=3GB
```

Optional: 2GB swap for safety.

---

### Raspberry Pi 4 (2GB)

**Adequate performance, handles 10-20 users**

Environment settings:
```bash
DB_MEMORY_LIMIT=512m
APP_MEMORY_LIMIT=512m
GUNICORN_WORKERS=2
PG_SHARED_BUFFERS=256MB
PG_CACHE_SIZE=1GB
```

**Important:** Enable 2GB swap:
```bash
sudo nano /etc/dphys-swapfile
# Set: CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

### Raspberry Pi 3B+ (1GB)

**Limited performance, handles <10 users**

Environment settings:
```bash
DB_MEMORY_LIMIT=256m
APP_MEMORY_LIMIT=256m
GUNICORN_WORKERS=2
PG_SHARED_BUFFERS=128MB
PG_CACHE_SIZE=512MB
```

**Important:** Enable 4GB swap:
```bash
sudo nano /etc/dphys-swapfile
# Set: CONF_SWAPSIZE=4096
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

---

## Hardware Recommendations

### Storage

**Option 1: microSD Card** (Budget)
- SanDisk Extreme (A2, V30, U3)
- Samsung EVO Plus
- 64GB minimum, 128GB recommended
- ⚠️ 1-3 year lifespan
- 💰 $10-25

**Option 2: USB SSD** (Recommended)
- Any USB 3.0+ SSD
- Crucial MX500, Samsung 870 EVO
- 128GB minimum, 256GB recommended
- ✅ 5-10+ year lifespan
- ✅ 5-10x faster
- 💰 $25-60

### Cooling

**Required for reliable operation:**
- Passive heatsinks (minimum)
- Active cooling fan (recommended for Pi 4/5)
- Temperature should stay below 80°C

**Check temperature:**
```bash
vcgencmd measure_temp
```

### Power Supply

**Use official power supply:**
- Pi 3B+: 5V 2.5A
- Pi 4: 5V 3A (15W)
- Pi 5: 5V 5A (27W)

⚠️ Cheap power supplies cause instability!

### Optional

- Small UPS ($30-50) for power protection
- Ethernet cable (more stable than WiFi)
- Case with passive or active cooling

---

## Performance Optimization

### Enable Swap (Low RAM Models)

For Pi 4 (2GB) and Pi 3B+:

```bash
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
```

Change to:
```
CONF_SWAPSIZE=2048  # 2GB for 2GB RAM
# or
CONF_SWAPSIZE=4096  # 4GB for 1GB RAM
```

Restart swap:
```bash
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

### Boot from SSD (Pi 4/5)

For best performance, boot directly from USB SSD:

1. Update bootloader:
   ```bash
   sudo rpi-eeprom-update
   sudo rpi-eeprom-update -a
   sudo reboot
   ```

2. Flash OS to SSD using Raspberry Pi Imager

3. Boot from SSD (no SD card needed!)

### Monitor Resources

```bash
# CPU/Memory usage
htop

# Docker container stats
docker stats

# Temperature
vcgencmd measure_temp

# Disk usage
df -h
```

---

## Management Commands

### With Raspberry Pi Compose File

All commands use the Pi-specific compose file:

```bash
# Navigate to installation
cd ~/The-Logbook-v2

# Start
docker-compose -f raspberry-pi/docker-compose.pi.yml up -d

# Stop
docker-compose -f raspberry-pi/docker-compose.pi.yml down

# Restart
docker-compose -f raspberry-pi/docker-compose.pi.yml restart

# Logs
docker-compose -f raspberry-pi/docker-compose.pi.yml logs -f

# Status
docker-compose -f raspberry-pi/docker-compose.pi.yml ps

# Create admin user
docker-compose -f raspberry-pi/docker-compose.pi.yml exec onboarding python manage.py createsuperuser
```

### Helper Scripts

Create aliases for easier management:

```bash
nano ~/.bashrc
```

Add:
```bash
alias logbook-start='docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml up -d'
alias logbook-stop='docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml down'
alias logbook-restart='docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml restart'
alias logbook-logs='docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml logs -f'
alias logbook-status='docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml ps'
```

Reload:
```bash
source ~/.bashrc
```

Now use simple commands:
```bash
logbook-start
logbook-logs
logbook-status
```

---

## Automated Backups

### Create Backup Script

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
    cp -r ~/backups/logbook/latest /mnt/usb-backup/
fi
```

Make executable:
```bash
chmod +x ~/backup-logbook.sh
```

### Schedule with Cron

```bash
crontab -e
```

Add for daily backups at 2 AM:
```
0 2 * * * /home/pi/backup-logbook.sh >> /home/pi/backup.log 2>&1
```

---

## Troubleshooting

### Out of Memory

**Symptoms:**
- Container crashes
- Slow performance
- Database connection errors

**Solutions:**
1. Check memory: `free -h`
2. Enable/increase swap
3. Reduce workers in `.env`
4. Restart containers: `docker-compose restart`

### Temperature Throttling

**Symptoms:**
- Slow performance
- System lag

**Check:**
```bash
vcgencmd measure_temp
vcgencmd get_throttled
```

**Solutions:**
- Add heatsink or fan
- Improve case ventilation
- Use official power supply
- Reduce load

### SD Card Corruption

**Prevention:**
- Use quality SD card
- Switch to SSD
- Add UPS
- Enable regular backups

**Recovery:**
- Restore from backup
- Re-flash SD card
- Restore database from backup

### Slow Performance

**Solutions:**
1. Switch to SSD (5-10x faster)
2. Enable swap
3. Optimize PostgreSQL (see .env.pi.example)
4. Reduce workers
5. Check temperature

---

## Cost Comparison

### Total Cost of Ownership (3 years)

**Raspberry Pi 4 (4GB) Setup:**
- Hardware: $108 (one-time)
- Electricity: ~$24 ($8/year × 3)
- **Total: $132**

**Cloud Hosting (smallest viable):**
- 2GB VPS: $10-15/month
- **Total: $360-540**

**Savings: $228-408 over 3 years**

Plus:
- ✅ You own the hardware
- ✅ No monthly fees
- ✅ Complete control
- ✅ Offline capability

---

## Documentation

- **Complete Pi Guide**: [../docs/RASPBERRY_PI.md](../docs/RASPBERRY_PI.md)
- **Main README**: [../README.md](../README.md)
- **Deployment Guide**: [../DEPLOYMENT.md](../DEPLOYMENT.md)
- **Scripts Guide**: [../scripts/README.md](../scripts/README.md)

---

## Support

**Need help?**

1. Check [docs/RASPBERRY_PI.md](../docs/RASPBERRY_PI.md)
2. View logs: `docker-compose logs`
3. Check resources: `htop`, `free -h`, `df -h`
4. GitHub Issues: https://github.com/thegspiro/The-Logbook-v2/issues
5. Raspberry Pi Forums: https://forums.raspberrypi.com/

---

**Built for volunteer fire departments, optimized for Raspberry Pi. Affordable, reliable, always-on. Stay Safe! 🔥🚒**
