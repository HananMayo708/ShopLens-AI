import requests

class SerpAPIScraper:
    """SERP API - Working version"""
    
    def __init__(self, api_key=None):
        self.api_key = api_key or "3de926d2fb0b0c1135a2bbdce1e22603bef9544cdf18a463dc80982df9e0b4b1"
        self.base_url = "https://serpapi.com/search"
    
    def search_walmart(self, query, max_items=10):
        print(f"\n🛒 SERPAPI WALMART for: '{query}'")
        
        params = {
            "engine": "walmart",
            "query": query,
            "api_key": self.api_key,
            "num": max_items
        }
        
        try:
            response = requests.get(self.base_url, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('organic_results', [])[:max_items]:
                price = 0
                if 'price' in item:
                    price_raw = item['price']
                    if isinstance(price_raw, dict):
                        price_raw = price_raw.get('raw', 0)
                    if price_raw:
                        try:
                            price = float(str(price_raw).replace('$', '').replace(',', '')) * 280
                        except:
                            price = 0
                
                image = item.get('thumbnail', '')
                if not image:
                    image = item.get('image', '')
                
                products.append({
                    'name': item.get('title', ''),
                    'price': price,
                    'image_url': image,
                    'description': f"Walmart product: {item.get('title', '')[:100]}",
                    'rating': item.get('rating', None),
                    'reviews': item.get('reviews', 0),
                    'is_mock': False
                })
                print(f"    ✅ {item.get('title', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} REAL Walmart products")
            return products
            
        except Exception as e:
            print(f"  ❌ SERPAPI error: {e}")
            return []
    
    def search_google_shopping(self, query, max_items=10):
        print(f"\n🛍️ SERPAPI GOOGLE SHOPPING for: '{query}'")
        
        params = {
            "engine": "google_shopping",
            "q": query,
            "api_key": self.api_key,
            "num": max_items
        }
        
        try:
            response = requests.get(self.base_url, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('shopping_results', [])[:max_items]:
                price = 0
                if 'price' in item:
                    price_raw = item['price']
                    if price_raw:
                        try:
                            price = float(str(price_raw).replace('$', '').replace(',', '')) * 280
                        except:
                            price = 0
                
                products.append({
                    'name': item.get('title', ''),
                    'price': price,
                    'image_url': item.get('thumbnail', ''),
                    'description': f"Google Shopping: {item.get('title', '')[:100]}",
                    'rating': item.get('rating', None),
                    'reviews': item.get('reviews', 0),
                    'is_mock': False
                })
                print(f"    ✅ {item.get('title', '')[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} REAL Google Shopping products")
            return products
            
        except Exception as e:
            print(f"  ❌ SERPAPI error: {e}")
            return []
    
    def search_amazon(self, query, max_items=10):
        print(f"\n📦 SERPAPI AMAZON for: '{query}'")
        # Temporarily return empty list - Amazon needs different handling
        print(f"  ⚠️ Amazon search temporarily disabled")
        return []
