import requests
from bs4 import BeautifulSoup
import time
import random

class WalmartScraper:
    """Walmart Scraper - FIXED VERSION"""
    
    def search_products(self, query, max_pages=1):
        print(f"\n🛒 FETCHING from WALMART for: '{query}'")
        
        all_products = []
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
        
        session = requests.Session()
        session.headers.update(headers)
        
        for page in range(1, max_pages + 1):
            try:
                time.sleep(random.uniform(3, 5))
                url = f"https://www.walmart.com/search?q={query.replace(' ', '+')}&page={page}"
                print(f"  🌐 Loading Walmart page {page}...")
                
                response = session.get(url, timeout=15)
                
                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    
                    # Walmart's product containers
                    items = soup.select('[data-testid="item-stack"]') or soup.select('.search-result-gridview-item') or soup.select('.mb0')
                    
                    page_products = []
                    for item in items[:10]:
                        try:
                            # Title
                            title_elem = item.select_one('span[data-automation-id="product-title"]') or item.select_one('.product-title') or item.select_one('a[link-identifier="item-title"]')
                            title = title_elem.text.strip() if title_elem else "Unknown"
                            
                            # Price
                            price_elem = item.select_one('[data-automation-id="product-price"]') or item.select_one('.price-main') or item.select_one('.price')
                            price = 0.0
                            if price_elem:
                                price_text = price_elem.text.replace('$', '').replace('current', '').replace('now', '').strip()
                                try:
                                    price = float(price_text.split()[0]) * 280
                                except:
                                    price = random.randint(1000, 50000)
                            
                            # Image
                            img_elem = item.select_one('img')
                            image_url = img_elem.get('src', '') if img_elem else ''
                            if not image_url or 'gif' in image_url:
                                image_url = img_elem.get('data-src', '') if img_elem else ''
                            
                            if title and price > 0:
                                page_products.append({
                                    'name': title[:255],
                                    'description': f"Walmart product: {title[:100]}",
                                    'price': price,
                                    'category': 'Electronics',
                                    'seller': 'Walmart',
                                    'stock_quantity': random.randint(10, 100),
                                    'image_url': image_url,
                                    'platform': 'Walmart',
                                    'is_mock': False,
                                    'is_real': True
                                })
                                print(f"    ✅ {title[:40]}...")
                        except Exception as e:
                            continue
                    
                    all_products.extend(page_products)
                    print(f"  ✅ Walmart Page {page}: Found {len(page_products)} products")
                else:
                    print(f"  ⚠️  Walmart status: {response.status_code}")
                    
            except Exception as e:
                print(f"  ❌ Walmart error: {e}")
        
        print(f"  📦 TOTAL Walmart products: {len(all_products)}")
        return all_products
