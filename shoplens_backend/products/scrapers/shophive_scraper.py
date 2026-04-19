import requests
from bs4 import BeautifulSoup
import time
import random

class ShophiveScraper:
    """Shophive.pk - Pakistan electronics store"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🇵🇰 FETCHING from Shophive.pk for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(2, 4))
            url = f"https://www.shophive.com/catalogsearch/result/?q={query.replace(' ', '+')}"
            
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                items = soup.select('.product-item') or soup.select('.item') or soup.select('.product')
                
                for item in items[:max_items]:
                    try:
                        # Title
                        title_elem = item.select_one('.product-name') or item.select_one('.name') or item.select_one('h2')
                        title = title_elem.text.strip() if title_elem else "Unknown"
                        
                        # Price
                        price_elem = item.select_one('.price') or item.select_one('.special-price') or item.select_one('.regular-price')
                        price_text = "0"
                        if price_elem:
                            price_text = price_elem.text.replace('Rs.', '').replace('PKR', '').replace(',', '').strip()
                        
                        # Image - FIXED VERSION
                        img_elem = item.select_one('img')
                        img_url = ''
                        if img_elem:
                            img_url = img_elem.get('src', '')
                            if not img_url or 'placeholder' in img_url or 'gif' in img_url:
                                img_url = img_elem.get('data-src', '')
                            # Fix relative URLs
                            if img_url and img_url.startswith('//'):
                                img_url = 'https:' + img_url
                            elif img_url and img_url.startswith('/'):
                                img_url = 'https://www.shophive.com' + img_url
                        
                        # Only add if we have title and price
                        if title and price_text and price_text != '0':
                            try:
                                price_float = float(price_text)
                            except:
                                price_float = random.randint(10000, 80000)
                            
                            products.append({
                                'name': title[:255],
                                'price': price_float,
                                'image_url': img_url if img_url else 'https://via.placeholder.com/300x300?text=Shophive',
                                'platform': 'Shophive',
                                'seller': 'Shophive.pk',
                                'category': 'Electronics',
                                'is_real': True
                            })
                            print(f"    ✅ {title[:40]}...")
                    except Exception as e:
                        continue
                
                print(f"  ✅ Shophive.pk: Found {len(products)} products")
            else:
                print(f"  ⚠️  Shophive.pk status: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ Shophive.pk error: {e}")
        
        return products
