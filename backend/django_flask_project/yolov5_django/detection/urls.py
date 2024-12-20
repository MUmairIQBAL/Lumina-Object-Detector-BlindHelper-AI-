# detection/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('detect/', views.detect_view, name='detect'),
]
