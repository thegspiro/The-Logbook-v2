"""
Views for The Logbook Onboarding Module
"""
from django.shortcuts import render, redirect, get_object_or_404
from django.views import View
from django.contrib import messages
from django.utils import timezone
from .models import OnboardingConfig, OnboardingStep


class WelcomeView(View):
    """
    Landing page with fade-in animation.
    Displays welcome message and starts the onboarding process.
    """
    def get(self, request):
        # Check if onboarding is already completed
        completed_config = OnboardingConfig.objects.filter(is_completed=True).first()
        if completed_config:
            # Onboarding already done, could redirect to main app
            context = {
                'onboarding_completed': True,
                'organization_name': completed_config.organization_name,
            }
            return render(request, 'onboarding/welcome.html', context)

        # Check if there's an in-progress onboarding
        in_progress = OnboardingConfig.objects.filter(is_completed=False).first()

        context = {
            'onboarding_completed': False,
            'has_in_progress': in_progress is not None,
            'current_step': in_progress.current_step if in_progress else 1,
        }
        return render(request, 'onboarding/welcome.html', context)


class OnboardingStepView(View):
    """
    Generic view for onboarding steps.
    Handles the 8-page onboarding flow.
    """
    STEP_TEMPLATES = {
        1: 'onboarding/steps/step1_organization.html',
        2: 'onboarding/steps/step2_email.html',
        3: 'onboarding/steps/step3_security.html',
        4: 'onboarding/steps/step4_storage.html',
        5: 'onboarding/steps/step5_integrations.html',
        6: 'onboarding/steps/step6_users.html',
        7: 'onboarding/steps/step7_preferences.html',
        8: 'onboarding/steps/step8_review.html',
    }

    STEP_NAMES = {
        1: 'Organization Setup',
        2: 'Email Configuration',
        3: 'Security Settings',
        4: 'File Storage',
        5: 'External Integrations',
        6: 'User Management',
        7: 'Preferences',
        8: 'Review & Complete',
    }

    def get(self, request, step=1):
        """Display the onboarding step"""
        if step < 1 or step > 8:
            return redirect('onboarding:step', step=1)

        # Get or create onboarding config
        config = OnboardingConfig.objects.filter(is_completed=False).first()
        if not config:
            config = OnboardingConfig.objects.create(current_step=1)

        # Update current step if moving forward
        if step > config.current_step:
            config.current_step = step
            config.save()

        context = {
            'step': step,
            'total_steps': 8,
            'step_name': self.STEP_NAMES.get(step, f'Step {step}'),
            'config': config,
            'progress_percentage': int((step / 8) * 100),
        }

        template = self.STEP_TEMPLATES.get(step, 'onboarding/steps/step_base.html')
        return render(request, template, context)

    def post(self, request, step=1):
        """Handle form submission for each step"""
        config = OnboardingConfig.objects.filter(is_completed=False).first()
        if not config:
            messages.error(request, "Onboarding session not found. Please start again.")
            return redirect('onboarding:welcome')

        # Process step-specific data
        if step == 1:
            self._process_step1(request, config)
        elif step == 2:
            self._process_step2(request, config)
        elif step == 3:
            self._process_step3(request, config)
        elif step == 4:
            self._process_step4(request, config)
        elif step == 8:
            # Final step - mark as completed
            config.is_completed = True
            config.completed_at = timezone.now()
            config.save()
            messages.success(request, "Onboarding completed successfully!")
            return redirect('onboarding:welcome')

        # Move to next step
        next_step = step + 1
        if next_step <= 8:
            return redirect('onboarding:step', step=next_step)

        return redirect('onboarding:welcome')

    def _process_step1(self, request, config):
        """Process organization setup"""
        config.organization_name = request.POST.get('organization_name', '')
        config.primary_color = request.POST.get('primary_color', '#DC2626')
        config.secondary_color = request.POST.get('secondary_color', '#1F2937')
        config.save()

    def _process_step2(self, request, config):
        """Process email configuration"""
        config.email_host = request.POST.get('email_host', '')
        config.email_port = int(request.POST.get('email_port', 587))
        config.email_use_tls = request.POST.get('email_use_tls') == 'on'
        config.email_host_user = request.POST.get('email_host_user', '')
        config.email_from_address = request.POST.get('email_from_address', '')

        # Encrypt and store password
        password = request.POST.get('email_host_password', '')
        if password:
            config.set_email_password(password)

        config.save()

    def _process_step3(self, request, config):
        """Process security settings"""
        config.session_timeout_minutes = int(request.POST.get('session_timeout', 60))
        config.password_min_length = int(request.POST.get('password_min_length', 12))
        config.require_2fa = request.POST.get('require_2fa') == 'on'
        config.allowed_domains = request.POST.get('allowed_domains', '')
        config.save()

    def _process_step4(self, request, config):
        """Process file storage configuration"""
        config.storage_backend = request.POST.get('storage_backend', 'local')

        if config.storage_backend == 's3':
            config.s3_bucket_name = request.POST.get('s3_bucket_name', '')
            config.s3_region = request.POST.get('s3_region', 'us-east-1')

            # Encrypt and store S3 credentials
            access_key = request.POST.get('s3_access_key', '')
            secret_key = request.POST.get('s3_secret_key', '')
            if access_key:
                config.set_s3_access_key(access_key)
            if secret_key:
                config.set_s3_secret_key(secret_key)

        config.save()
