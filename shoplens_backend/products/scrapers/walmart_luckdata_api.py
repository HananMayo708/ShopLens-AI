import requests

class WalmartLuckdataAPI:
    """Walmart via Luckdata - 100 free points/month"""
    
    def __init__(self):
        # Get from: https://luckdata.io/marketplace/detail/walmart-API
        self.api_key = "YOUR_LUCKDATA_API_KEY"  # Replace after signup [citation:4]
    
    def search_products(self, query, max_items=15):
        print(f"\n🛒 WALMART LUCKDATA API for: '{query}'")
        
        url = "https://luckdata.io/api/walmart-API/search"
        headers = {
            "X-Luckdata-Api-Key": self.api_key
        }
        params = {
            "q": query,
            "limit": max_items
        }
        
        try:
            response = requests.get(url, headers=headers, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('data', {}).get('products', [])[:max_items]:
                products.append({
                    'name': item.get('name', '')[:255],
                    'price': float(item.get('price', 0)) * 280,
                    'image_url': item.get('image', ''),
                    'platform': 'Walmart',
                    'seller': 'Walmart',
                    'is_real': True,
                    'source': 'Luckdata API'
                })
                print(f"    ✅ {item.get('name', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} REAL Walmart products")
            return products
            
        except Exception as e:
            print(f"  ❌ Walmart API error: {e}")
            return []
