#!/bin/bash
################################################################################
# The Logbook - Backup Script
#
# This script creates a complete backup of The Logbook including:
# - PostgreSQL database
# - Media files and uploads
# - Configuration files
#
# Designed for Unraid but works on any Docker host
################################################################################

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/mnt/user/backups/logbook}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="logbook_backup_${TIMESTAMP}"

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
    echo "║           The Logbook - Backup Script                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Backup will be saved to: ${BACKUP_DIR}/${BACKUP_NAME}"
    echo ""
}

check_docker() {
    if ! docker-compose ps | grep -q "Up"; then
        print_error "The Logbook containers are not running"
        print_info "Start them with: docker-compose up -d"
        exit 1
    fi
    print_success "Containers are running"
}

create_backup_dir() {
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
    print_success "Created backup directory"
}

backup_database() {
    print_info "Backing up PostgreSQL database..."

    # Get database credentials from .env
    source .env

    # Create database dump
    docker-compose exec -T db pg_dump \
        -U "${POSTGRES_USER}" \
        -d "${POSTGRES_DB}" \
        --clean --if-exists \
        > "${BACKUP_DIR}/${BACKUP_NAME}/database.sql"

    # Compress the dump
    gzip "${BACKUP_DIR}/${BACKUP_NAME}/database.sql"

    print_success "Database backed up ($(du -h "${BACKUP_DIR}/${BACKUP_NAME}/database.sql.gz" | cut -f1))"
}

backup_media() {
    print_info "Backing up media files..."

    # Backup media volume
    docker run --rm \
        -v logbook_media_volume:/data:ro \
        -v "${BACKUP_DIR}/${BACKUP_NAME}":/backup \
        alpine \
        tar czf /backup/media.tar.gz -C /data .

    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}/media.tar.gz" ]; then
        print_success "Media files backed up ($(du -h "${BACKUP_DIR}/${BACKUP_NAME}/media.tar.gz" | cut -f1))"
    else
        print_warning "No media files found or backup failed"
    fi
}

backup_static() {
    print_info "Backing up static files..."

    # Backup static volume
    docker run --rm \
        -v logbook_static_volume:/data:ro \
        -v "${BACKUP_DIR}/${BACKUP_NAME}":/backup \
        alpine \
        tar czf /backup/static.tar.gz -C /data .

    if [ -f "${BACKUP_DIR}/${BACKUP_NAME}/static.tar.gz" ]; then
        print_success "Static files backed up ($(du -h "${BACKUP_DIR}/${BACKUP_NAME}/static.tar.gz" | cut -f1))"
    else
        print_warning "No static files found or backup failed"
    fi
}

backup_config() {
    print_info "Backing up configuration files..."

    # Backup .env file (excluding sensitive data in plain text)
    if [ -f .env ]; then
        # Create a sanitized version
        grep -v "SECRET\|PASSWORD" .env > "${BACKUP_DIR}/${BACKUP_NAME}/env.template" || true
        print_warning ".env file sanitized and backed up as env.template"
    fi

    # Backup docker-compose.yml
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml "${BACKUP_DIR}/${BACKUP_NAME}/"
        print_success "docker-compose.yml backed up"
    fi

    # Backup nginx config
    if [ -d nginx ]; then
        cp -r nginx "${BACKUP_DIR}/${BACKUP_NAME}/"
        print_success "Nginx configuration backed up"
    fi
}

create_manifest() {
    print_info "Creating backup manifest..."

    cat > "${BACKUP_DIR}/${BACKUP_NAME}/MANIFEST.txt" <<EOF
The Logbook Backup Manifest
===========================

Backup Date: $(date)
Backup Name: ${BACKUP_NAME}
Hostname: $(hostname)

Contents:
---------
- database.sql.gz    : PostgreSQL database dump
- media.tar.gz       : User-uploaded media files
- static.tar.gz      : Static assets (CSS, JS, images)
- docker-compose.yml : Container orchestration config
- nginx/             : Web server configuration
- env.template       : Environment variables (sanitized)

Restore Instructions:
--------------------
1. Stop existing containers: docker-compose down
2. Restore database:
   gunzip -c database.sql.gz | docker-compose exec -T db psql -U logbook_user logbook_db
3. Restore volumes:
   docker run --rm -v logbook_media_volume:/data -v \$(pwd):/backup alpine tar xzf /backup/media.tar.gz -C /data
   docker run --rm -v logbook_static_volume:/data -v \$(pwd):/backup alpine tar xzf /backup/static.tar.gz -C /data
4. Restart containers: docker-compose up -d

For detailed instructions, see DEPLOYMENT.md

Backup Size: $(du -sh "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
EOF

    print_success "Manifest created"
}

cleanup_old_backups() {
    print_info "Cleaning up backups older than ${RETENTION_DAYS} days..."

    find "${BACKUP_DIR}" -maxdepth 1 -type d -name "logbook_backup_*" -mtime +${RETENTION_DAYS} -exec rm -rf {} \; 2>/dev/null || true

    local backup_count=$(find "${BACKUP_DIR}" -maxdepth 1 -type d -name "logbook_backup_*" | wc -l)
    print_success "Cleanup complete (${backup_count} backups remaining)"
}

create_latest_symlink() {
    # Create a symlink to the latest backup
    ln -sfn "${BACKUP_DIR}/${BACKUP_NAME}" "${BACKUP_DIR}/latest"
    print_success "Created 'latest' symlink"
}

print_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Backup Completed Successfully! ✓              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "Backup location: ${BACKUP_DIR}/${BACKUP_NAME}"
    echo "Backup size: $(du -sh "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)"
    echo ""
    print_info "To restore from this backup, see:"
    echo "  ${BACKUP_DIR}/${BACKUP_NAME}/MANIFEST.txt"
    echo ""
    print_warning "For Unraid users: Consider copying backups to a different array/disk"
    echo ""
}

# Main execution
main() {
    print_header

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run this script from the project root."
        exit 1
    fi

    check_docker
    create_backup_dir
    backup_database
    backup_media
    backup_static
    backup_config
    create_manifest
    create_latest_symlink
    cleanup_old_backups
    print_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  BACKUP_DIR           Directory to store backups (default: /mnt/user/backups/logbook)"
        echo "  RETENTION_DAYS       Days to keep old backups (default: 30)"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Standard backup"
        echo "  BACKUP_DIR=/tmp/backup $0             # Custom backup location"
        echo "  RETENTION_DAYS=7 $0                   # Keep backups for 7 days"
        exit 0
        ;;
    *)
        main
        ;;
esac
