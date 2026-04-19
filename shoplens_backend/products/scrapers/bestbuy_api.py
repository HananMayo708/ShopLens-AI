import requests

class BestBuyAPI:
    """Best Buy Official API - REAL electronics, laptops, phones"""
    
    def __init__(self):
        # Get free key: https://developer.bestbuy.com/
        self.api_key = "YOUR_BESTBUY_API_KEY"  # Sign up for free
    
    def search_products(self, query, max_items=15):
        print(f"\n📺 FETCHING from BestBuy API for: '{query}'")
        
        url = "https://api.bestbuy.com/v1/products"
        params = {
            "format": "json",
            "apiKey": self.api_key,
            "search": query,
            "pageSize": max_items
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('products', [])[:max_items]:
                products.append({
                    'name': item.get('name', '')[:255],
                    'price': item.get('salePrice', 0) * 280,
                    'image_url': item.get('image', ''),
                    'product_url': item.get('url', ''),
                    'platform': 'BestBuy',
                    'seller': 'Best Buy',
                    'category': 'Electronics',
                    'is_real': True
                })
                print(f"    ✅ {item.get('name', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} products")
            return products
            
        except Exception as e:
            print(f"  ❌ BestBuy error: {e}")
            return []
