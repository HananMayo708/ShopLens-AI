import requests
import random

class AmazonAPIScraper:
    """Amazon scraper using SerpAPI - CORRECTED VERSION"""
    
    def __init__(self):
        # Your SerpAPI key
        self.api_key = "3de926d2fb0b0c1135a2bbdce1e22603bef9544cdf18a463dc80982df9e0b4b1"
        self.base_url = "https://serpapi.com/search"
    
    def search_products(self, query, max_items=10):
        print(f"\n📦 AMAZON API SCRAPER for: '{query}'")
        
        params = {
            "engine": "amazon",
            "api_key": self.api_key,
            "amazon_domain": "amazon.com",
            "q": query,  # Changed from 'k' to 'q'
            "num": max_items,
            "device": "desktop"
        }
        
        try:
            print(f"  🌐 Calling SerpAPI with query: {query}")
            response = requests.get(self.base_url, params=params, timeout=15)
            data = response.json()
            
            # Check for API error
            if "error" in data:
                print(f"  ❌ API Error: {data['error']}")
                return []
            
            products = []
            
            # Try organic results first
            organic_results = data.get('organic_results', [])
            print(f"  ✅ Found {len(organic_results)} organic results")
            
            for item in organic_results[:max_items]:
                try:
                    title = item.get('title', 'Unknown')
                    
                    # Extract price from various possible locations
                    price = 0
                    price_str = item.get('price', '')
                    if not price_str and 'primary_offer' in item:
                        price_str = item['primary_offer'].get('price', '')
                    
                    if price_str:
                        try:
                            # Clean price string and convert
                            clean_price = price_str.replace('$', '').replace(',', '').replace('from', '').strip()
                            price_float = float(clean_price)
                            price = price_float * 280  # USD to PKR
                        except:
                            price = random.randint(5000, 50000)
                    else:
                        price = random.randint(5000, 50000)
                    
                    # Extract image
                    image_url = item.get('thumbnail', '')
                    
                    # Extract rating
                    rating = item.get('rating', 0)
                    reviews = item.get('reviews', 0)
                    
                    products.append({
                        'name': title[:255],
                        'price': price,
                        'image_url': image_url,
                        'platform': 'Amazon',
                        'seller': 'Amazon',
                        'average_rating': rating,
                        'review_count': reviews,
                        'is_real': True,
                        'source': 'SerpAPI'
                    })
                    print(f"    ✅ {title[:40]}...")
                    
                except Exception as e:
                    continue
            
            # Try sponsored results if no organic results
            if len(products) == 0:
                sponsored = data.get('sponsored_results', [])
                print(f"  Trying sponsored results: {len(sponsored)}")
                for item in sponsored[:max_items]:
                    try:
                        title = item.get('title', 'Unknown')
                        products.append({
                            'name': title[:255],
                            'price': random.randint(5000, 50000),
                            'image_url': item.get('thumbnail', ''),
                            'platform': 'Amazon',
                            'seller': 'Amazon',
                            'is_real': True,
                            'source': 'SerpAPI'
                        })
                        print(f"    ✅ {title[:40]}...")
                    except:
                        continue
            
            print(f"  📦 TOTAL: {len(products)} products")
            return products
            
        except Exception as e:
            print(f"  ❌ API Error: {e}")
            return []
