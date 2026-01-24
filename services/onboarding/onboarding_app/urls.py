"""
URL configuration for The Logbook Onboarding App
"""
from django.urls import path
from . import views

app_name = 'onboarding'

urlpatterns = [
    path('', views.WelcomeView.as_view(), name='welcome'),
    path('step/<int:step>/', views.OnboardingStepView.as_view(), name='step'),
]
