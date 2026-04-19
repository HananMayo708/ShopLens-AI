import requests

class EbayOfficialAPI:
    """OFFICIAL eBay Finding API - 5000 calls/day FREE"""
    
    def __init__(self, app_id=None):
        # Get from: https://developer.ebay.com/my/keys
        self.app_id = app_id or "YOUR_EBAY_APP_ID"  # Replace with your actual App ID
    
    def search_products(self, query, max_items=15):
        print(f"\n🕷️ EBAY OFFICIAL API for: '{query}'")
        
        if self.app_id == "YOUR_EBAY_APP_ID":
            print("  ⚠️  Please set your eBay App ID in ebay_official_api.py")
            print("  🔗 Get it free from: https://developer.ebay.com/my/keys")
            return self._get_mock_products(query, max_items)
        
        url = "https://svcs.ebay.com/services/search/FindingService/v1"
        params = {
            "OPERATION-NAME": "findItemsByKeywords",
            "SERVICE-VERSION": "1.0.0",
            "SECURITY-APPNAME": self.app_id,
            "RESPONSE-DATA-FORMAT": "JSON",
            "REST-PAYLOAD": "",
            "keywords": query,
            "paginationInput.entriesPerPage": max_items
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            # Check for API errors
            if 'errorMessage' in data:
                error = data['errorMessage']['error'][0]['message']
                print(f"  ❌ eBay API Error: {error}")
                return self._get_mock_products(query, max_items)
            
            products = []
            search_result = data.get('findItemsByKeywordsResponse', [{}])[0]
            items = search_result.get('searchResult', [{}])[0].get('item', [])
            
            for item in items:
                try:
                    # Extract title
                    title = item.get('title', ['Unknown'])[0]
                    
                    # Extract price
                    price = 0
                    if 'sellingStatus' in item:
                        current_price = item['sellingStatus'][0].get('currentPrice', [{}])[0]
                        price = float(current_price.get('__value__', 0)) * 280  # USD to PKR
                    
                    # Extract image
                    image = item.get('galleryURL', [''])[0]
                    if image and 'gif' in image:
                        image = ''  # Skip placeholder images
                    
                    # Extract product URL
                    product_url = item.get('viewItemURL', [''])[0]
                    
                    # Extract seller
                    seller = 'eBay Seller'
                    if 'sellerInfo' in item:
                        seller_info = item['sellerInfo'][0]
                        seller = seller_info.get('sellerUserName', ['eBay Seller'])[0]
                    
                    # Extract condition
                    condition = 'New'
                    if 'condition' in item:
                        condition_display = item['condition'][0].get('conditionDisplayName', ['New'])[0]
                        condition = condition_display
                    
                    products.append({
                        'name': title[:255],
                        'price': price,
                        'image_url': image,
                        'platform': 'eBay',
                        'seller': seller,
                        'product_url': product_url,
                        'condition': condition,
                        'is_real': True,
                        'source': 'Official eBay API'
                    })
                    print(f"    ✅ {title[:40]}...")
                    
                except Exception as e:
                    print(f"    ⚠️ Error parsing item: {e}")
                    continue
            
            print(f"  📦 TOTAL: {len(products)} REAL eBay products")
            return products
            
        except requests.exceptions.Timeout:
            print("  ❌ eBay API timeout")
            return self._get_mock_products(query, max_items)
        except Exception as e:
            print(f"  ❌ eBay API error: {e}")
            return self._get_mock_products(query, max_items)
    
    def _get_mock_products(self, query, count=8):
        """Return mock products when API fails (temporary fallback)"""
        print(f"  📋 Using mock products while waiting for eBay API key")
        products = []
        categories = ['Electronics', 'Laptops', 'Computers', 'Gaming', 'Accessories']
        
        for i in range(count):
            price = (i + 1) * 5000 + 20000
            products.append({
                'name': f"eBay {query.title()} - Model {i+1}",
                'price': price,
                'image_url': f"https://via.placeholder.com/300x300?text=eBay+{query.replace(' ', '+')}",
                'platform': 'eBay',
                'seller': 'eBay Seller',
                'is_mock': True,
                'is_real': False,
                'note': 'Waiting for API key'
            })
            print(f"    📋 Mock {i+1}: eBay {query} - Model {i+1}")
        
        return products
