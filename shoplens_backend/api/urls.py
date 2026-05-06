from django.urls import path
from .views.multi_store_views import MultiStoreSearchView
from .views import auth_views
from .views.hybrid_search_views import HybridImageSearchView
from .views.price_alert_views import PriceAlertListView, CreatePriceAlertView, DeletePriceAlertView
from .views.image_search_views import (
    ResNetImageSearchView,
    ExtractAndSearchView,
    IndexProductFeaturesView,
    ReindexAllFeaturesView,
    GetProductFeaturesView
)

urlpatterns = [
    # Multi-Store Search (Working - Amazon, eBay, Walmart, Daraz, AliExpress)
    path('multistore/search/', MultiStoreSearchView.as_view(), name='multistore-search'),
    
    # Image Search (AI-powered using ResNet50)
    path('image-search/', ResNetImageSearchView.as_view(), name='image-search'),
    path('image-search/hybrid/', HybridImageSearchView.as_view(), name='hybrid-image-search'),
    path('image-search/extract/', ExtractAndSearchView.as_view(), name='extract-search'),
    
    # Feature indexing endpoints (Admin only)
    path('image-search/index/', IndexProductFeaturesView.as_view(), name='index-features'),
    path('image-search/reindex/', ReindexAllFeaturesView.as_view(), name='reindex-features'),
    path('image-search/features/<int:product_id>/', GetProductFeaturesView.as_view(), name='product-features'),
    
    # Authentication endpoints
    path('auth/register/', auth_views.register, name='register'),
    path('auth/login/', auth_views.login, name='login'),
    path('auth/logout/', auth_views.logout, name='logout'),
    path('auth/profile/', auth_views.profile, name='profile'),
    path('auth/change-password/', auth_views.change_password, name='change-password'),
    path('auth/refresh/', auth_views.refresh_token, name='refresh-token'),
    
    # Price Alert endpoints
    path('price-alerts/', PriceAlertListView.as_view(), name='price-alerts-list'),
    path('price-alerts/create/', CreatePriceAlertView.as_view(), name='price-alerts-create'),
    path('price-alerts/<int:alert_id>/delete/', DeletePriceAlertView.as_view(), name='price-alerts-delete'),
]