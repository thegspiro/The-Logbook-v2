#!/bin/bash
################################################################################
# The Logbook - Unraid Setup Script
#
# This script automates the initial setup of The Logbook on Unraid servers.
# It will guide you through configuration and deployment.
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           The Logbook - Unraid Setup Script               ║"
    echo "║     Fire Department Intranet Platform Setup Wizard        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_requirements() {
    print_info "Checking system requirements..."

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker is installed"

    # Check if Docker Compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        print_info "Please install Docker Compose or use the Docker Compose Manager plugin in Unraid"
        exit 1
    fi
    print_success "Docker Compose is installed"

    # Check available disk space (need at least 5GB)
    available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        print_warning "Less than 5GB of disk space available. Recommended: 10GB+"
    else
        print_success "Sufficient disk space available (${available_space}GB)"
    fi
}

generate_secret_key() {
    python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())' 2>/dev/null || \
    openssl rand -base64 50 | tr -d "=+/" | cut -c1-50
}

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-24
}

setup_environment() {
    print_info "Setting up environment configuration..."

    if [ -f .env ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return
        fi
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        print_success "Backed up existing .env file"
    fi

    # Copy example file
    cp .env.example .env

    # Generate secrets
    print_info "Generating secure secrets..."
    DJANGO_SECRET=$(generate_secret_key)
    POSTGRES_PASSWORD=$(generate_password)

    # Get user input
    echo ""
    print_info "Please provide the following information:"
    echo ""

    read -p "Your Unraid server IP address (e.g., 192.168.1.100): " SERVER_IP
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="localhost"
    fi

    read -p "Your fire department name (e.g., Volunteer Fire Company 1): " DEPT_NAME

    read -p "Primary color (hex code, e.g., #DC2626 for red): " PRIMARY_COLOR
    if [ -z "$PRIMARY_COLOR" ]; then
        PRIMARY_COLOR="#DC2626"
    fi

    read -p "Secondary color (hex code, e.g., #1F2937 for dark gray): " SECONDARY_COLOR
    if [ -z "$SECONDARY_COLOR" ]; then
        SECONDARY_COLOR="#1F2937"
    fi

    # Update .env file
    sed -i "s|DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=${DJANGO_SECRET}|" .env
    sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|" .env
    sed -i "s|DJANGO_ALLOWED_HOSTS=.*|DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,${SERVER_IP}|" .env
    sed -i "s|PRIMARY_COLOR=.*|PRIMARY_COLOR=${PRIMARY_COLOR}|" .env
    sed -i "s|SECONDARY_COLOR=.*|SECONDARY_COLOR=${SECONDARY_COLOR}|" .env

    # Set production settings
    sed -i "s|DJANGO_DEBUG=.*|DJANGO_DEBUG=False|" .env

    print_success "Environment file configured"

    # Save credentials to a secure file
    cat > .credentials.txt <<EOF
The Logbook - Installation Credentials
Generated: $(date)

IMPORTANT: Keep this file secure and delete it after recording the information!

PostgreSQL Database Password: ${POSTGRES_PASSWORD}
Django Secret Key: ${DJANGO_SECRET}
Server IP: ${SERVER_IP}
Department: ${DEPT_NAME}

After installation, you'll need to create an admin user with:
docker-compose exec onboarding python manage.py createsuperuser

REMEMBER TO DELETE THIS FILE AFTER SETUP!
EOF

    chmod 600 .credentials.txt
    print_warning "Credentials saved to .credentials.txt - KEEP THIS SECURE!"
}

check_ports() {
    print_info "Checking if required ports are available..."

    PORTS=(80 443 5432 8000)
    PORTS_IN_USE=()

    for port in "${PORTS[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "; then
            PORTS_IN_USE+=($port)
            print_warning "Port $port is already in use"
        fi
    done

    if [ ${#PORTS_IN_USE[@]} -gt 0 ]; then
        print_warning "Some ports are in use: ${PORTS_IN_USE[*]}"
        print_info "You may need to modify docker-compose.yml to use different ports"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All required ports are available"
    fi
}

deploy_stack() {
    print_info "Building and deploying The Logbook..."

    # Pull latest images
    docker-compose pull

    # Build the application
    print_info "Building application containers (this may take a few minutes)..."
    docker-compose build --no-cache

    # Start the stack
    print_info "Starting services..."
    docker-compose up -d

    print_success "Containers started"

    # Wait for database to be ready
    print_info "Waiting for database to initialize..."
    sleep 10

    # Check if containers are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Some containers failed to start"
        print_info "Check logs with: docker-compose logs"
        exit 1
    fi

    print_success "All services are running"
}

run_migrations() {
    print_info "Running database migrations..."

    # Wait a bit more for the app to be ready
    sleep 5

    docker-compose exec -T onboarding python manage.py migrate --noinput
    print_success "Database migrations completed"

    # Collect static files
    print_info "Collecting static files..."
    docker-compose exec -T onboarding python manage.py collectstatic --noinput
    print_success "Static files collected"
}

print_completion() {
    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              The Logbook Setup Complete! ✓                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    print_info "Next steps:"
    echo ""
    echo "1. Access the onboarding wizard at:"
    echo -e "   ${BLUE}http://${SERVER_IP}${NC}"
    echo ""
    echo "2. Complete the 8-step onboarding process to configure:"
    echo "   • Organization details and theme"
    echo "   • Email settings"
    echo "   • Security policies"
    echo "   • File storage"
    echo "   • User preferences"
    echo ""
    echo "3. After onboarding, create an admin account:"
    echo -e "   ${YELLOW}docker-compose exec onboarding python manage.py createsuperuser${NC}"
    echo ""
    echo "4. Access the admin panel at:"
    echo -e "   ${BLUE}http://${SERVER_IP}/admin${NC}"
    echo ""
    print_warning "IMPORTANT: Review and secure .credentials.txt, then DELETE it!"
    echo ""
    echo "For help and documentation, see:"
    echo "  • README.md"
    echo "  • DEPLOYMENT.md"
    echo "  • docs/UNRAID.md"
    echo ""
    print_info "Useful commands:"
    echo "  • View logs: docker-compose logs -f"
    echo "  • Stop: docker-compose down"
    echo "  • Restart: docker-compose restart"
    echo "  • Backup: ./scripts/backup.sh"
    echo ""
}

# Main execution
main() {
    print_header

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run this script from the project root directory."
        exit 1
    fi

    check_requirements
    check_ports
    setup_environment
    deploy_stack
    run_migrations
    print_completion
}

# Run main function
main
