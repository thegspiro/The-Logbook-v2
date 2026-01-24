# The Logbook - Management Scripts

This directory contains helpful scripts for managing The Logbook on Unraid and other Docker hosts.

## Available Scripts

### 🚀 unraid-setup.sh

**Automated initial setup for Unraid servers**

Guides you through the complete installation process:
- Checks system requirements
- Generates secure credentials
- Configures environment variables
- Deploys Docker containers
- Runs database migrations

**Usage:**
```bash
chmod +x scripts/unraid-setup.sh
./scripts/unraid-setup.sh
```

**When to use:**
- First-time installation on Unraid
- Fresh deployment
- Starting from scratch

---

### 💾 backup.sh

**Creates complete backups of The Logbook**

Backs up:
- PostgreSQL database (compressed)
- Media files (user uploads)
- Static assets
- Configuration files (sanitized)

**Usage:**
```bash
# Standard backup
./scripts/backup.sh

# Custom backup location
BACKUP_DIR=/path/to/backups ./scripts/backup.sh

# Custom retention (keep backups for 7 days)
RETENTION_DAYS=7 ./scripts/backup.sh
```

**Environment Variables:**
- `BACKUP_DIR` - Where to store backups (default: `/mnt/user/backups/logbook`)
- `RETENTION_DAYS` - Days to keep old backups (default: 30)

**Automated Backups:**

Using Unraid User Scripts plugin:
```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh
```

Schedule: Daily at 2:00 AM

Using cron:
```bash
0 2 * * * cd /mnt/user/appdata/The-Logbook-v2 && ./scripts/backup.sh >> /var/log/logbook-backup.log 2>&1
```

---

### 🔄 update.sh

**Safely updates The Logbook to the latest version**

The script:
1. Creates pre-update backup
2. Pulls latest code from git
3. Rebuilds Docker containers
4. Runs database migrations
5. Restarts services
6. Verifies health

**Usage:**
```bash
./scripts/update.sh
```

**Interactive prompts:**
- Confirms update
- Shows what will be updated
- Allows cancellation

**Rollback:**
If update fails, restore from the pre-update backup:
```bash
./scripts/restore.sh
# Select the pre-update backup
```

---

### ♻️ restore.sh

**Restores The Logbook from a backup**

Interactive restoration process:
1. Shows available backups
2. Lets you select which to restore
3. Stops containers
4. Restores database and files
5. Restarts services
6. Verifies integrity

**Usage:**
```bash
# Use default backup directory
./scripts/restore.sh

# Use custom backup directory
./scripts/restore.sh /path/to/backups
```

**When to use:**
- After system failure
- To rollback an update
- To restore deleted data
- Moving to new server

---

## Script Permissions

Make all scripts executable:

```bash
chmod +x scripts/*.sh
```

Or individually:

```bash
chmod +x scripts/unraid-setup.sh
chmod +x scripts/backup.sh
chmod +x scripts/update.sh
chmod +x scripts/restore.sh
```

---

## Typical Workflows

### Fresh Installation

```bash
# 1. Clone repository
git clone https://github.com/yourusername/The-Logbook-v2.git
cd The-Logbook-v2

# 2. Run setup
./scripts/unraid-setup.sh

# 3. Complete onboarding in browser
# http://your-server-ip

# 4. Create admin user
docker-compose exec onboarding python manage.py createsuperuser
```

### Regular Maintenance

```bash
# Weekly: Check logs
docker-compose logs --tail=100

# Weekly: Verify backups
ls -lh /mnt/user/backups/logbook/

# Monthly: Update
./scripts/update.sh

# Daily: Automated backup (via User Scripts)
# Runs automatically at 2 AM
```

### Disaster Recovery

```bash
# 1. Clone repository (if needed)
git clone https://github.com/yourusername/The-Logbook-v2.git
cd The-Logbook-v2

# 2. Configure environment
cp .env.example .env
nano .env  # Edit with your settings

# 3. Restore from backup
./scripts/restore.sh

# 4. Verify restoration
docker-compose logs -f
```

### Migration to New Server

```bash
# On old server:
./scripts/backup.sh

# Copy backup to new server:
# /mnt/user/backups/logbook/logbook_backup_YYYYMMDD_HHMMSS

# On new server:
git clone https://github.com/yourusername/The-Logbook-v2.git
cd The-Logbook-v2
cp .env.example .env
nano .env  # Edit with settings

# Restore backup
./scripts/restore.sh /path/to/copied/backup
```

---

## Unraid-Specific Integration

### User Scripts Plugin

Install **User Scripts** from Community Applications, then:

#### Daily Backup Script

Name: `Logbook Daily Backup`
Schedule: `Daily at 2:00 AM`

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh
```

#### Weekly Health Check

Name: `Logbook Health Check`
Schedule: `Weekly on Sunday at 3:00 AM`

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
docker-compose exec -T onboarding python manage.py check --database default
if [ $? -eq 0 ]; then
    echo "Health check passed"
else
    echo "Health check FAILED - check logs"
    /usr/local/emhttp/webGui/scripts/notify -s "Logbook Health Check Failed" -d "The Logbook health check failed. Check logs immediately."
fi
```

#### Monthly Updates

Name: `Logbook Monthly Update`
Schedule: `Monthly on 1st at 1:00 AM`

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/update.sh --force
```

### Unraid Notifications

Send notification after backup:

```bash
#!/bin/bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh

if [ $? -eq 0 ]; then
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Backup Complete" \
        -d "Backup completed successfully" \
        -i "normal"
else
    /usr/local/emhttp/webGui/scripts/notify \
        -s "Logbook Backup FAILED" \
        -d "Backup failed - check logs" \
        -i "alert"
fi
```

---

## Troubleshooting

### "Permission denied" Error

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### "docker-compose.yml not found"

Run scripts from project root:
```bash
cd /mnt/user/appdata/The-Logbook-v2
./scripts/backup.sh  # Not from within scripts/
```

### Backup Script Fails

Check disk space:
```bash
df -h /mnt/user/backups
```

Check Docker volumes:
```bash
docker volume ls | grep logbook
```

### Update Script Fails

View detailed error:
```bash
./scripts/update.sh 2>&1 | tee update.log
```

Rollback:
```bash
./scripts/restore.sh
# Select the pre-update backup
```

### Restore Script Hangs

Check if containers are stopped:
```bash
docker-compose ps
docker-compose down
```

Then retry restore.

---

## Best Practices

### Backups

✅ **Do:**
- Schedule daily automated backups
- Store backups on different disk/array than appdata
- Keep at least 30 days of backups
- Test restore procedure quarterly
- Keep one backup offsite/cloud

❌ **Don't:**
- Store backups only on cache drive
- Delete backups manually without checking
- Skip backup before updates
- Store backups in same location as app

### Updates

✅ **Do:**
- Read changelog before updating
- Update during low-usage times
- Backup before updating
- Test in staging environment (if critical)
- Monitor logs after update

❌ **Don't:**
- Update without backup
- Skip intermediate versions (major updates)
- Update during incident response
- Ignore error messages

### Security

✅ **Do:**
- Keep scripts executable only by root
- Review scripts before running
- Use environment variables for secrets
- Keep .env file secure (chmod 600)

❌ **Don't:**
- Run scripts as non-root without review
- Commit secrets to git
- Share credentials in scripts
- Expose backup directory publicly

---

## Additional Resources

- **Main Documentation**: [../README.md](../README.md)
- **Deployment Guide**: [../DEPLOYMENT.md](../DEPLOYMENT.md)
- **Unraid Guide**: [../docs/UNRAID.md](../docs/UNRAID.md)
- **GitHub Repository**: https://github.com/yourusername/The-Logbook-v2

---

## Contributing

Found a bug in a script? Have an improvement?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

**Script Guidelines:**
- Follow existing style
- Add helpful comments
- Include error handling
- Test on Unraid
- Update this README

---

**Questions?** Open an issue on GitHub or ask in Discussions.

**Stay Safe! 🔥🚒**
