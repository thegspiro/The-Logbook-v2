# The Logbook - GitHub Wiki Files

This directory contains files for setting up and maintaining The Logbook's GitHub Wiki.

## Quick Start

To migrate all documentation to GitHub Wiki:

```bash
# 1. Enable wiki on GitHub (if not already enabled)
# Go to: https://github.com/thegspiro/The-Logbook-v2/settings
# Enable "Wikis" under Features

# 2. Create first page (if wiki is empty)
# Go to: https://github.com/thegspiro/The-Logbook-v2/wiki
# Create a page titled "Home" with any content

# 3. Clone the wiki repository
cd ..
git clone https://github.com/thegspiro/The-Logbook-v2.wiki.git

# 4. Run migration script
cd The-Logbook-v2
./wiki/migrate-to-wiki.sh
```

That's it! Your wiki will be populated with all 350+ pages of documentation.

## Files in This Directory

### Home.md
The wiki's home page with navigation to all sections.

**Features:**
- Welcome message and project overview
- Quick links to all deployment platforms
- Navigation to documentation sections
- Deployment comparison table
- Latest updates section

### _Sidebar.md
Navigation sidebar that appears on every wiki page.

**Structure:**
- Getting Started links
- Deployment guides
- Configuration topics
- Management tools
- Platform guides
- Advanced topics
- Help resources

### WIKI_SETUP_GUIDE.md
Complete guide for setting up and maintaining the GitHub Wiki.

**Covers:**
- What is a GitHub Wiki
- Step-by-step setup instructions
- Migration procedures (automated and manual)
- Additional page creation
- Wiki maintenance workflows
- Sync strategies
- Best practices

### migrate-to-wiki.sh
Automated script to migrate all documentation to the wiki.

**What it does:**
1. Checks if wiki is cloned
2. Copies wiki structure files (Home, Sidebar)
3. Copies all deployment guides
4. Copies platform-specific documentation
5. Copies management documentation
6. Creates additional pages (FAQ, System Requirements, Troubleshooting)
7. Commits changes with descriptive message
8. Optionally pushes to GitHub

**Usage:**
```bash
./wiki/migrate-to-wiki.sh
```

## Wiki Structure

After migration, your wiki will have this structure:

```
Home.md                           # Wiki homepage
_Sidebar.md                       # Navigation
_Footer.md                        # Footer (optional)

# Getting Started
Installation-Overview.md          # From README.md
System-Requirements.md            # Generated
First-Time-Setup.md               # To be created
Onboarding-Wizard.md              # To be created

# Deployment Guides
Raspberry-Pi-Deployment.md        # From raspberry-pi/README.md
Raspberry-Pi-Guide.md             # From docs/RASPBERRY_PI.md
Unraid-Deployment.md              # From unraid/README.md
Unraid-Guide.md                   # From docs/UNRAID.md
Portainer-Guide.md                # From unraid/PORTAINER_INSTALL.md
Docker-Compose-Deployment.md      # From unraid/COMPOSE_INSTALL.md
Manual-Installation.md            # From DEPLOYMENT.md

# Management
Backup-and-Restore.md             # From scripts/README.md

# Help
FAQ.md                            # Generated
Troubleshooting.md                # Generated

# More pages to be added as needed
```

## Maintaining the Wiki

### Syncing After Updates

When you update documentation in the main repository:

```bash
# Option 1: Re-run migration script
./wiki/migrate-to-wiki.sh

# Option 2: Manual sync
cd ../The-Logbook-v2.wiki
cp ../The-Logbook-v2/docs/RASPBERRY_PI.md ./Raspberry-Pi-Guide.md
git add .
git commit -m "Update Raspberry Pi guide"
git push origin master
```

### Adding New Pages

Create new pages in the wiki repository:

```bash
cd ../The-Logbook-v2.wiki
nano New-Page.md  # Create your page
git add New-Page.md
git commit -m "Add new page for XYZ"
git push origin master
```

Then update `_Sidebar.md` to link to it.

### Editing Existing Pages

**Via Git:**
```bash
cd ../The-Logbook-v2.wiki
nano Page-Name.md
git add Page-Name.md
git commit -m "Update page description"
git push origin master
```

**Via Web Interface:**
1. Go to the page on GitHub
2. Click "Edit"
3. Make changes
4. Add commit message
5. Click "Save"

## Wiki vs Repository Docs

**Keep Both!**

| Location | Purpose | Audience |
|----------|---------|----------|
| **Wiki** | User-friendly documentation | End users, admins |
| **Repository** | Technical documentation | Developers, contributors |

**Strategy:**
- User-facing guides → Wiki
- Technical specs, API docs → Repository
- Both can coexist and link to each other

## Benefits of Using Wiki

✅ **Easy Navigation** - Sidebar on every page
✅ **Search** - Built-in search functionality
✅ **Collaboration** - Easy for community to contribute
✅ **Clean URLs** - `/wiki/Page-Name` instead of `/blob/main/docs/File.md`
✅ **Web Editing** - Edit right in browser
✅ **Versioning** - Full Git history
✅ **Free** - GitHub provides free wiki hosting
✅ **SEO** - Indexed by search engines

## Customization

### Change Sidebar

Edit `_Sidebar.md` in the wiki repository to change navigation.

### Add Footer

Create `_Footer.md` in the wiki repository:

```markdown
---
**The Logbook** | [GitHub](https://github.com/thegspiro/The-Logbook-v2) | [Issues](https://github.com/thegspiro/The-Logbook-v2/issues) | [Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)

Built for firefighters, by firefighters. Stay Safe! 🔥🚒
```

### Update Home Page

Edit `Home.md` to change the welcome page.

## Link From Main README

Update the main `README.md` to point users to the wiki:

```markdown
## 📖 Documentation

**Complete documentation is available in our [Wiki](https://github.com/thegspiro/The-Logbook-v2/wiki)**

Quick links:
- [Installation Overview](https://github.com/thegspiro/The-Logbook-v2/wiki/Installation-Overview)
- [Raspberry Pi Deployment](https://github.com/thegspiro/The-Logbook-v2/wiki/Raspberry-Pi-Guide)
- [Unraid Deployment](https://github.com/thegspiro/The-Logbook-v2/wiki/Unraid-Guide)
- [Troubleshooting](https://github.com/thegspiro/The-Logbook-v2/wiki/Troubleshooting)
- [FAQ](https://github.com/thegspiro/The-Logbook-v2/wiki/FAQ)
```

## Resources

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://www.markdownguide.org/)
- [The Logbook Wiki](https://github.com/thegspiro/The-Logbook-v2/wiki) (once set up)

## Support

Having issues with wiki setup?
- Check `WIKI_SETUP_GUIDE.md` for detailed instructions
- Review GitHub's wiki documentation
- Ask in [GitHub Discussions](https://github.com/thegspiro/The-Logbook-v2/discussions)

---

**Ready to set up your wiki? Run `./wiki/migrate-to-wiki.sh` to get started!**
