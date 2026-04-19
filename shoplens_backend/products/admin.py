from django.contrib import admin
from .models import Category, Seller, Product, Review

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'product_count', 'created_at']
    search_fields = ['name']
    readonly_fields = ['created_at']
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'


@admin.register(Seller)
class SellerAdmin(admin.ModelAdmin):
    list_display = ['name', 'rating', 'product_count', 'created_at']
    search_fields = ['name']
    list_filter = ['rating']
    readonly_fields = ['created_at']
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'price', 'category', 'seller', 'stock_quantity', 'is_active', 'created_at']
    list_filter = ['category', 'seller', 'is_active']
    search_fields = ['name', 'description', 'sku']
    readonly_fields = ['created_at', 'updated_at']
    list_editable = ['price', 'stock_quantity', 'is_active']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'price', 'sku')
        }),
        ('Categories & Seller', {
            'fields': ('category', 'seller')
        }),
        ('Inventory', {
            'fields': ('stock_quantity', 'is_active')
        }),
        ('Media', {
            'fields': ('image_url',)
        }),
        ('Ratings', {
            'fields': ('average_rating', 'review_count')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['product', 'user', 'rating', 'created_at']
    list_filter = ['rating', 'created_at']
    search_fields = ['product__name', 'user__username', 'comment']
    readonly_fields = ['created_at']  # REMOVED updated_at - it doesn't exist!
    
    fieldsets = (
        ('Review Details', {
            'fields': ('product', 'user', 'rating')
        }),
        ('Content', {
            'fields': ('comment',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
