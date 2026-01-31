#!/bin/bash
################################################################################
# The Logbook - Raspberry Pi Setup Script
#
# This script automates the installation of The Logbook on Raspberry Pi
# Compatible with: Pi 3B+, Pi 4, Pi 5
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
    echo "║      The Logbook - Raspberry Pi Setup Script              ║"
    echo "║     Fire Department Intranet Platform Installer           ║"
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

detect_pi_model() {
    print_info "Detecting Raspberry Pi model..."

    PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")

    if echo "$PI_MODEL" | grep -q "Raspberry Pi 5"; then
        PI_VERSION="5"
        RAM_GB=8
        RECOMMENDED_WORKERS=6
    elif echo "$PI_MODEL" | grep -q "Raspberry Pi 4"; then
        PI_VERSION="4"
        RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [ "$RAM_GB" -ge 4 ]; then
            RECOMMENDED_WORKERS=4
        else
            RECOMMENDED_WORKERS=2
        fi
    elif echo "$PI_MODEL" | grep -q "Raspberry Pi 3"; then
        PI_VERSION="3"
        RAM_GB=1
        RECOMMENDED_WORKERS=2
    else
        print_warning "Could not detect Raspberry Pi model"
        print_info "Model detected: $PI_MODEL"
        PI_VERSION="unknown"
        RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        RECOMMENDED_WORKERS=2
    fi

    print_success "Detected: Raspberry Pi $PI_VERSION with ${RAM_GB}GB RAM"
}

check_requirements() {
    print_info "Checking system requirements..."

    # Check if running on ARM
    ARCH=$(uname -m)
    if [[ ! "$ARCH" =~ ^(aarch64|armv7l|armv8)$ ]]; then
        print_error "This script is for ARM architecture (Raspberry Pi)"
        print_info "Detected architecture: $ARCH"
        exit 1
    fi
    print_success "ARM architecture detected: $ARCH"

    # Check available disk space (need at least 5GB)
    available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -lt 5 ]; then
        print_error "Insufficient disk space. Need at least 5GB, have ${available_space}GB"
        exit 1
    fi
    print_success "Sufficient disk space available (${available_space}GB)"

    # Check RAM
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 900 ]; then
        print_error "Insufficient RAM. Need at least 1GB"
        exit 1
    fi
    print_success "Sufficient RAM available (${total_ram}MB)"
}

check_temperature() {
    if command -v vcgencmd &> /dev/null; then
        TEMP=$(vcgencmd measure_temp | sed 's/temp=//' | sed 's/°C//' | sed "s/'C//")
        print_info "Current temperature: ${TEMP}°C"

        if (( $(echo "$TEMP > 75" | bc -l 2>/dev/null || echo "0") )); then
            print_warning "Temperature is high (${TEMP}°C). Consider adding cooling."
        fi
    fi
}

update_system() {
    print_info "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    print_success "System updated"
}

install_dependencies() {
    print_info "Installing required packages..."
    sudo apt install -y git curl wget vim bc
    print_success "Dependencies installed"
}

install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        return
    fi

    print_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh

    # Add user to docker group
    sudo usermod -aG docker $USER

    print_success "Docker installed"
    print_warning "You may need to log out and back in for docker group to take effect"
}

install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is already installed"
        return
    fi

    print_info "Installing Docker Compose..."
    sudo apt install -y docker-compose
    print_success "Docker Compose installed"
}

configure_swap() {
    if [ "$RAM_GB" -ge 4 ]; then
        print_info "Sufficient RAM (${RAM_GB}GB), swap configuration skipped"
        return
    fi

    print_info "Configuring swap for low RAM..."

    # Determine swap size based on RAM
    if [ "$RAM_GB" -le 1 ]; then
        SWAP_SIZE=4096
    else
        SWAP_SIZE=2048
    fi

    print_info "Setting swap to ${SWAP_SIZE}MB..."

    sudo dphys-swapfile swapoff 2>/dev/null || true
    sudo sed -i "s/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=${SWAP_SIZE}/" /etc/dphys-swapfile
    sudo dphys-swapfile setup
    sudo dphys-swapfile swapon

    print_success "Swap configured to ${SWAP_SIZE}MB"
}

clone_repository() {
    print_info "Cloning The Logbook repository..."

    if [ -d "$HOME/The-Logbook-v2" ]; then
        print_warning "Directory already exists"
        read -p "Remove and re-clone? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/The-Logbook-v2"
        else
            print_info "Using existing directory"
            return
        fi
    fi

    cd ~
    git clone https://github.com/thegspiro/The-Logbook-v2.git
    print_success "Repository cloned"
}

generate_secrets() {
    print_info "Generating secure secrets..."
    DJANGO_SECRET=$(openssl rand -base64 50)
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    print_success "Secrets generated"
}

configure_environment() {
    print_info "Configuring environment..."

    cd ~/The-Logbook-v2

    # Copy Pi-specific environment template
    cp raspberry-pi/.env.pi.example .env

    # Get Pi's IP address
    PI_IP=$(hostname -I | awk '{print $1}')

    # Get user input
    echo ""
    print_info "Please provide the following information:"
    echo ""

    read -p "Your fire department name (e.g., Volunteer Fire Company 1): " DEPT_NAME
    if [ -z "$DEPT_NAME" ]; then
        DEPT_NAME="Volunteer Fire Company"
    fi

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
    sed -i "s|DJANGO_ALLOWED_HOSTS=.*|DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,${PI_IP},$(hostname).local|" .env
    sed -i "s|ORGANIZATION_NAME=.*|ORGANIZATION_NAME=${DEPT_NAME}|" .env
    sed -i "s|PRIMARY_COLOR=.*|PRIMARY_COLOR=${PRIMARY_COLOR}|" .env
    sed -i "s|SECONDARY_COLOR=.*|SECONDARY_COLOR=${SECONDARY_COLOR}|" .env

    # Set production mode
    sed -i "s|DJANGO_DEBUG=.*|DJANGO_DEBUG=False|" .env

    # Configure for detected Pi model
    if [ "$PI_VERSION" == "5" ]; then
        sed -i 's/^# DB_MEMORY_LIMIT=2048m/DB_MEMORY_LIMIT=2048m/' .env
        sed -i 's/^# APP_MEMORY_LIMIT=2048m/APP_MEMORY_LIMIT=2048m/' .env
        sed -i 's/^# GUNICORN_WORKERS=6/GUNICORN_WORKERS=6/' .env
    elif [ "$RAM_GB" -le 1 ]; then
        sed -i 's/^# DB_MEMORY_LIMIT=256m/DB_MEMORY_LIMIT=256m/' .env
        sed -i 's/^# APP_MEMORY_LIMIT=256m/APP_MEMORY_LIMIT=256m/' .env
        sed -i 's/^# GUNICORN_WORKERS=2/GUNICORN_WORKERS=2/' .env
    elif [ "$RAM_GB" -le 2 ]; then
        sed -i 's/^# DB_MEMORY_LIMIT=512m/DB_MEMORY_LIMIT=512m/' .env
        sed -i 's/^# APP_MEMORY_LIMIT=512m/APP_MEMORY_LIMIT=512m/' .env
        sed -i 's/^# GUNICORN_WORKERS=2/GUNICORN_WORKERS=2/' .env
    fi

    print_success "Environment configured"

    # Save credentials to a file
    cat > .credentials.txt <<EOF
The Logbook - Installation Credentials
Generated: $(date)

IMPORTANT: Keep this file secure and delete it after recording the information!

Raspberry Pi IP: ${PI_IP}
PostgreSQL Database Password: ${POSTGRES_PASSWORD}
Django Secret Key: ${DJANGO_SECRET}
Department: ${DEPT_NAME}

After installation, access The Logbook at:
http://${PI_IP}

Complete the onboarding wizard, then create an admin user with:
cd ~/The-Logbook-v2
docker-compose -f raspberry-pi/docker-compose.pi.yml exec onboarding python manage.py createsuperuser

REMEMBER TO DELETE THIS FILE AFTER SETUP!
EOF

    chmod 600 .credentials.txt
    print_warning "Credentials saved to ~/The-Logbook-v2/.credentials.txt - KEEP THIS SECURE!"
}

deploy_stack() {
    print_info "Building and deploying The Logbook..."

    cd ~/The-Logbook-v2

    # Build and start containers
    print_info "Building Docker images (this may take 5-15 minutes on Raspberry Pi)..."
    docker-compose -f raspberry-pi/docker-compose.pi.yml build

    print_info "Starting services..."
    docker-compose -f raspberry-pi/docker-compose.pi.yml up -d

    print_success "Containers started"
}

wait_for_services() {
    print_info "Waiting for services to be ready..."

    sleep 15

    # Check if containers are running
    if ! docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml ps | grep -q "Up"; then
        print_error "Some containers failed to start"
        print_info "Check logs with: cd ~/The-Logbook-v2 && docker-compose -f raspberry-pi/docker-compose.pi.yml logs"
        exit 1
    fi

    print_success "All services are running"
}

run_migrations() {
    print_info "Running database migrations..."

    cd ~/The-Logbook-v2

    sleep 10  # Give database time to fully start

    docker-compose -f raspberry-pi/docker-compose.pi.yml exec -T onboarding python manage.py migrate
    print_success "Database migrations completed"

    print_info "Collecting static files..."
    docker-compose -f raspberry-pi/docker-compose.pi.yml exec -T onboarding python manage.py collectstatic --noinput
    print_success "Static files collected"
}

create_backup_script() {
    print_info "Creating backup script..."

    cat > ~/backup-logbook.sh <<'EOF'
#!/bin/bash
cd ~/The-Logbook-v2
./scripts/backup.sh
EOF

    chmod +x ~/backup-logbook.sh
    print_success "Backup script created at ~/backup-logbook.sh"

    print_info "To schedule daily backups, run: crontab -e"
    print_info "Then add: 0 2 * * * /home/pi/backup-logbook.sh >> /home/pi/backup.log 2>&1"
}

print_completion() {
    PI_IP=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          The Logbook Installation Complete! ✓             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    print_info "Raspberry Pi Model: $PI_MODEL"
    print_info "IP Address: $PI_IP"
    echo ""
    print_info "Next steps:"
    echo ""
    echo "1. Access the onboarding wizard:"
    echo -e "   ${BLUE}http://${PI_IP}${NC}"
    echo ""
    echo "2. Complete the 8-step onboarding process"
    echo ""
    echo "3. After onboarding, create an admin account:"
    echo -e "   ${YELLOW}cd ~/The-Logbook-v2${NC}"
    echo -e "   ${YELLOW}docker-compose -f raspberry-pi/docker-compose.pi.yml exec onboarding python manage.py createsuperuser${NC}"
    echo ""
    echo "4. Access the admin panel:"
    echo -e "   ${BLUE}http://${PI_IP}/admin${NC}"
    echo ""
    print_warning "IMPORTANT: Review ~/The-Logbook-v2/.credentials.txt, then DELETE it!"
    echo ""
    print_info "Useful commands:"
    echo "  • View logs: docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml logs -f"
    echo "  • Stop: docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml down"
    echo "  • Restart: docker-compose -f ~/The-Logbook-v2/raspberry-pi/docker-compose.pi.yml restart"
    echo "  • Backup: ~/backup-logbook.sh"
    echo "  • Temperature: vcgencmd measure_temp"
    echo ""
    print_info "For documentation, see:"
    echo "  • ~/The-Logbook-v2/docs/RASPBERRY_PI.md"
    echo "  • ~/The-Logbook-v2/README.md"
    echo ""
}

# Main execution
main() {
    print_header

    detect_pi_model
    check_requirements
    check_temperature

    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    update_system
    install_dependencies
    install_docker
    install_docker_compose
    configure_swap
    clone_repository
    generate_secrets
    configure_environment
    deploy_stack
    wait_for_services
    run_migrations
    create_backup_script
    print_completion
}

# Run main function
main
