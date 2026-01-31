"""
Admin configuration for The Logbook Onboarding Module
"""
from django.contrib import admin
from .models import OnboardingConfig, OnboardingStep


@admin.register(OnboardingConfig)
class OnboardingConfigAdmin(admin.ModelAdmin):
    list_display = ['organization_name', 'current_step', 'is_completed', 'created_at', 'updated_at']
    list_filter = ['is_completed', 'storage_backend', 'created_at']
    search_fields = ['organization_name', 'email_host_user']
    readonly_fields = ['created_at', 'updated_at', 'completed_at']

    fieldsets = (
        ('Organization', {
            'fields': ('organization_name', 'primary_color', 'secondary_color')
        }),
        ('Email Configuration', {
            'fields': ('email_backend', 'email_host', 'email_port', 'email_use_tls',
                      'email_use_ssl', 'email_host_user', 'email_from_address'),
            'classes': ('collapse',)
        }),
        ('Security', {
            'fields': ('session_timeout_minutes', 'password_min_length', 'require_2fa', 'allowed_domains'),
            'classes': ('collapse',)
        }),
        ('Storage', {
            'fields': ('storage_backend', 's3_bucket_name', 's3_region'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_completed', 'current_step', 'completed_at', 'created_at', 'updated_at', 'created_by')
        }),
    )


@admin.register(OnboardingStep)
class OnboardingStepAdmin(admin.ModelAdmin):
    list_display = ['config', 'step_number', 'step_name', 'is_completed', 'completed_at']
    list_filter = ['is_completed', 'step_number']
    search_fields = ['config__organization_name', 'step_name']
