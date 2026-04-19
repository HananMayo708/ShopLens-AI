import requests

class BestBuyOfficialAPI:
    """OFFICIAL BestBuy API - 50 calls/day FREE"""
    
    def __init__(self):
        # Get from: https://developer.bestbuy.com/
        self.api_key = "YOUR_BESTBUY_API_KEY"  # Replace after signup
    
    def search_products(self, query, max_items=15):
        print(f"\n📺 BESTBUY OFFICIAL API for: '{query}'")
        
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
                    'is_real': True,
                    'source': 'Official BestBuy API'
                })
                print(f"    ✅ {item.get('name', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} REAL BestBuy products")
            return products
            
        except Exception as e:
            print(f"  ❌ BestBuy API error: {e}")
            return []
