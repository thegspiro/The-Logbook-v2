"""
App configuration for The Logbook Onboarding Module
"""
from django.apps import AppConfig


class OnboardingAppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'onboarding_app'
    verbose_name = 'Onboarding'

    def ready(self):
        """
        Import signals or perform startup tasks
        """
        pass
