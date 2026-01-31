# GitHub Wiki Setup Guide

This guide explains how to set up and populate The Logbook's GitHub Wiki with all documentation.

## What is a GitHub Wiki?

GitHub Wikis are separate Git repositories attached to your main project repository. They provide:
- ✅ Easy navigation with sidebar
- ✅ Built-in search functionality
- ✅ Version control for documentation
- ✅ Collaborative editing
- ✅ Markdown support
- ✅ Free hosting

## Step 1: Enable the Wiki

1. Go to your GitHub repository: `https://github.com/thegspiro/The-Logbook-v2`
2. Click **Settings** tab
3. Scroll to **Features** section
4. Check ✅ **Wikis**
5. Click **Save**

The Wiki is now enabled and accessible at:
`https://github.com/thegspiro/The-Logbook-v2/wiki`

## Step 2: Clone the Wiki Repository

The Wiki is a separate Git repository. Clone it locally:

```bash
# Clone the wiki repository
git clone https://github.com/thegspiro/The-Logbook-v2.wiki.git

cd The-Logbook-v2.wiki
```

**Note:** The wiki repository won't exist until you create the first page through the GitHub web interface.

### Initial Wiki Setup (If Wiki is Empty)

If this is the first time:

1. Go to `https://github.com/thegspiro/The-Logbook-v2/wiki`
2. Click **Create the first page**
3. Title: `Home`
4. Add temporary content: `Coming soon!`
5. Click **Save Page**

Now you can clone:

```bash
git clone https://github.com/thegspiro/The-Logbook-v2.wiki.git
```

## Step 3: Copy Documentation to Wiki

### Automated Migration Script

Use this script to automatically migrate all documentation:

```bash
#!/bin/bash
# migrate-to-wiki.sh

# Set paths
REPO_DIR="/path/to/The-Logbook-v2"
WIKI_DIR="/path/to/The-Logbook-v2.wiki"

# Copy wiki structure
cp $REPO_DIR/wiki/Home.md $WIKI_DIR/
cp $REPO_DIR/wiki/_Sidebar.md $WIKI_DIR/

# Copy and rename documentation files
# Deployment guides
cp $REPO_DIR/docs/RASPBERRY_PI.md $WIKI_DIR/Raspberry-Pi-Guide.md
cp $REPO_DIR/docs/UNRAID.md $WIKI_DIR/Unraid-Guide.md
cp $REPO_DIR/unraid/PORTAINER_INSTALL.md $WIKI_DIR/Portainer-Guide.md
cp $REPO_DIR/unraid/COMPOSE_INSTALL.md $WIKI_DIR/Docker-Compose-Deployment.md
cp $REPO_DIR/DEPLOYMENT.md $WIKI_DIR/Manual-Installation.md

# Platform-specific quick starts
cp $REPO_DIR/raspberry-pi/README.md $WIKI_DIR/Raspberry-Pi-Deployment.md
cp $REPO_DIR/unraid/README.md $WIKI_DIR/Unraid-Deployment.md

# Scripts documentation
cp $REPO_DIR/scripts/README.md $WIKI_DIR/Backup-and-Restore.md

# Main project files
cp $REPO_DIR/README.md $WIKI_DIR/Installation-Overview.md

# Commit and push
cd $WIKI_DIR
git add .
git commit -m "Initial wiki migration with complete documentation"
git push origin master

echo "✓ Wiki migration complete!"
echo "View at: https://github.com/thegspiro/The-Logbook-v2/wiki"
```

### Manual Migration

If you prefer manual control:

```bash
cd The-Logbook-v2.wiki

# Copy home page and sidebar
cp ../The-Logbook-v2/wiki/Home.md ./
cp ../The-Logbook-v2/wiki/_Sidebar.md ./

# Copy documentation (rename for wiki URLs)
cp ../The-Logbook-v2/docs/RASPBERRY_PI.md ./Raspberry-Pi-Guide.md
cp ../The-Logbook-v2/docs/UNRAID.md ./Unraid-Guide.md
cp ../The-Logbook-v2/unraid/PORTAINER_INSTALL.md ./Portainer-Guide.md
cp ../The-Logbook-v2/unraid/COMPOSE_INSTALL.md ./Docker-Compose-Deployment.md
cp ../The-Logbook-v2/raspberry-pi/README.md ./Raspberry-Pi-Deployment.md
cp ../The-Logbook-v2/unraid/README.md ./Unraid-Deployment.md

# Add, commit, and push
git add .
git commit -m "Add complete documentation to wiki"
git push origin master
```

## Step 4: Create Additional Pages

Create pages for sections not yet covered:

### System Requirements

```bash
cat > System-Requirements.md <<'EOF'
# System Requirements

## Minimum Requirements

### Raspberry Pi
- **Model**: Raspberry Pi 3B+ or newer
- **RAM**: 1GB minimum, 2GB+ recommended
- **Storage**: 64GB microSD or SSD
- **Network**: Ethernet or WiFi
- **Power**: Official power supply

### Unraid/Docker Host
- **RAM**: 2GB minimum, 4GB+ recommended
- **Storage**: 10GB+ available
- **Docker**: 20.10 or newer
- **Docker Compose**: 1.29 or newer

### Cloud VPS
- **RAM**: 2GB minimum
- **Storage**: 20GB SSD
- **Bandwidth**: 1TB/month
- **OS**: Ubuntu 22.04 LTS or Debian 11+

## Recommended Specifications

See platform-specific guides for detailed recommendations:
- [Raspberry Pi Guide](Raspberry-Pi-Guide)
- [Unraid Guide](Unraid-Guide)
- [Cloud Deployment](Cloud-Deployment)
EOF
```

### FAQ

```bash
cat > FAQ.md <<'EOF'
# Frequently Asked Questions

## General Questions

### What is The Logbook?
The Logbook is an open-source intranet platform designed specifically for volunteer fire departments...

### Is it really free?
Yes! The Logbook is 100% free and open-source under the MIT License...

### Can I customize it for my department?
Absolutely! You can customize colors, branding, and configure all modules...

## Deployment Questions

### Which platform should I use?
- **Raspberry Pi**: Best for budget-conscious departments
- **Unraid**: Best if you already have an Unraid server
- **Cloud VPS**: Best for remote access and scalability

### Can I run this on Windows?
We recommend Linux for production, but you can run it on Windows using Docker Desktop...

[See full FAQ](FAQ)
EOF
```

### Troubleshooting

```bash
cat > Troubleshooting.md <<'EOF'
# Troubleshooting Guide

## Common Issues

### Containers Won't Start
**Symptoms**: Docker containers exit immediately or won't start

**Solutions**:
1. Check logs: `docker-compose logs`
2. Verify ports aren't in use
3. Check disk space: `df -h`
4. Ensure Docker daemon is running

### Database Connection Errors
**Symptoms**: "could not connect to server" errors

**Solutions**:
1. Check database container: `docker-compose ps db`
2. Verify credentials in `.env` file
3. Restart database: `docker-compose restart db`

[See complete troubleshooting guide](Troubleshooting)
EOF
```

## Step 5: Update Main README

Update the main repository README to link to the wiki:

```markdown
## Documentation

📖 **[Complete Documentation Wiki](https://github.com/thegspiro/The-Logbook-v2/wiki)**

Quick links:
- [Installation Guide](https://github.com/thegspiro/The-Logbook-v2/wiki/Installation-Overview)
- [Raspberry Pi Deployment](https://github.com/thegspiro/The-Logbook-v2/wiki/Raspberry-Pi-Guide)
- [Unraid Deployment](https://github.com/thegspiro/The-Logbook-v2/wiki/Unraid-Guide)
- [Troubleshooting](https://github.com/thegspiro/The-Logbook-v2/wiki/Troubleshooting)
```

## Step 6: Organize Documentation Structure

### Recommended Wiki Page Structure

```
Home.md                           # Wiki home page
_Sidebar.md                       # Navigation sidebar
_Footer.md                        # Footer (optional)

# Getting Started
Installation-Overview.md
System-Requirements.md
First-Time-Setup.md
Onboarding-Wizard.md

# Deployment Guides
Raspberry-Pi-Deployment.md
Raspberry-Pi-Guide.md             # Detailed guide
Unraid-Deployment.md
Unraid-Guide.md                   # Detailed guide
Portainer-Deployment.md
Portainer-Guide.md                # Detailed guide
Docker-Compose-Deployment.md
Manual-Installation.md
Cloud-Deployment.md

# Configuration
Environment-Variables.md
Database-Configuration.md
Email-Setup.md
Storage-Configuration.md
Security-Settings.md
Theme-Customization.md

# Management
Backup-and-Restore.md
Updates-and-Upgrades.md
Monitoring.md
Performance-Tuning.md
Troubleshooting.md

# Advanced
Architecture-Overview.md
Security-Best-Practices.md
API-Documentation.md
Module-Development.md

# Help
FAQ.md
Common-Issues.md
Performance-Issues.md
Getting-Help.md
Contributing.md
```

## Step 7: Enable Wiki Features

### Add Footer (Optional)

Create `_Footer.md`:

```markdown
---
**The Logbook** | [GitHub](https://github.com/thegspiro/The-Logbook-v2) | [Issues](https://github.com/thegspiro/The-Logbook-v2/issues) | [Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)

Built for firefighters, by firefighters. Stay Safe! 🔥🚒
```

### Internal Linking

Use wiki-style links in your markdown:

```markdown
See the [Raspberry Pi Guide](Raspberry-Pi-Guide) for details.

Check [Troubleshooting](Troubleshooting) if you encounter issues.
```

## Step 8: Maintain the Wiki

### Workflow for Updates

1. **Edit locally**:
   ```bash
   cd The-Logbook-v2.wiki
   nano Raspberry-Pi-Guide.md  # Edit page
   ```

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "Update Raspberry Pi guide with new tips"
   git push origin master
   ```

3. **Or edit via web interface**:
   - Go to wiki page
   - Click **Edit**
   - Make changes
   - Click **Save**

### Keep Wiki in Sync

Create a sync script:

```bash
#!/bin/bash
# sync-wiki.sh
# Keeps wiki in sync with repository docs

REPO_DIR="/path/to/The-Logbook-v2"
WIKI_DIR="/path/to/The-Logbook-v2.wiki"

# Update from latest docs
cp $REPO_DIR/docs/RASPBERRY_PI.md $WIKI_DIR/Raspberry-Pi-Guide.md
cp $REPO_DIR/docs/UNRAID.md $WIKI_DIR/Unraid-Guide.md
# ... (other files)

cd $WIKI_DIR
git add .
git commit -m "Sync wiki with latest documentation"
git push origin master

echo "✓ Wiki synced!"
```

Run after updating docs in main repo.

## Benefits of Using Wiki

✅ **Easy Navigation**: Sidebar appears on every page
✅ **Search**: Built-in search functionality
✅ **Versioning**: Full Git history
✅ **Collaborative**: Easy for others to contribute
✅ **Integrated**: Lives with your project on GitHub
✅ **Free**: No hosting costs
✅ **SEO**: Indexed by search engines

## Comparison: Wiki vs Repository Docs

| Feature | GitHub Wiki | Repository Docs |
|---------|-------------|-----------------|
| **Navigation** | Sidebar + footer | File structure |
| **Search** | Built-in | Limited |
| **Editing** | Web UI + Git | Git only |
| **Collaboration** | Easy (web UI) | Requires PR |
| **Organization** | Flat structure | Hierarchical |
| **Versioning** | Separate repo | Main repo |
| **URLs** | Clean (`/wiki/Page`) | Long (`/blob/main/docs/File.md`) |

**Recommendation**: Use **both**!
- Keep technical docs in repository (for PRs, CI/CD)
- Mirror user-facing docs to wiki (for easy access)

## Example: Complete Migration

```bash
#!/bin/bash
# complete-wiki-migration.sh

set -e

echo "=== The Logbook Wiki Migration ==="
echo ""

# Variables
REPO_DIR="$(pwd)"
WIKI_DIR="../The-Logbook-v2.wiki"

# Check if wiki is cloned
if [ ! -d "$WIKI_DIR" ]; then
    echo "Cloning wiki repository..."
    cd ..
    git clone https://github.com/thegspiro/The-Logbook-v2.wiki.git
    cd "$REPO_DIR"
fi

echo "Copying documentation to wiki..."

# Copy structure
cp wiki/Home.md "$WIKI_DIR/"
cp wiki/_Sidebar.md "$WIKI_DIR/"

# Copy guides
cp docs/RASPBERRY_PI.md "$WIKI_DIR/Raspberry-Pi-Guide.md"
cp docs/UNRAID.md "$WIKI_DIR/Unraid-Guide.md"
cp unraid/PORTAINER_INSTALL.md "$WIKI_DIR/Portainer-Guide.md"
cp unraid/COMPOSE_INSTALL.md "$WIKI_DIR/Docker-Compose-Deployment.md"
cp DEPLOYMENT.md "$WIKI_DIR/Manual-Installation.md"

# Copy quick starts
cp raspberry-pi/README.md "$WIKI_DIR/Raspberry-Pi-Deployment.md"
cp unraid/README.md "$WIKI_DIR/Unraid-Deployment.md"

# Copy management docs
cp scripts/README.md "$WIKI_DIR/Backup-and-Restore.md"

# Copy main docs
cp README.md "$WIKI_DIR/Installation-Overview.md"

echo "Committing to wiki..."
cd "$WIKI_DIR"
git add .
git commit -m "Complete documentation migration

- Add home page and navigation sidebar
- Add all deployment guides
- Add platform-specific documentation
- Add management and troubleshooting guides
- 350+ pages of comprehensive documentation"

echo "Pushing to GitHub..."
git push origin master

echo ""
echo "✓ Wiki migration complete!"
echo ""
echo "View your wiki at:"
echo "https://github.com/thegspiro/The-Logbook-v2/wiki"
echo ""
```

## Next Steps

1. ✅ Enable wiki on GitHub
2. ✅ Clone wiki repository
3. ✅ Run migration script
4. ✅ Verify pages appear correctly
5. ✅ Update main README with wiki links
6. ✅ Announce wiki to users

## Resources

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://www.markdownguide.org/)
- [Wiki Best Practices](https://github.com/github/docs/blob/main/contributing/content-markup-reference.md)

---

**Ready to set up your wiki? Follow the steps above and your documentation will be beautifully organized and easily accessible!**
