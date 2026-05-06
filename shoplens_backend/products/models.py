from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.conf import settings
import numpy as np

class Category(models.Model):
    """Product categories like Electronics, Fashion, Books, etc."""
    
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name_plural = "Categories"
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Seller(models.Model):
    """Sellers/retailers who sell products"""
    
    name = models.CharField(max_length=200)
    rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        default=0.0,
        validators=[MinValueValidator(0), MaxValueValidator(5)]
    )
    website = models.URLField(blank=True, null=True)
    contact_email = models.EmailField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Product(models.Model):
    """Main product model - FIXED CONSTRAINTS"""
    
    name = models.CharField(max_length=500)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Foreign Keys
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products', null=True, blank=True)
    seller = models.ForeignKey(Seller, on_delete=models.CASCADE, related_name='products', null=True, blank=True)
    
    # Product details
    sku = models.CharField(max_length=100, blank=True, null=True)
    stock_quantity = models.IntegerField(default=0)
    image_url = models.URLField(max_length=500, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    # Ratings and reviews
    average_rating = models.DecimalField(
        max_digits=3, 
        decimal_places=2, 
        null=True, 
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(5)]
    )
    review_count = models.IntegerField(default=0)
    
    # AI Features for image search (JSON field to store multiple offers)
    offers = models.JSONField(default=list, blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['price']),
            models.Index(fields=['-created_at']),
            models.Index(fields=['sku']),
        ]
    
    def __str__(self):
        return self.name


class ProductFeature(models.Model):
    """
    Stores ResNet50 feature vectors for AI-powered image search
    Each product has a 2048-dimensional feature vector extracted from its image
    """
    product = models.OneToOneField(
        Product, 
        on_delete=models.CASCADE, 
        related_name='features'
    )
    
    # Store the 2048-dim feature vector as JSON
    feature_vector = models.JSONField(
        help_text="2048-dimensional feature vector from ResNet50"
    )
    
    # Metadata about the feature extraction
    model_version = models.CharField(
        max_length=50, 
        default='ResNet50',
        help_text="Model used for feature extraction"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['product']),
        ]
        ordering = ['-created_at']
    
    def get_vector(self):
        """Convert stored JSON back to numpy array"""
        import numpy as np
        return np.array(self.feature_vector)
    
    def calculate_similarity(self, other_vector):
        """
        Calculate cosine similarity with another feature vector
        Returns a value between 0 and 1 (1 = most similar)
        """
        import numpy as np
        from numpy.linalg import norm
        
        vec1 = self.get_vector()
        vec2 = other_vector if isinstance(other_vector, np.ndarray) else np.array(other_vector)
        
        dot_product = np.dot(vec1, vec2)
        norm_product = norm(vec1) * norm(vec2)
        
        if norm_product == 0:
            return 0
        
        similarity = dot_product / norm_product
        return float(similarity)
    
    def __str__(self):
        return f"AI Features for {self.product.name}"


class Review(models.Model):
    """Product reviews from users"""
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='reviews')
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['product', 'user']
        indexes = [
            models.Index(fields=['product', 'rating']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.product.name} - {self.rating}★"


class PriceHistory(models.Model):
    """
    Track price changes over time for trend analysis
    """
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='price_history')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    recorded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-recorded_at']
        indexes = [
            models.Index(fields=['product', 'recorded_at']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - ${self.price} on {self.recorded_at.date()}"


class ProductView(models.Model):
    """
    Track user views for personalized recommendations
    """
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='views')
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='product_views')
    viewed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-viewed_at']
        indexes = [
            models.Index(fields=['user', 'viewed_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} viewed {self.product.name}"


# ========== PRICE ALERT MODEL ==========

class PriceAlert(models.Model):
    """
    Store user price alerts for products
    """
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='price_alerts')
    product_id = models.CharField(max_length=255)
    product_name = models.CharField(max_length=500)
    product_url = models.CharField(max_length=1000, blank=True, null=True)
    product_image = models.CharField(max_length=1000, blank=True, null=True)
    target_price = models.DecimalField(max_digits=10, decimal_places=2)
    current_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_notified = models.BooleanField(default=False)
    source_store = models.CharField(max_length=100, default='Amazon')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'product_id']
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_notified']),
            models.Index(fields=['product_id']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.product_name} - ${self.target_price}"


# ========== IN-APP NOTIFICATION MODEL (ADDED) ==========

class Notification(models.Model):
    """
    In-app notifications for price alerts and system updates
    Shows price drop alerts, wishlist updates, etc. to users
    """
    NOTIFICATION_TYPES = [
        ('price_drop', 'Price Drop'),
        ('price_alert', 'Price Alert'),
        ('wishlist', 'Wishlist Update'),
        ('system', 'System Notification'),
        ('promotion', 'Promotion'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='notifications'
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(
        max_length=20, 
        choices=NOTIFICATION_TYPES, 
        default='system'
    )
    is_read = models.BooleanField(default=False)
    
    # Optional links to related data
    product_id = models.CharField(max_length=255, blank=True, null=True)
    product_name = models.CharField(max_length=500, blank=True, null=True)
    price_alert_id = models.IntegerField(blank=True, null=True)
    
    # Additional data as JSON (store price, savings, store name, etc.)
    extra_data = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['notification_type']),
        ]
    
    def mark_as_read(self):
        """Mark notification as read"""
        self.is_read = True
        self.save(update_fields=['is_read'])
    
    def get_time_ago(self):
        """Get human-readable time ago string"""
        from django.utils import timezone
        from django.utils.timesince import timesince
        return timesince(self.created_at, timezone.now())
    
    def __str__(self):
        return f"{self.user.email} - {self.title} - {'Read' if self.is_read else 'Unread'}"