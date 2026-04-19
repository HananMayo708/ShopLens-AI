import requests
from bs4 import BeautifulSoup
import time
import random

class SymbiosScraper:
    """Symbios.pk - Fixed with longer timeout and retries"""
    
    def search_products(self, query, max_items=15, retries=3):
        print(f"\n🇵🇰 FETCHING from Symbios.pk for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        for attempt in range(retries):
            try:
                print(f"  🔄 Attempt {attempt + 1}/{retries}")
                time.sleep(random.uniform(5, 8))  # Longer delay
                
                url = f"https://symbios.pk/catalogsearch/result/?q={query.replace(' ', '+')}"
                response = requests.get(url, headers=headers, timeout=30)  # Increased timeout
                
                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    items = soup.select('.product-item') or soup.select('.item')
                    
                    products = []
                    for item in items[:max_items]:
                        try:
                            title = item.select_one('.product-name') or item.select_one('.name')
                            title = title.text.strip() if title else "Unknown"
                            
                            price = item.select_one('.price') or item.select_one('.special-price')
                            price_text = price.text.replace('Rs.', '').replace(',', '').strip() if price else "0"
                            
                            img = item.select_one('img')
                            img_url = ''
                            if img:
                                img_url = img.get('src', '')
                                if not img_url or 'placeholder' in img_url:
                                    img_url = img.get('data-src', '')
                            
                            if title and price_text and price_text != '0':
                                products.append({
                                    'name': title[:255],
                                    'price': float(price_text),
                                    'image_url': img_url,
                                    'platform': 'Symbios.pk',
                                    'seller': 'Symbios',
                                    'is_real': True
                                })
                                print(f"    ✅ {title[:40]}...")
                        except:
                            continue
                    
                    if products:
                        print(f"  ✅ Symbios.pk: Found {len(products)} products")
                        return products
                
                print(f"  ⚠️  Attempt {attempt + 1} failed, retrying...")
                
            except Exception as e:
                print(f"  ❌ Attempt {attempt + 1} error: {e}")
                if attempt == retries - 1:
                    print("  📋 No products from Symbios.pk")
                    return []
                time.sleep(10)
        
        return []
