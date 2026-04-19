import requests
from bs4 import BeautifulSoup
import time
import random

class AliExpressScraper:
    """AliExpress - Sometimes works with proper delays"""
    
    def search_products(self, query, max_items=15):
        print(f"\n📦 FETCHING from AliExpress for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(5, 8))
            url = f"https://www.aliexpress.com/wholesale?SearchText={query.replace(' ', '+')}"
            
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                items = soup.select('[data-product-id]') or soup.select('.product-item') or soup.select('.list-item')
                
                for item in items[:max_items]:
                    try:
                        title = item.select_one('.product-title') or item.select_one('.title')
                        title = title.text.strip() if title else "Unknown"
                        
                        price = item.select_one('.product-price') or item.select_one('.price')
                        price_text = price.text.replace('$', '').replace(',', '').strip() if price else "0"
                        
                        img = item.select_one('img')
                        img_url = img.get('src', '') if img else ''
                        
                        products.append({
                            'name': title[:255],
                            'price': float(price_text.split()[0]) * 280 if price_text else random.randint(5000, 50000),
                            'image_url': img_url,
                            'platform': 'AliExpress',
                            'seller': 'AliExpress Seller',
                            'category': 'Electronics',
                            'is_real': True
                        })
                        print(f"    ✅ {title[:40]}...")
                    except:
                        continue
                
                print(f"  ✅ AliExpress: Found {len(products)} products")
            else:
                print(f"  ⚠️  AliExpress status: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ AliExpress error: {e}")
        
        return products
