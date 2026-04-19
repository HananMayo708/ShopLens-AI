import os
import re
from serpapi import GoogleSearch

class SerpAPIService:
    def __init__(self):
        self.api_key = os.getenv('SERPAPI_API_KEY')
    
    def search_shopping_products(self, query, limit=20):
        """Search for products using Google Shopping API"""
        try:
            if not self.api_key:
                print("❌ SerpAPI key not configured")
                return {"success": False, "error": "API key missing", "products": []}
            
            params = {
                "q": query,
                "api_key": self.api_key,
                "engine": "google_shopping",
                "gl": "us",
                "hl": "en",
                "num": limit
            }
            
            search = GoogleSearch(params)
            results = search.get_dict()
            
            products = []
            shopping_results = results.get("shopping_results", [])
            
            for item in shopping_results[:limit]:
                product = {
                    "id": f"serp_{item.get('position', 0)}",
                    "name": item.get("title", ""),
                    "price": self._extract_price(item.get("price", "0")),
                    "original_price": self._extract_price(item.get("old_price")),
                    "image_url": item.get("thumbnail", ""),
                    "source": item.get("source", ""),
                    "rating": float(item.get("rating", 4.0)),
                    "review_count": item.get("reviews", 0),
                    "description": item.get("description", ""),
                    "shipping": item.get("shipping", ""),
                    "link": item.get("link", ""),
                    "in_stock": True,
                    "category": self._get_category(query),
                }
                products.append(product)
            
            print(f"✅ SerpAPI found {len(products)} products for '{query}'")
            return {
                "success": True,
                "products": products,
                "total": len(products)
            }
            
        except Exception as e:
            print(f"❌ SerpAPI Error: {e}")
            return {"success": False, "error": str(e), "products": []}
    
    def _extract_price(self, price_string):
        """Extract numeric price from string like '$24.99'"""
        if not price_string:
            return 0.0
        match = re.search(r'[\d,]+\.?\d*', str(price_string))
        if match:
            return float(match.group().replace(',', ''))
        return 0.0
    
    def _get_category(self, query):
        """Map search query to category"""
        query_lower = query.lower()
        if any(word in query_lower for word in ['laptop', 'computer', 'macbook']):
            return 'Electronics'
        elif any(word in query_lower for word in ['phone', 'smartphone', 'iphone', 'samsung']):
            return 'Electronics'
        elif any(word in query_lower for word in ['headphone', 'earbud', 'audio']):
            return 'Electronics'
        elif any(word in query_lower for word in ['gaming', 'game', 'controller']):
            return 'Gaming'
        elif any(word in query_lower for word in ['shoe', 'clothing', 'fashion', 'shirt']):
            return 'Fashion'
        elif any(word in query_lower for word in ['home', 'kitchen', 'vacuum', 'pot']):
            return 'Home'
        else:
            return 'Electronics'
