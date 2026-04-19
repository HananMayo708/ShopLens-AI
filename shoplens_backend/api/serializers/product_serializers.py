from rest_framework import serializers
from products.models import Category, Seller, Product, Review

class CategorySerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'product_count', 'created_at']
        read_only_fields = ['id', 'created_at']


class SellerSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Seller
        fields = ['id', 'name', 'rating', 'website', 'contact_email', 'product_count', 'created_at']
        read_only_fields = ['id', 'created_at']


class ReviewSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    user_id = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Review
        fields = ['id', 'product', 'user', 'user_id', 'rating', 'comment', 'created_at']
        read_only_fields = ['id', 'created_at', 'user', 'user_id']
    
    def validate_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        source='category',
        write_only=True
    )
    seller = SellerSerializer(read_only=True)
    seller_id = serializers.PrimaryKeyRelatedField(
        queryset=Seller.objects.all(),
        source='seller',
        write_only=True
    )
    reviews = ReviewSerializer(many=True, read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 
            'category', 'category_id', 'seller', 'seller_id',
            'sku', 'stock_quantity', 'image_url', 'is_active',
            'reviews', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ProductListSerializer(serializers.ModelSerializer):
    category = serializers.StringRelatedField()
    seller = serializers.StringRelatedField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'price', 'category', 'seller',
            'stock_quantity', 'image_url', 'is_active',
            'created_at'
        ]
        read_only_fields = ['id', 'created_at']
