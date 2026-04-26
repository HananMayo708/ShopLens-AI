from django.urls import path
from .views.serpapi_search_view import SerpAPISearchView
from .views.ebay_views import EbaySearchView
from .views.scraperapi_views import ScraperAPISearchView
from .views.multi_store_views import MultiStoreSearchView
from .views import marketplace_integrity_view, auth_views, search_views, image_search_views, hybrid_search_views
from . import seller_verification

urlpatterns = [
    # Multi-Store Search (NEW - Primary source - Amazon, eBay, Walmart, Daraz, AliExpress)
    path('multistore/search/', MultiStoreSearchView.as_view(), name='multistore-search'),
    
    # ScraperAPI Search (Backup)
    path('scraperapi/search/', ScraperAPISearchView.as_view(), name='scraperapi-search'),
    
    # SerpAPI Search
    path('serpapi/search/', SerpAPISearchView.as_view(), name='serpapi-search'),
    
    # eBay Search
    path('ebay/search/', EbaySearchView.as_view(), name='ebay-search'),
    
    # Auth endpoints
    path('auth/register/', auth_views.register, name='register'),
    path('auth/login/', auth_views.login, name='login'),
    path('auth/logout/', auth_views.logout, name='logout'),
    path('auth/profile/', auth_views.profile, name='profile'),
    path('auth/change-password/', auth_views.change_password, name='change-password'),
    path('auth/refresh/', auth_views.refresh_token, name='refresh-token'),

    # RapidAPI Search endpoints (Backup - optional)
    path('rapidapi/search/', search_views.rapidapi_search, name='rapidapi_search'),
    path('rapidapi/trending/', search_views.rapidapi_trending, name='rapidapi_trending'),
    path('product/<str:product_id>/', search_views.get_product_details, name='product_details'),
    path('search/', search_views.search_products, name='search_products'),

    # Image search endpoints
    path('image-search/', image_search_views.ResNetImageSearchView.as_view(), name='image-search'),
    path('image-search/resnet/', image_search_views.ResNetImageSearchView.as_view(), name='resnet-image-search'),

    # Hybrid image search endpoint
    path('image-search/hybrid/', hybrid_search_views.HybridImageSearchView.as_view(), name='hybrid-image-search'),
    
    # Marketplace integrity / Seller verification
    path('marketplace/verify/', marketplace_integrity_view.MarketplaceIntegrityView.as_view(), name='marketplace-verify'),

    # Seller verification endpoints
    path('seller/verify/', seller_verification.verify_seller, name='verify-seller'),
    path('seller/verify-multiple/', seller_verification.verify_multiple_sellers, name='verify-multiple-sellers'),
]