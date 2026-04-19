from django.urls import path
from . import views

urlpatterns = [
    path('compare_prices/', views.compare_prices, name='compare_prices'),
]
