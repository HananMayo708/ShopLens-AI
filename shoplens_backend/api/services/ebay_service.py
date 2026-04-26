import requests
import json
from django.conf import settings

class EbayProductService:
    def __init__(self):
        self.app_id = settings.EBAY_APP_ID
        self.cert_id = settings.EBAY_CERT_ID
        self.dev_id = settings.EBAY_DEV_ID
        self.base_url = "https://svcs.ebay.com/services/search/FindingService/v1"
    
    def search_products(self, query, limit=20):
        """Search for products on eBay by keyword (No OAuth required)"""
        try:
            params = {
                "OPERATION-NAME": "findItemsAdvanced",
                "SERVICE-VERSION": "1.0.0",
                "SECURITY-APPNAME": self.app_id,
                "RESPONSE-DATA-FORMAT": "JSON",
                "keywords": query,
                "paginationInput.entriesPerPage": limit,
                "sortOrder": "BestMatch"
            }
            
            print(f"🔍 Searching eBay for: {query}")
            
            response = requests.get(self.base_url, params=params, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                products = []
                
                # Navigate through eBay's nested JSON response
                search_result = data.get("findItemsAdvancedResponse", [{}])[0]
                items = search_result.get("searchResult", [{}])[0].get("item", [])
                
                print(f"📦 Found {len(items)} products on eBay")
                
                for item in items:
                    product = {
                        "id": item.get("itemId", [""])[0],
                        "name": item.get("title", [""])[0],
                        "price": float(item.get("sellingStatus", [{}])[0].get("currentPrice", [{}])[0].get("value", [0])[0]),
                        "image_url": item.get("galleryURL", [""])[0],
                        "source": "eBay",
                        "brand": "",
                        "rating": 4.0,
                        "review_count": 0,
                        "in_stock": True,
                        "condition": item.get("condition", [{}])[0].get("conditionDisplayName", [""])[0],
                        "item_url": item.get("viewItemURL", [""])[0],
                        "shipping": item.get("shippingInfo", [{}])[0].get("shippingServiceCost", [{}])[0].get("value", [0])[0]
                    }
                    products.append(product)
                
                return products
            else:
                print(f"❌ eBay API error: {response.status_code}")
                return []
                
        except Exception as e:
            print(f"❌ eBay search error: {e}")
            return []

    def get_product_details(self, item_id):
        """Get detailed information for a specific product"""
        # You can implement getItem API here for detailed info
        pass
