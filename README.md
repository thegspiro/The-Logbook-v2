# The Logbook

An open-source intranet platform designed specifically for volunteer fire departments. Built with Django, PostgreSQL, and Docker for easy deployment and scalability.

## Features

- **Modular Architecture**: Microservices-based design for flexibility and scalability
- **Customizable Theming**: Set department colors with Section 508/WCAG 2.1 compliance
- **Secure by Design**: Encrypted credentials, strong password policies, optional 2FA
- **Easy Deployment**: Docker-ready for quick setup on any platform
- **Core Modules** (coming soon):
  - Personnel Management
  - Incident Reporting
  - Equipment Tracking
  - Training & Scheduling
  - Communications

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB of available RAM
- Ports 80, 443, 5432, and 8000 available

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/The-Logbook-v2.git
   cd The-Logbook-v2
   ```

2. **Create your environment file:**
   ```bash
   cp .env.example .env
   ```

3. **Edit the `.env` file with your settings:**
   ```bash
   nano .env
   ```

   **Important**: Change these values:
   - `POSTGRES_PASSWORD`: Set a strong database password
   - `DJANGO_SECRET_KEY`: Generate a random secret key (see below)
   - `DJANGO_ALLOWED_HOSTS`: Add your domain or IP address

   To generate a secure Django secret key:
   ```bash
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

4. **Build and start the containers:**
   ```bash
   docker-compose up -d --build
   ```

5. **Wait for services to initialize** (about 30-60 seconds on first run)

6. **Access the onboarding wizard:**
   Open your browser and navigate to: `http://localhost` or `http://your-server-ip`

7. **Complete the 8-step onboarding process** to configure:
   - Organization details and theme colors
   - Email settings
   - Security policies
   - File storage (local or AWS S3)
   - User preferences

### Post-Installation

After completing onboarding:

1. **Create a superuser account:**
   ```bash
   docker-compose exec onboarding python manage.py createsuperuser
   ```

2. **Access the admin panel:**
   Navigate to: `http://localhost/admin`

3. **Add users and configure modules** through the admin interface

## Unraid Deployment

The Logbook is designed to work seamlessly with Unraid:

1. Install the **Docker Compose Manager** plugin from Community Applications
2. Create a new stack with the `docker-compose.yml` file
3. Configure your environment variables
4. Deploy the stack

Alternatively, use Portainer for a web-based Docker management interface.

## Architecture

The Logbook uses a microservices architecture:

```
The-Logbook-v2/
├── services/
│   └── onboarding/          # Onboarding microservice
│       ├── onboarding_app/  # Django app
│       ├── Dockerfile
│       └── requirements.txt
├── nginx/                   # Reverse proxy configuration
├── docker-compose.yml       # Container orchestration
└── .env                     # Environment configuration
```

## Security Features

- **Password Security**: Uses Argon2 hashing with configurable minimum length
- **Encrypted Credentials**: Email and S3 credentials encrypted at rest using Fernet
- **Session Management**: Configurable timeout and secure cookie settings
- **HTTPS Support**: Nginx configuration ready for SSL/TLS certificates
- **CSRF Protection**: Django CSRF middleware enabled
- **SQL Injection Prevention**: Django ORM with parameterized queries
- **XSS Protection**: Template auto-escaping and Content Security headers

## Development

### Running Tests

```bash
docker-compose exec onboarding python manage.py test
```

### Building Tailwind CSS

```bash
docker-compose exec onboarding npm run build:css
```

### Creating Database Migrations

```bash
docker-compose exec onboarding python manage.py makemigrations
docker-compose exec onboarding python manage.py migrate
```

### Viewing Logs

```bash
docker-compose logs -f onboarding  # Application logs
docker-compose logs -f db          # Database logs
docker-compose logs -f nginx       # Web server logs
```

## Configuration

### Environment Variables

See `.env.example` for all available configuration options.

Key variables:
- `POSTGRES_*`: Database configuration
- `DJANGO_SECRET_KEY`: Application secret (keep secure!)
- `DJANGO_DEBUG`: Set to `False` in production
- `DJANGO_ALLOWED_HOSTS`: Comma-separated list of allowed domains/IPs
- `PRIMARY_COLOR` / `SECONDARY_COLOR`: Default theme colors (hex codes)

### Email Configuration

Configure in the onboarding wizard or directly in `.env`:
- SMTP host, port, and credentials
- TLS/SSL encryption settings
- From address for system emails

### File Storage

Choose between:
- **Local Storage**: Files stored in Docker volumes
- **AWS S3**: Cloud storage with unlimited capacity

## Updating

To update The Logbook:

```bash
git pull origin main
docker-compose down
docker-compose up -d --build
docker-compose exec onboarding python manage.py migrate
```

## Backup

### Database Backup

```bash
docker-compose exec db pg_dump -U logbook_user logbook_db > backup_$(date +%Y%m%d).sql
```

### Restore Database

```bash
cat backup_20240101.sql | docker-compose exec -T db psql -U logbook_user logbook_db
```

### Full Backup

Backup Docker volumes:
```bash
docker run --rm -v logbook_postgres_data:/data -v $(pwd):/backup ubuntu tar czf /backup/postgres_backup.tar.gz /data
docker run --rm -v logbook_media_volume:/data -v $(pwd):/backup ubuntu tar czf /backup/media_backup.tar.gz /data
```

## Troubleshooting

### Container won't start

Check logs:
```bash
docker-compose logs onboarding
```

Common issues:
- Port already in use: Change ports in `docker-compose.yml`
- Database not ready: Wait 30 seconds and try again
- Permission errors: Ensure Docker has appropriate permissions

### Can't access the application

1. Verify containers are running: `docker-compose ps`
2. Check firewall settings
3. Verify `DJANGO_ALLOWED_HOSTS` includes your domain/IP
4. Check nginx logs: `docker-compose logs nginx`

### Database connection errors

1. Ensure database container is healthy: `docker-compose ps`
2. Verify credentials in `.env` match
3. Try restarting: `docker-compose restart db`

### Static files not loading

Run collectstatic:
```bash
docker-compose exec onboarding python manage.py collectstatic --noinput
```

## Contributing

We welcome contributions! This is an open-source project built for the firefighting community.

### How to Contribute

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Guidelines

- Follow PEP 8 for Python code
- Write tests for new features
- Update documentation as needed
- Ensure Section 508/WCAG 2.1 compliance for UI changes
- Keep dependencies up to date

## Roadmap

- [ ] Complete onboarding module (current)
- [ ] Personnel management module
- [ ] Incident reporting module
- [ ] Equipment tracking module
- [ ] Training & scheduling module
- [ ] Communications module
- [ ] Mobile app (iOS/Android)
- [ ] API for third-party integrations
- [ ] Multi-language support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [Wiki](https://github.com/yourusername/The-Logbook-v2/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/The-Logbook-v2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/The-Logbook-v2/discussions)

## Acknowledgments

Built with love for the volunteer firefighting community. Thank you to all contributors and the open-source community for making this possible.

---

**Stay Safe. Stay Connected. The Logbook.**