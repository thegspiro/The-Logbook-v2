"""
Tests for The Logbook Onboarding Module
"""
from django.test import TestCase, Client
from django.urls import reverse
from .models import OnboardingConfig


class OnboardingWelcomeViewTest(TestCase):
    """Test cases for the welcome view"""

    def setUp(self):
        self.client = Client()

    def test_welcome_page_loads(self):
        """Test that the welcome page loads successfully"""
        response = self.client.get(reverse('onboarding:welcome'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Welcome to The Logbook')

    def test_welcome_page_with_completed_onboarding(self):
        """Test welcome page when onboarding is complete"""
        config = OnboardingConfig.objects.create(
            organization_name="Test Fire Department",
            is_completed=True
        )
        response = self.client.get(reverse('onboarding:welcome'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Welcome Back')


class OnboardingConfigModelTest(TestCase):
    """Test cases for the OnboardingConfig model"""

    def test_create_config(self):
        """Test creating an onboarding configuration"""
        config = OnboardingConfig.objects.create(
            organization_name="Springfield VFD",
            primary_color="#DC2626",
            secondary_color="#1F2937"
        )
        self.assertEqual(config.organization_name, "Springfield VFD")
        self.assertEqual(config.current_step, 1)
        self.assertFalse(config.is_completed)

    def test_password_encryption(self):
        """Test that passwords are encrypted"""
        config = OnboardingConfig.objects.create(organization_name="Test Dept")
        test_password = "super_secret_password"
        config.set_email_password(test_password)
        config.save()

        # Encrypted value should not be the plain text
        self.assertNotEqual(config.email_host_password_encrypted, test_password)

        # Decryption should return original password
        self.assertEqual(config.get_email_password(), test_password)

    def test_s3_key_encryption(self):
        """Test that S3 keys are encrypted"""
        config = OnboardingConfig.objects.create(organization_name="Test Dept")
        access_key = "AKIAIOSFODNN7EXAMPLE"
        secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

        config.set_s3_access_key(access_key)
        config.set_s3_secret_key(secret_key)
        config.save()

        self.assertNotEqual(config.s3_access_key_encrypted, access_key)
        self.assertNotEqual(config.s3_secret_key_encrypted, secret_key)

        self.assertEqual(config.get_s3_access_key(), access_key)
        self.assertEqual(config.get_s3_secret_key(), secret_key)


class OnboardingStepViewTest(TestCase):
    """Test cases for onboarding step views"""

    def setUp(self):
        self.client = Client()

    def test_step1_loads(self):
        """Test that step 1 loads successfully"""
        response = self.client.get(reverse('onboarding:step', kwargs={'step': 1}))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Organization Setup')

    def test_step1_submission(self):
        """Test submitting step 1 data"""
        response = self.client.post(reverse('onboarding:step', kwargs={'step': 1}), {
            'organization_name': 'Test Fire Department',
            'primary_color': '#DC2626',
            'secondary_color': '#1F2937',
        })
        self.assertEqual(response.status_code, 302)  # Should redirect to step 2

        # Verify config was created
        config = OnboardingConfig.objects.first()
        self.assertIsNotNone(config)
        self.assertEqual(config.organization_name, 'Test Fire Department')

    def test_invalid_step_redirects(self):
        """Test that invalid step numbers redirect to step 1"""
        response = self.client.get(reverse('onboarding:step', kwargs={'step': 99}))
        self.assertEqual(response.status_code, 302)
