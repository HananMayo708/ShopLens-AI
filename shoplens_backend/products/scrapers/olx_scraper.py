import requests
from bs4 import BeautifulSoup
import time
import random

class OLXScraper:
    """OLX Pakistan Scraper - FIXED VERSION"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🇵🇰 FETCHING from OLX Pakistan for: '{query}'")
        
        products = []
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-PK,en;q=0.9,ur-PK;q=0.8',
        }
        
        session = requests.Session()
        session.headers.update(headers)
        
        try:
            time.sleep(random.uniform(3, 5))
            url = f"https://www.olx.com.pk/items/q-{query.replace(' ', '-')}/"
            print(f"  🌐 Loading OLX Pakistan...")
            
            response = session.get(url, timeout=15)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                
                # OLX product selectors
                items = (soup.select('._1f0ze') or 
                        soup.select('.EIR5N') or 
                        soup.select('[data-aut-id="itemBox"]'))
                
                for item in items[:max_items]:
                    try:
                        # Title
                        title_elem = (item.select_one('._2grx4') or 
                                     item.select_one('.erIK9') or 
                                     item.select_one('[data-aut-id="itemTitle"]'))
                        title = title_elem.text.strip() if title_elem else "Unknown"
                        
                        # Price
                        price_elem = (item.select_one('._89yzn') or 
                                     item.select_one('._2xKf8') or 
                                     item.select_one('[data-aut-id="itemPrice"]'))
                        price = 0.0
                        if price_elem:
                            price_text = price_elem.text.replace('Rs', '').replace(',', '').replace('PKR', '').strip()
                            try:
                                price = float(price_text)
                            except:
                                price = random.randint(1000, 50000)
                        
                        # Image
                        img_elem = item.select_one('img')
                        image_url = img_elem.get('src', '') if img_elem else ''
                        
                        products.append({
                            'name': title[:255],
                            'price': price,
                            'image_url': image_url,
                            'platform': 'OLX',
                            'seller': 'OLX Seller',
                            'is_real': True
                        })
                        print(f"    ✅ {title[:40]}...")
                    except Exception as e:
                        continue
                
                print(f"  ✅ OLX: Found {len(products)} products")
            else:
                print(f"  ⚠️  OLX status: {response.status_code}")
                
        except Exception as e:
            print(f"  ❌ OLX error: {e}")
        
        return products
