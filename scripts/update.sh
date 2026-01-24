#!/bin/bash
################################################################################
# The Logbook - Update Script
#
# This script safely updates The Logbook to the latest version
# It will:
# - Create a backup before updating
# - Pull latest code
# - Rebuild containers
# - Run database migrations
# - Restart services
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
    echo "║           The Logbook - Update Script                     ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

check_prerequisites() {
    print_info "Checking prerequisites..."

    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Run from project root."
        exit 1
    fi

    if ! docker-compose ps | grep -q "Up"; then
        print_warning "Containers are not running"
        read -p "Do you want to start them first? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose up -d
            sleep 10
        else
            print_error "Update requires running containers"
            exit 1
        fi
    fi

    print_success "Prerequisites satisfied"
}

create_backup() {
    print_info "Creating backup before update..."

    if [ -f "./scripts/backup.sh" ]; then
        chmod +x ./scripts/backup.sh
        BACKUP_DIR="/mnt/user/backups/logbook/pre-update" ./scripts/backup.sh
        print_success "Pre-update backup created"
    else
        print_warning "Backup script not found, proceeding without backup"
        read -p "Continue without backup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_git_status() {
    print_info "Checking for updates..."

    if [ -d ".git" ]; then
        # Save current branch
        CURRENT_BRANCH=$(git branch --show-current)

        # Fetch latest
        git fetch origin

        # Check if updates are available
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

        if [ -z "$REMOTE" ]; then
            print_warning "Not tracking a remote branch"
            return 1
        elif [ "$LOCAL" = "$REMOTE" ]; then
            print_success "Already up to date!"
            read -p "Rebuild containers anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
            return 2
        else
            COMMITS_BEHIND=$(git rev-list HEAD..@{u} --count)
            print_info "Updates available: ${COMMITS_BEHIND} new commits"
            return 0
        fi
    else
        print_warning "Not a git repository, cannot check for updates"
        return 1
    fi
}

pull_updates() {
    if [ -d ".git" ]; then
        print_info "Pulling latest code..."

        # Check for local changes
        if ! git diff-index --quiet HEAD --; then
            print_warning "Local changes detected"
            print_info "Stashing local changes..."
            git stash
            STASHED=true
        fi

        # Pull updates
        git pull origin $(git branch --show-current)

        if [ "$STASHED" = true ]; then
            print_info "Re-applying local changes..."
            git stash pop || {
                print_warning "Could not auto-apply stashed changes"
                print_info "Run 'git stash pop' manually to restore changes"
            }
        fi

        print_success "Code updated"
    else
        print_info "Skipping git pull (not a git repository)"
    fi
}

stop_services() {
    print_info "Stopping services gracefully..."
    docker-compose down --timeout 30
    print_success "Services stopped"
}

rebuild_containers() {
    print_info "Rebuilding containers with latest code..."
    docker-compose build --pull --no-cache
    print_success "Containers rebuilt"
}

start_services() {
    print_info "Starting updated services..."
    docker-compose up -d
    print_success "Services started"

    print_info "Waiting for services to be ready..."
    sleep 15
}

run_migrations() {
    print_info "Running database migrations..."

    docker-compose exec -T onboarding python manage.py migrate --noinput
    print_success "Migrations completed"
}

collect_static() {
    print_info "Collecting static files..."

    docker-compose exec -T onboarding python manage.py collectstatic --noinput
    print_success "Static files collected"
}

verify_health() {
    print_info "Verifying service health..."

    # Check if containers are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Some services failed to start"
        print_info "Check logs with: docker-compose logs"
        return 1
    fi

    # Check database connectivity
    if ! docker-compose exec -T onboarding python manage.py check --database default >/dev/null 2>&1; then
        print_warning "Database health check failed"
        return 1
    fi

    print_success "All services are healthy"
    return 0
}

show_changelog() {
    if [ -d ".git" ]; then
        echo ""
        print_info "Recent changes:"
        echo ""
        git log --oneline --decorate -5
        echo ""
    fi
}

print_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              Update Completed Successfully! ✓              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_success "The Logbook has been updated to the latest version"
    echo ""
    print_info "What's next?"
    echo "  • Review recent changes above"
    echo "  • Check the application: http://$(hostname -I | awk '{print $1}')"
    echo "  • View logs if needed: docker-compose logs -f"
    echo "  • Review release notes in the repository"
    echo ""
}

rollback() {
    print_error "Update failed!"
    echo ""
    print_info "To rollback to the previous version:"
    echo "  1. Stop containers: docker-compose down"
    echo "  2. Restore from backup (see backup MANIFEST.txt)"
    echo "  3. Restart: docker-compose up -d"
    echo ""
    exit 1
}

# Main execution
main() {
    print_header

    # Set error handler
    trap rollback ERR

    check_prerequisites

    # Confirm update
    read -p "This will update The Logbook to the latest version. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Update cancelled"
        exit 0
    fi

    create_backup
    check_git_status
    pull_updates
    stop_services
    rebuild_containers
    start_services
    run_migrations
    collect_static

    if verify_health; then
        show_changelog
        print_summary
    else
        print_error "Health check failed after update"
        print_info "The application may still be starting. Check logs: docker-compose logs -f"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h           Show this help message"
        echo "  --force              Skip confirmation prompts"
        echo "  --no-backup          Skip pre-update backup (not recommended)"
        echo ""
        echo "This script will:"
        echo "  1. Create a backup of current installation"
        echo "  2. Pull latest code from git"
        echo "  3. Rebuild Docker containers"
        echo "  4. Run database migrations"
        echo "  5. Restart all services"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac
