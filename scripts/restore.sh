#!/bin/bash
################################################################################
# The Logbook - Restore Script
#
# This script restores The Logbook from a backup
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
    echo "║           The Logbook - Restore Script                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_available_backups() {
    echo ""
    print_info "Available backups:"
    echo ""

    local backup_dir="${1:-/mnt/user/backups/logbook}"

    if [ ! -d "$backup_dir" ]; then
        print_error "Backup directory not found: $backup_dir"
        exit 1
    fi

    local backups=($(find "$backup_dir" -maxdepth 1 -type d -name "logbook_backup_*" | sort -r))

    if [ ${#backups[@]} -eq 0 ]; then
        print_error "No backups found in $backup_dir"
        exit 1
    fi

    local i=1
    for backup in "${backups[@]}"; do
        local backup_name=$(basename "$backup")
        local backup_date=$(echo "$backup_name" | sed 's/logbook_backup_//' | sed 's/_/ /')
        local backup_size=$(du -sh "$backup" | cut -f1)

        echo "  [$i] $backup_date ($backup_size)"

        # Show manifest if available
        if [ -f "$backup/MANIFEST.txt" ]; then
            local manifest_date=$(grep "Backup Date:" "$backup/MANIFEST.txt" | cut -d: -f2-)
            echo "      Created:$manifest_date"
        fi

        i=$((i+1))
    done

    echo ""
}

select_backup() {
    local backup_dir="${1:-/mnt/user/backups/logbook}"
    local backups=($(find "$backup_dir" -maxdepth 1 -type d -name "logbook_backup_*" | sort -r))

    read -p "Select backup number to restore (or 'q' to quit): " selection

    if [ "$selection" = "q" ]; then
        print_info "Restore cancelled"
        exit 0
    fi

    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backups[@]} ]; then
        print_error "Invalid selection"
        exit 1
    fi

    SELECTED_BACKUP="${backups[$((selection-1))]}"
    print_success "Selected: $(basename "$SELECTED_BACKUP")"
}

verify_backup() {
    print_info "Verifying backup integrity..."

    local required_files=("database.sql.gz" "MANIFEST.txt")

    for file in "${required_files[@]}"; do
        if [ ! -f "$SELECTED_BACKUP/$file" ]; then
            print_error "Backup is incomplete: missing $file"
            exit 1
        fi
    done

    print_success "Backup verification passed"
}

stop_containers() {
    print_warning "This will stop The Logbook and restore from backup"
    read -p "Are you sure you want to continue? (yes/NO): " confirmation

    if [ "$confirmation" != "yes" ]; then
        print_info "Restore cancelled"
        exit 0
    fi

    print_info "Stopping containers..."
    docker-compose down
    print_success "Containers stopped"
}

restore_database() {
    print_info "Restoring database..."

    # Start only database container
    docker-compose up -d db

    # Wait for database
    print_info "Waiting for database to be ready..."
    sleep 10

    # Drop and recreate database (clean slate)
    source .env
    docker-compose exec -T db psql -U "${POSTGRES_USER}" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" || true
    docker-compose exec -T db psql -U "${POSTGRES_USER}" -d postgres -c "CREATE DATABASE ${POSTGRES_DB};"

    # Restore from backup
    gunzip -c "${SELECTED_BACKUP}/database.sql.gz" | docker-compose exec -T db psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"

    print_success "Database restored"
}

restore_media() {
    print_info "Restoring media files..."

    if [ ! -f "${SELECTED_BACKUP}/media.tar.gz" ]; then
        print_warning "No media backup found, skipping"
        return
    fi

    # Remove old media
    docker volume rm logbook_media_volume 2>/dev/null || true
    docker volume create logbook_media_volume

    # Restore media
    docker run --rm \
        -v logbook_media_volume:/data \
        -v "${SELECTED_BACKUP}":/backup \
        alpine \
        tar xzf /backup/media.tar.gz -C /data

    print_success "Media files restored"
}

restore_static() {
    print_info "Restoring static files..."

    if [ ! -f "${SELECTED_BACKUP}/static.tar.gz" ]; then
        print_warning "No static files backup found, skipping"
        return
    fi

    # Remove old static
    docker volume rm logbook_static_volume 2>/dev/null || true
    docker volume create logbook_static_volume

    # Restore static
    docker run --rm \
        -v logbook_static_volume:/data \
        -v "${SELECTED_BACKUP}":/backup \
        alpine \
        tar xzf /backup/static.tar.gz -C /data

    print_success "Static files restored"
}

start_containers() {
    print_info "Starting all services..."

    docker-compose up -d

    print_info "Waiting for services to start..."
    sleep 15

    # Check health
    if docker-compose ps | grep -q "Up"; then
        print_success "All services started"
    else
        print_error "Some services failed to start"
        print_info "Check logs: docker-compose logs"
        exit 1
    fi
}

verify_restore() {
    print_info "Verifying restoration..."

    # Check database
    if ! docker-compose exec -T onboarding python manage.py check --database default >/dev/null 2>&1; then
        print_warning "Database verification failed"
        return 1
    fi

    # Check application
    if ! docker-compose exec -T onboarding python manage.py check >/dev/null 2>&1; then
        print_warning "Application verification failed"
        return 1
    fi

    print_success "Restoration verified"
}

print_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            Restore Completed Successfully! ✓               ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_success "The Logbook has been restored from backup"
    echo ""
    print_info "Restored from: $(basename "$SELECTED_BACKUP")"
    echo ""
    print_info "Access the application:"
    echo "  http://$(hostname -I | awk '{print $1}')"
    echo ""
    print_warning "If you encounter issues, check logs with:"
    echo "  docker-compose logs -f"
    echo ""
}

# Main execution
main() {
    print_header

    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Run from project root."
        exit 1
    fi

    local backup_dir="${1:-/mnt/user/backups/logbook}"

    show_available_backups "$backup_dir"
    select_backup "$backup_dir"
    verify_backup
    stop_containers
    restore_database
    restore_media
    restore_static
    start_containers
    verify_restore
    print_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [BACKUP_DIR]"
        echo ""
        echo "Arguments:"
        echo "  BACKUP_DIR    Directory containing backups (default: /mnt/user/backups/logbook)"
        echo ""
        echo "This script will:"
        echo "  1. Show available backups"
        echo "  2. Let you select which backup to restore"
        echo "  3. Stop The Logbook containers"
        echo "  4. Restore database, media, and static files"
        echo "  5. Restart all services"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
