import requests
from bs4 import BeautifulSoup
import time
import random

class HomeShoppingScraper:
    """HomeShopping.pk - Fixed with better selectors"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🇵🇰 FETCHING from HomeShopping.pk for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(4, 6))
            url = f"https://homeshopping.pk/catalogsearch/result/?q={query.replace(' ', '+')}"
            
            response = requests.get(url, headers=headers, timeout=20)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                
                # Multiple selector attempts
                items = (soup.select('.product-item') or 
                        soup.select('.item') or 
                        soup.select('[class*="product"]') or
                        soup.find_all('li', class_=True))
                
                for item in items[:max_items]:
                    try:
                        title = (item.select_one('.product-name') or 
                                item.select_one('.name') or 
                                item.select_one('h2') or
                                item.select_one('a')).text.strip()
                        
                        price_elem = (item.select_one('.price') or 
                                     item.select_one('.special-price') or
                                     item.select_one('[class*="price"]'))
                        
                        if price_elem:
                            price_text = price_elem.text.replace('Rs.', '').replace(',', '').strip()
                            price = float(price_text) if price_text else 0
                        else:
                            continue
                        
                        img = item.select_one('img')
                        img_url = img.get('src', '') if img else ''
                        
                        products.append({
                            'name': title[:255],
                            'price': price,
                            'image_url': img_url,
                            'platform': 'HomeShopping.pk',
                            'seller': 'HomeShopping',
                            'is_real': True
                        })
                        print(f"    ✅ {title[:40]}...")
                    except:
                        continue
                
                print(f"  ✅ HomeShopping.pk: Found {len(products)} products")
                return products
            
            print(f"  ⚠️  HomeShopping.pk status: {response.status_code}")
            
        except Exception as e:
            print(f"  ❌ HomeShopping.pk error: {e}")
        
        return products
