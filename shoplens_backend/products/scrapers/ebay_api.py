import requests

class EbayAPI:
    """eBay API - REAL products, need App ID"""
    
    def __init__(self):
        # Get free key: https://developer.ebay.com/
        self.app_id = "YOUR_APP_ID"
    
    def search_products(self, query, max_items=15):
        print(f"\n🕷️ FETCHING from eBay API for: '{query}'")
        
        url = "https://svcs.ebay.com/services/search/FindingService/v1"
        params = {
            "OPERATION-NAME": "findItemsByKeywords",
            "SERVICE-VERSION": "1.0.0",
            "SECURITY-APPNAME": self.app_id,
            "RESPONSE-DATA-FORMAT": "JSON",
            "keywords": query,
            "paginationInput.entriesPerPage": max_items
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            products = []
            items = data.get('findItemsByKeywordsResponse', [{}])[0].get('searchResult', [{}])[0].get('item', [])
            
            for item in items[:max_items]:
                title = item.get('title', [''])[0]
                price = float(item.get('sellingStatus', [{}])[0].get('currentPrice', [{}])[0].get('__value__', 0)) * 280
                image = item.get('galleryURL', [''])[0]
                url = item.get('viewItemURL', [''])[0]
                
                products.append({
                    'name': title[:255],
                    'price': price,
                    'image_url': image,
                    'product_url': url,
                    'platform': 'eBay',
                    'seller': 'eBay Seller',
                    'category': 'Electronics',
                    'is_real': True
                })
                print(f"    ✅ {title[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} products")
            return products
            
        except Exception as e:
            print(f"  ❌ eBay error: {e}")
            return []
