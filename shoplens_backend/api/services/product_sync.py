from products.models import Product, Category
from .rapidapi_service import RapidAPIProductService
import logging
from django.utils.text import slugify
from decimal import Decimal
import random

logger = logging.getLogger(__name__)

class ProductSyncService:
    """
    Service to sync products from RapidAPI to local database
    """
    
    def __init__(self):
        self.api_service = RapidAPIProductService()
    
    def map_rapidapi_product_to_item(self, api_product: dict) -> dict:
        """
        Map RapidAPI product data to your Product model fields
        This mapping will need adjustment based on your specific API response structure
        """
        # Create or get category
        category_name = api_product.get('category', 'Uncategorized')
        category, _ = Category.objects.get_or_create(
            name=category_name,
            defaults={'slug': slugify(category_name)}
        )
        
        # Generate a unique SKU
        sku = f"EXT-{api_product.get('id', random.randint(10000, 99999))}"
        
        # Map the fields - adjust according to your API response structure
        return {
            'name': api_product.get('title', api_product.get('name', 'Unknown Product')),
            'slug': slugify(api_product.get('title', api_product.get('name', 'unknown'))),
            'sku': sku,
            'description': api_product.get('description', 'No description available'),
            'price': Decimal(str(api_product.get('price', api_product.get('salePrice', 0)))),
            'compare_at_price': Decimal(str(api_product.get('originalPrice', api_product.get('listPrice', 0)))),
            'category': category,
            'main_image': api_product.get('image', api_product.get('thumbnail')),
            'is_active': True,
            'quantity': api_product.get('stock', api_product.get('availability', 10)),
            'tags': ','.join(api_product.get('tags', [])),
            'specifications': api_product.get('specifications', {}),
        }
    
    def sync_search_results(self, query: str, max_items: int = 50) -> int:
        """
        Search and sync products from RapidAPI
        Returns number of products synced
        """
        try:
            response = self.api_service.search_products(query)
            products = response.get('products', [])[:max_items]
            
            synced_count = 0
            for api_product in products:
                try:
                    product_data = self.map_rapidapi_product_to_item(api_product)
                    
                    # Check if product already exists by SKU or name
                    Product, created = Product.objects.get_or_create(
                        sku=product_data['sku'],
                        defaults=product_data
                    )
                    
                    if created:
                        synced_count += 1
                        logger.info(f"Synced new product: {Product.name}")
                    else:
                        logger.info(f"Product already exists: {Product.name}")
                        
                except Exception as e:
                    logger.error(f"Failed to sync product {api_product.get('id')}: {str(e)}")
                    continue
            
            return synced_count
            
        except Exception as e:
            logger.error(f"Failed to sync search results: {str(e)}")
            return 0
    
    def sync_category_products(self, category: str, max_items: int = 50) -> int:
        """
        Sync products from a specific category
        """
        try:
            response = self.api_service.get_products_by_category(category)
            products = response.get('products', [])[:max_items]
            
            synced_count = 0
            for api_product in products:
                try:
                    product_data = self.map_rapidapi_product_to_item(api_product)
                    
                    Product, created = Product.objects.get_or_create(
                        sku=product_data['sku'],
                        defaults=product_data
                    )
                    
                    if created:
                        synced_count += 1
                        
                except Exception as e:
                    logger.error(f"Failed to sync product: {str(e)}")
                    continue
            
            return synced_count
            
        except Exception as e:
            logger.error(f"Failed to sync category products: {str(e)}")
            return 0
    
    def update_existing_products(self) -> int:
        """
        Update existing products with latest data from API
        """
        updated_count = 0
        # Get products that were synced from external source
        external_products = Product.objects.filter(sku__startswith='EXT-')
        
        for Product in external_products:
            try:
                # Extract external ID from SKU
                external_id = Product.sku.replace('EXT-', '')
                
                # Fetch latest data from API
                api_product = self.api_service.get_product_details(external_id)
                
                if api_product:
                    # Update fields
                    Product.price = Decimal(str(api_product.get('price', Product.price)))
                    Product.quantity = api_product.get('stock', Product.quantity)
                    Product.is_active = True
                    Product.save()
                    updated_count += 1
                    
            except Exception as e:
                logger.error(f"Failed to update product {Product.sku}: {str(e)}")
                continue
        
        return updated_count
