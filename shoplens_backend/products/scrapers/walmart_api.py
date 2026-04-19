import requests
import time
import hashlib

class WalmartAPI:
    """Walmart API - REAL products, need API key"""
    
    def __init__(self):
        # Get free key: https://developer.walmart.com/
        self.consumer_id = "YOUR_CONSUMER_ID"
        self.private_key = "YOUR_PRIVATE_KEY"
    
    def search_products(self, query, max_items=15):
        print(f"\n🛒 FETCHING from Walmart API for: '{query}'")
        
        url = "https://api.walmart.io/v1/items"
        params = {"query": query, "limit": max_items}
        
        try:
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('items', [])[:max_items]:
                products.append({
                    'name': item.get('name', '')[:255],
                    'price': item.get('salePrice', 0) * 280,
                    'image_url': item.get('largeImage', item.get('mediumImage', '')),
                    'product_url': item.get('productUrl', ''),
                    'platform': 'Walmart',
                    'seller': 'Walmart',
                    'category': 'General',
                    'is_real': True
                })
                print(f"    ✅ {item.get('name', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} products")
            return products
            
        except Exception as e:
            print(f"  ❌ Walmart error: {e}")
            return []
