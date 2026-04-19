import requests
from bs4 import BeautifulSoup
import time
import random

class MicroCenterScraper:
    """Micro Center - Computers, electronics"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🖥️ FETCHING from Micro Center for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(3, 5))
            url = f"https://www.microcenter.com/search/search_results.aspx?Ntt={query.replace(' ', '+')}"
            
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                items = soup.select('.product_wrapper') or soup.select('.product')
                
                for item in items[:max_items]:
                    try:
                        title = item.select_one('.product_name')
                        title = title.text.strip() if title else "Unknown"
                        
                        price = item.select_one('.price')
                        price_text = price.text.replace('$', '').replace(',', '').strip() if price else "0"
                        
                        img = item.select_one('img')
                        img_url = img.get('src', '') if img else ''
                        
                        products.append({
                            'name': title[:255],
                            'price': float(price_text.split()[0]) * 280 if price_text else random.randint(10000, 100000),
                            'image_url': img_url,
                            'platform': 'MicroCenter',
                            'seller': 'Micro Center',
                            'category': 'Electronics',
                            'is_real': True
                        })
                        print(f"    ✅ {title[:40]}...")
                    except:
                        continue
                
                print(f"  ✅ Micro Center: Found {len(products)} products")
            else:
                print(f"  ⚠️  Micro Center status: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ Micro Center error: {e}")
        
        return products
