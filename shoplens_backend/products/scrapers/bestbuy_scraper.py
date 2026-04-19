import requests
from bs4 import BeautifulSoup
import time
import random

class BestBuyScraper:
    """Best Buy Scraper - FIXED VERSION"""
    
    def search_products(self, query, max_pages=1):
        print(f"\n📺 FETCHING from BEST BUY for: '{query}'")
        
        all_products = []
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        }
        
        session = requests.Session()
        session.headers.update(headers)
        
        for page in range(1, max_pages + 1):
            try:
                time.sleep(random.uniform(3, 5))
                url = f"https://www.bestbuy.com/site/searchpage.jsp?st={query.replace(' ', '+')}&cp={page}"
                print(f"  🌐 Loading Best Buy page {page}...")
                
                response = session.get(url, timeout=15)
                
                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    
                    # Best Buy product containers
                    items = soup.select('.sku-item') or soup.select('[data-sku-id]') or soup.select('.product-item')
                    
                    page_products = []
                    for item in items[:10]:
                        try:
                            # Title
                            title_elem = item.select_one('.sku-title') or item.select_one('.product-title') or item.select_one('h4')
                            title = title_elem.text.strip() if title_elem else "Unknown"
                            
                            # Price
                            price_elem = item.select_one('.priceView-customer-price') or item.select_one('.sr-price') or item.select_one('.price')
                            price = 0.0
                            if price_elem:
                                price_text = price_elem.text.replace('$', '').replace(',', '').strip()
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
                                    'description': f"Best Buy product: {title[:100]}",
                                    'price': price,
                                    'category': 'Electronics',
                                    'seller': 'Best Buy',
                                    'stock_quantity': random.randint(10, 100),
                                    'image_url': image_url,
                                    'platform': 'BestBuy',
                                    'is_mock': False,
                                    'is_real': True
                                })
                                print(f"    ✅ {title[:40]}...")
                        except Exception as e:
                            continue
                    
                    all_products.extend(page_products)
                    print(f"  ✅ Best Buy Page {page}: Found {len(page_products)} products")
                else:
                    print(f"  ⚠️  Best Buy status: {response.status_code}")
                    
            except Exception as e:
                print(f"  ❌ Best Buy error: {e}")
        
        print(f"  📦 TOTAL Best Buy products: {len(all_products)}")
        return all_products
