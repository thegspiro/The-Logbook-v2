"""
Context processors for The Logbook Onboarding Module
"""
from django.conf import settings
from .models import OnboardingConfig


def theme_context(request):
    """
    Add theme colors and app configuration to template context.
    Checks for user-configured colors in database, falls back to settings.
    """
    # Try to get the latest onboarding config
    try:
        config = OnboardingConfig.objects.filter(is_completed=True).latest('completed_at')
        primary_color = config.primary_color
        secondary_color = config.secondary_color
        organization_name = config.organization_name
    except OnboardingConfig.DoesNotExist:
        # Fall back to settings
        primary_color = settings.PRIMARY_COLOR
        secondary_color = settings.SECONDARY_COLOR
        organization_name = settings.APP_NAME

    # Calculate lighter and darker shades for accessibility
    def hex_to_rgb(hex_color):
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

    def rgb_to_hex(rgb):
        return '#{:02x}{:02x}{:02x}'.format(int(rgb[0]), int(rgb[1]), int(rgb[2]))

    def lighten_color(hex_color, factor=0.3):
        rgb = hex_to_rgb(hex_color)
        lightened = tuple(min(255, int(c + (255 - c) * factor)) for c in rgb)
        return rgb_to_hex(lightened)

    def darken_color(hex_color, factor=0.3):
        rgb = hex_to_rgb(hex_color)
        darkened = tuple(max(0, int(c * (1 - factor))) for c in rgb)
        return rgb_to_hex(darkened)

    return {
        'APP_NAME': organization_name,
        'PRIMARY_COLOR': primary_color,
        'PRIMARY_COLOR_LIGHT': lighten_color(primary_color),
        'PRIMARY_COLOR_DARK': darken_color(primary_color),
        'SECONDARY_COLOR': secondary_color,
        'SECONDARY_COLOR_LIGHT': lighten_color(secondary_color),
        'SECONDARY_COLOR_DARK': darken_color(secondary_color),
    }
