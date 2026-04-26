import requests
from bs4 import BeautifulSoup
import re
import time
from django.conf import settings

class MultiStoreService:
    def __init__(self):
        self.api_key = settings.SCRAPERAPI_KEY
        self.base_url = "https://api.scraperapi.com/"
    
    def search_all_stores(self, query, limit=20):
        """Search all 5 stores and return products"""
        all_products = []
        
        print(f"🔍 Searching all stores for: {query}")
        
        # Search Daraz.pk (Pakistan's largest marketplace)
        try:
            products = self.search_daraz(query, limit)
            all_products.extend(products)
            print(f"✅ Daraz.pk: {len(products)} products")
        except Exception as e:
            print(f"❌ Daraz.pk error: {e}")
        
        # Search eBay
        try:
            products = self.search_ebay(query, limit)
            all_products.extend(products)
            print(f"✅ eBay: {len(products)} products")
        except Exception as e:
            print(f"❌ eBay error: {e}")
        
        # Search Amazon
        try:
            products = self.search_amazon(query, limit)
            all_products.extend(products)
            print(f"✅ Amazon: {len(products)} products")
        except Exception as e:
            print(f"❌ Amazon error: {e}")
        
        # Search AliExpress
        try:
            products = self.search_aliexpress(query, limit)
            all_products.extend(products)
            print(f"✅ AliExpress: {len(products)} products")
        except Exception as e:
            print(f"❌ AliExpress error: {e}")
        
        # Search Walmart
        try:
            products = self.search_walmart(query, limit)
            all_products.extend(products)
            print(f"✅ Walmart: {len(products)} products")
        except Exception as e:
            print(f"❌ Walmart error: {e}")
        
        return {
            'success': True,
            'products': all_products,
            'total': len(all_products)
        }
    
    def _fetch_page(self, url):
        """Fetch page using ScraperAPI"""
        try:
            response = requests.get(
                self.base_url,
                params={
                    "api_key": self.api_key,
                    "url": url,
                    "render": True,
                    "country_code": "us",
                    "device_type": "desktop",
                },
                timeout=45,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                }
            )
            return BeautifulSoup(response.text, "html.parser")
        except Exception as e:
            print(f"⚠️ Fetch error: {e}")
            return None
    
    def _extract_price(self, price_text):
        """Extract numeric price from text"""
        if not price_text:
            return 0.0
        cleaned = re.sub(r'[^\d.,]', '', price_text)
        match = re.search(r'[\d,]+\.?\d*', cleaned)
        if match:
            return float(match.group().replace(',', ''))
        return 0.0
    
    def search_daraz(self, query, limit=20):
        """Scrape Daraz.pk products"""
        url = f"https://www.daraz.pk/catalog/?q={query.replace(' ', '%20')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('.card-jfyugm')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('.title--yKCmn')
                price_elem = item.select_one('.price--NvLrE')
                image_elem = item.select_one('img')
                link_elem = item.select_one('a')
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = ""
                if link_elem:
                    product_url = link_elem.get("href", "")
                    if not product_url.startswith("http"):
                        product_url = f"https://www.daraz.pk{product_url}"
                
                products.append({
                    "id": f"daraz_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Daraz.pk",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        
        return products
    
    def search_ebay(self, query, limit=20):
        """Scrape eBay products"""
        url = f"https://www.ebay.com/sch/i.html?_nkw={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('.s-item')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('.s-item__title')
                price_elem = item.select_one('.s-item__price')
                old_price_elem = item.select_one('.s-item__price .STRIKE')
                image_elem = item.select_one('.s-item__image-img')
                link_elem = item.select_one('.s-item__link')
                
                if not name_elem or not price_elem or name_elem.text == "Shop on eBay":
                    continue
                
                product_url = link_elem.get("href", "") if link_elem else ""
                
                products.append({
                    "id": f"ebay_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "original_price": self._extract_price(old_price_elem.text) if old_price_elem else None,
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "eBay",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        
        return products
    
    def search_amazon(self, query, limit=20):
        """Scrape Amazon products"""
        url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('[data-component-type="s-search-result"]')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one("h2 span")
                price_elem = item.select_one(".a-price .a-offscreen")
                old_price_elem = item.select_one(".a-price .a-text-strike")
                image_elem = item.select_one("img.s-image")
                link_elem = item.select_one("h2 a")
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = ""
                if link_elem:
                    product_url = link_elem.get("href", "")
                    if product_url.startswith("/"):
                        product_url = f"https://amazon.com{product_url}"
                
                products.append({
                    "id": f"amzn_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "original_price": self._extract_price(old_price_elem.text) if old_price_elem else None,
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Amazon",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        
        return products
    
    def search_aliexpress(self, query, limit=20):
        """Scrape AliExpress products"""
        url = f"https://www.aliexpress.com/wholesale?SearchText={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('.list-item')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('.item-title')
                price_elem = item.select_one('.price-current')
                image_elem = item.select_one('img')
                link_elem = item.select_one('a')
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = ""
                if link_elem:
                    product_url = link_elem.get("href", "")
                    if not product_url.startswith("http"):
                        product_url = f"https://aliexpress.com{product_url}"
                
                products.append({
                    "id": f"ali_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "AliExpress",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        
        return products
    
    def search_walmart(self, query, limit=20):
        """Scrape Walmart products"""
        url = f"https://www.walmart.com/search?q={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('[data-testid="item-stack"]')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('[data-testid="product-title"]')
                price_elem = item.select_one('[data-testid="price"]')
                old_price_elem = item.select_one('[data-testid="was-price"]')
                image_elem = item.select_one('img')
                link_elem = item.select_one('a')
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = ""
                if link_elem:
                    product_url = link_elem.get("href", "")
                    if not product_url.startswith("http"):
                        product_url = f"https://walmart.com{product_url}"
                
                products.append({
                    "id": f"wmt_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "original_price": self._extract_price(old_price_elem.text) if old_price_elem else None,
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Walmart",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        
        return products