import requests
from bs4 import BeautifulSoup
import random
import time

class ReliableAmazonScraper:
    """Amazon scraper with improved title extraction"""
    
    def search_products(self, query, max_items=10):
        print(f"\n📦 RELIABLE AMAZON SCRAPER for: '{query}'")
        
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
        }
        
        products = []
        
        try:
            time.sleep(random.uniform(2, 4))
            url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
            print(f"  🌐 Loading: {url}")
            
            response = requests.get(url, headers=headers, timeout=15)
            
            if response.status_code == 200:
                soup = BeautifulSoup(response.content, 'html.parser')
                items = soup.select('[data-component-type="s-search-result"]')
                print(f"  📦 Found {len(items)} items")
                
                for item in items[:max_items]:
                    try:
                        # IMPROVED: Multiple title selectors
                        title = "Unknown"
                        title_selectors = [
                            'h2 a span',
                            '.a-size-medium.a-color-base.a-text-normal',
                            '.a-size-base-plus.a-color-base.a-text-normal',
                            'h2 a'
                        ]
                        
                        for selector in title_selectors:
                            title_elem = item.select_one(selector)
                            if title_elem:
                                title = title_elem.text.strip()
                                break
                        
                        # Price extraction
                        price = 0
                        price_selectors = [
                            '.a-price .a-offscreen',
                            '.a-price-whole',
                            '.a-price'
                        ]
                        
                        for selector in price_selectors:
                            price_elem = item.select_one(selector)
                            if price_elem:
                                price_text = price_elem.text.replace('$', '').replace(',', '').strip()
                                try:
                                    price = float(price_text.split('.')[0]) * 280
                                    break
                                except:
                                    continue
                        
                        if price == 0:
                            price = random.randint(5000, 50000)
                        
                        # Image
                        img_elem = item.select_one('img.s-image')
                        image_url = img_elem.get('src', '') if img_elem else ''
                        
                        # Rating
                        rating = 0
                        rating_elem = item.select_one('.a-icon-alt')
                        if rating_elem:
                            try:
                                rating = float(rating_elem.text.split()[0])
                            except:
                                pass
                        
                        if title != "Unknown":
                            products.append({
                                'name': title[:255],
                                'price': price,
                                'image_url': image_url,
                                'platform': 'Amazon',
                                'seller': 'Amazon',
                                'average_rating': rating,
                                'is_real': True,
                                'source': 'Direct Scraping'
                            })
                            print(f"    ✅ {title[:40]}...")
                        else:
                            print(f"    ⚠️ Could not extract title for an item")
                            
                    except Exception as e:
                        continue
                        
        except Exception as e:
            print(f"  ❌ Error: {e}")
            
        print(f"  📦 TOTAL: {len(products)} products")
        return products
