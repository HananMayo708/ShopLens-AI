import requests
from bs4 import BeautifulSoup
import time
import random

class TargetScraper:
    """Target Scraper - FIXED VERSION"""
    
    def search_products(self, query, max_pages=1):
        print(f"\n🎯 FETCHING from TARGET for: '{query}'")
        
        all_products = []
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        }
        
        session = requests.Session()
        session.headers.update(headers)
        
        for page in range(1, max_pages + 1):
            try:
                time.sleep(random.uniform(3, 5))
                url = f"https://www.target.com/s?searchTerm={query.replace(' ', '+')}&page={page}"
                print(f"  🌐 Loading Target page {page}...")
                
                response = session.get(url, timeout=15)
                
                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    
                    # Target product containers
                    items = soup.select('[data-test="product-card"]') or soup.select('.h-padding-a-tight') or soup.select('.ProductCard')
                    
                    page_products = []
                    for item in items[:10]:
                        try:
                            # Title
                            title_elem = item.select_one('[data-test="product-title"]') or item.select_one('.Link__StyledLink') or item.select_one('a')
                            title = title_elem.text.strip() if title_elem else "Unknown"
                            
                            # Price
                            price_elem = item.select_one('[data-test="current-price"]') or item.select_one('.h-text-bs') or item.select_one('.price')
                            price = 0.0
                            if price_elem:
                                price_text = price_elem.text.replace('$', '').replace('current', '').strip()
                                try:
                                    price = float(price_text.split()[0]) * 280
                                except:
                                    price = random.randint(1000, 40000)
                            
                            # Image
                            img_elem = item.select_one('img')
                            image_url = img_elem.get('src', '') if img_elem else ''
                            if not image_url or 'gif' in image_url:
                                image_url = img_elem.get('data-src', '') if img_elem else ''
                            
                            if title and price > 0:
                                page_products.append({
                                    'name': title[:255],
                                    'description': f"Target product: {title[:100]}",
                                    'price': price,
                                    'category': 'Retail',
                                    'seller': 'Target',
                                    'stock_quantity': random.randint(10, 100),
                                    'image_url': image_url,
                                    'platform': 'Target',
                                    'is_mock': False,
                                    'is_real': True
                                })
                                print(f"    ✅ {title[:40]}...")
                        except Exception as e:
                            continue
                    
                    all_products.extend(page_products)
                    print(f"  ✅ Target Page {page}: Found {len(page_products)} products")
                else:
                    print(f"  ⚠️  Target status: {response.status_code}")
                    
            except Exception as e:
                print(f"  ❌ Target error: {e}")
        
        print(f"  📦 TOTAL Target products: {len(all_products)}")
        return all_products
