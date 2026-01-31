"""
Models for The Logbook Onboarding Module
"""
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import EmailValidator, RegexValidator
from cryptography.fernet import Fernet
from django.conf import settings
import base64


class OnboardingConfig(models.Model):
    """
    Main configuration model for the onboarding process.
    Stores all settings configured during the 8-page onboarding flow.
    """
    # System Information
    organization_name = models.CharField(max_length=255, help_text="Fire Department Name")
    primary_color = models.CharField(
        max_length=7,
        default="#DC2626",
        validators=[RegexValidator(r'^#[0-9A-Fa-f]{6}$', 'Enter a valid hex color code')],
        help_text="Primary theme color (hex code)"
    )
    secondary_color = models.CharField(
        max_length=7,
        default="#1F2937",
        validators=[RegexValidator(r'^#[0-9A-Fa-f]{6}$', 'Enter a valid hex color code')],
        help_text="Secondary theme color (hex code)"
    )

    # Email Configuration (Page 2)
    email_backend = models.CharField(max_length=255, default='django.core.mail.backends.smtp.EmailBackend')
    email_host = models.CharField(max_length=255, blank=True)
    email_port = models.IntegerField(default=587)
    email_use_tls = models.BooleanField(default=True)
    email_use_ssl = models.BooleanField(default=False)
    email_host_user = models.CharField(max_length=255, blank=True)
    email_host_password_encrypted = models.TextField(blank=True, help_text="Encrypted email password")
    email_from_address = models.EmailField(validators=[EmailValidator()], blank=True)

    # Security Settings (Page 3)
    session_timeout_minutes = models.IntegerField(default=60, help_text="Session timeout in minutes")
    password_min_length = models.IntegerField(default=12, help_text="Minimum password length")
    require_2fa = models.BooleanField(default=False, help_text="Require two-factor authentication")
    allowed_domains = models.TextField(blank=True, help_text="Comma-separated list of allowed email domains")

    # File Storage Configuration (Page 4)
    storage_backend = models.CharField(
        max_length=50,
        choices=[('local', 'Local Storage'), ('s3', 'AWS S3')],
        default='local'
    )
    s3_bucket_name = models.CharField(max_length=255, blank=True)
    s3_access_key_encrypted = models.TextField(blank=True)
    s3_secret_key_encrypted = models.TextField(blank=True)
    s3_region = models.CharField(max_length=50, default='us-east-1', blank=True)

    # Integration Settings (Page 5-7 placeholders for future integrations)
    integrations_configured = models.JSONField(default=dict, blank=True)

    # Onboarding Status
    is_completed = models.BooleanField(default=False)
    current_step = models.IntegerField(default=1, help_text="Current onboarding step (1-8)")
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        verbose_name = "Onboarding Configuration"
        verbose_name_plural = "Onboarding Configurations"
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.organization_name} - Step {self.current_step}/8"

    @staticmethod
    def _get_encryption_key():
        """Get or generate encryption key for sensitive data"""
        key = settings.SECRET_KEY.encode()
        # Ensure key is 32 bytes for Fernet
        return base64.urlsafe_b64encode(key[:32].ljust(32, b'0'))

    def set_email_password(self, password):
        """Encrypt and store email password"""
        if password:
            f = Fernet(self._get_encryption_key())
            self.email_host_password_encrypted = f.encrypt(password.encode()).decode()

    def get_email_password(self):
        """Decrypt and return email password"""
        if self.email_host_password_encrypted:
            f = Fernet(self._get_encryption_key())
            return f.decrypt(self.email_host_password_encrypted.encode()).decode()
        return ''

    def set_s3_access_key(self, key):
        """Encrypt and store S3 access key"""
        if key:
            f = Fernet(self._get_encryption_key())
            self.s3_access_key_encrypted = f.encrypt(key.encode()).decode()

    def get_s3_access_key(self):
        """Decrypt and return S3 access key"""
        if self.s3_access_key_encrypted:
            f = Fernet(self._get_encryption_key())
            return f.decrypt(self.s3_access_key_encrypted.encode()).decode()
        return ''

    def set_s3_secret_key(self, key):
        """Encrypt and store S3 secret key"""
        if key:
            f = Fernet(self._get_encryption_key())
            self.s3_secret_key_encrypted = f.encrypt(key.encode()).decode()

    def get_s3_secret_key(self):
        """Decrypt and return S3 secret key"""
        if self.s3_secret_key_encrypted:
            f = Fernet(self._get_encryption_key())
            return f.decrypt(self.s3_secret_key_encrypted.encode()).decode()
        return ''


class OnboardingStep(models.Model):
    """
    Tracks individual steps in the onboarding process
    """
    config = models.ForeignKey(OnboardingConfig, on_delete=models.CASCADE, related_name='steps')
    step_number = models.IntegerField()
    step_name = models.CharField(max_length=100)
    is_completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)
    data = models.JSONField(default=dict, blank=True, help_text="Step-specific data")

    class Meta:
        unique_together = ['config', 'step_number']
        ordering = ['step_number']

    def __str__(self):
        return f"{self.config.organization_name} - Step {self.step_number}: {self.step_name}"
