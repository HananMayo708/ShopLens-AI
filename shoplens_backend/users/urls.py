# user/urls.py - COMPLETE FILE
from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from .views import (
    RegisterView,
    LoginView,
    UserProfileView,
    ProductSearchAPI,
    ProductDetailAPI,
    PriceTrendAPI,
    bookmark_api,
    health_check
)

urlpatterns = [
    # Authentication endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('api-token-auth/', obtain_auth_token, name='api_token_auth'),
    
    # ShopLens AI Product endpoints
    path('products/search/', ProductSearchAPI.as_view(), name='product-search'),
    path('products/<int:product_id>/', ProductDetailAPI.as_view(), name='product-detail'),
    path('products/<int:product_id>/trends/', PriceTrendAPI.as_view(), name='price-trend'),
    
    # Bookmark endpoints
    path('bookmarks/', bookmark_api, name='bookmarks-list'),
    path('bookmarks/<int:product_id>/', bookmark_api, name='bookmark-detail'),
    
    # Health check
    path('health/', health_check, name='health-check'),
]