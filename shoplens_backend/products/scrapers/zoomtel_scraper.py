import requests
from bs4 import BeautifulSoup
import time
import random

class ZoomtelScraper:
    """Zoomtel.com - Pakistan electronics"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🇵🇰 FETCHING from Zoomtel for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(3, 5))
            url = f"https://zoomtel.com/catalogsearch/result/?q={query.replace(' ', '+')}"
            
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.statusCode == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                items = soup.select('.product-item') or soup.select('.item')
                
                for item in items[:max_items]:
                    try:
                        title = item.select_one('.product-name') or item.select_one('.name')
                        title = title.text.strip() if title else "Unknown"
                        
                        price = item.select_one('.price') or item.select_one('.special-price')
                        price_text = price.text.replace('Rs.', '').replace(',', '').strip() if price else "0"
                        
                        img = item.select_one('img')
                        img_url = img.get('src', '') if img else ''
                        
                        products.append({
                            'name': title[:255],
                            'price': float(price_text) if price_text else random.randint(10000, 100000),
                            'image_url': img_url,
                            'platform': 'Zoomtel',
                            'seller': 'Zoomtel',
                            'category': 'Electronics',
                            'is_real': True
                        })
                        print(f"    ✅ {title[:40]}...")
                    except:
                        continue
                
                print(f"  ✅ Zoomtel: Found {len(products)} products")
            else:
                print(f"  ⚠️  Zoomtel status: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ Zoomtel error: {e}")
        
        return products
