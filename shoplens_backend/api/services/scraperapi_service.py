import requests
from bs4 import BeautifulSoup
import re
import time
from django.conf import settings

class ScraperAPIService:
    def __init__(self):
        self.api_key = settings.SCRAPERAPI_KEY
        self.base_url = "https://api.scraperapi.com/"
    
    def search_all_sources(self, query, limit=20):
        """Search all 5 websites in parallel"""
        all_products = []
        
        print(f"🔍 Searching all sources for: {query}")
        
        # Search Amazon
        try:
            products = self.search_amazon(query, limit)
            all_products.extend(products)
            print(f"✅ Amazon: {len(products)} products")
        except Exception as e:
            print(f"❌ Amazon error: {e}")
        
        # Search Walmart
        try:
            products = self.search_walmart(query, limit)
            all_products.extend(products)
            print(f"✅ Walmart: {len(products)} products")
        except Exception as e:
            print(f"❌ Walmart error: {e}")
        
        # Search Best Buy
        try:
            products = self.search_bestbuy(query, limit)
            all_products.extend(products)
            print(f"✅ Best Buy: {len(products)} products")
        except Exception as e:
            print(f"❌ Best Buy error: {e}")
        
        # Search Target
        try:
            products = self.search_target(query, limit)
            all_products.extend(products)
            print(f"✅ Target: {len(products)} products")
        except Exception as e:
            print(f"❌ Target error: {e}")
        
        # Search eBay
        try:
            products = self.search_ebay(query, limit)
            all_products.extend(products)
            print(f"✅ eBay: {len(products)} products")
        except Exception as e:
            print(f"❌ eBay error: {e}")
        
        return all_products
    
    def _fetch_page(self, url):
        """Fetch page using ScraperAPI with better headers"""
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
                    'Accept-Language': 'en-US,en;q=0.5',
                }
            )
            return BeautifulSoup(response.text, "html.parser")
        except Exception as e:
            print(f"⚠️ Fetch error: {e}")
            return None
    
    def _extract_price(self, price_text):
        """Extract numeric price from text like '$19.99'"""
        if not price_text:
            return 0.0
        # Remove currency symbols and commas
        cleaned = re.sub(r'[^\d.,]', '', price_text)
        match = re.search(r'[\d,]+\.?\d*', cleaned)
        if match:
            return float(match.group().replace(',', ''))
        return 0.0
    
    def _extract_rating(self, item):
        """Extract rating from product item"""
        try:
            # Amazon rating
            rating_elem = item.select_one(".a-icon-alt")
            if rating_elem:
                match = re.search(r'([\d.]+)', rating_elem.text)
                if match:
                    return float(match.group(1))
            
            # Walmart rating
            rating_elem = item.select_one('[data-testid="product-ratings"]')
            if rating_elem:
                match = re.search(r'([\d.]+)', rating_elem.text)
                if match:
                    return float(match.group(1))
        except:
            pass
        return 4.0
    
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
                    "rating": self._extract_rating(item),
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                print(f"⚠️ Amazon parse error: {e}")
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
                print(f"⚠️ Walmart parse error: {e}")
                continue
        
        return products
    
    def search_bestbuy(self, query, limit=20):
        """Scrape Best Buy products"""
        url = f"https://www.bestbuy.com/site/searchpage.jsp?st={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('.sku-item')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('.sku-title h4 a')
                price_elem = item.select_one('.priceView-customer-price span')
                old_price_elem = item.select_one('.priceView-price-now .priceView-sale-price')
                image_elem = item.select_one('.product-image img')
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = name_elem.get("href", "") if name_elem else ""
                if product_url and not product_url.startswith("http"):
                    product_url = f"https://bestbuy.com{product_url}"
                
                products.append({
                    "id": f"bb_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "original_price": self._extract_price(old_price_elem.text) if old_price_elem else None,
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Best Buy",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                print(f"⚠️ Best Buy parse error: {e}")
                continue
        
        return products
    
    def search_target(self, query, limit=20):
        """Scrape Target products"""
        url = f"https://www.target.com/s?searchTerm={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        if not soup:
            return []
        
        products = []
        items = soup.select('[data-test="product-grid"] div')
        
        for item in items[:limit]:
            try:
                name_elem = item.select_one('[data-test="product-title"]')
                price_elem = item.select_one('[data-test="current-price"]')
                old_price_elem = item.select_one('[data-test="was-price"]')
                image_elem = item.select_one('picture img')
                link_elem = item.select_one('a')
                
                if not name_elem or not price_elem:
                    continue
                
                product_url = ""
                if link_elem:
                    product_url = link_elem.get("href", "")
                    if not product_url.startswith("http"):
                        product_url = f"https://target.com{product_url}"
                
                products.append({
                    "id": f"tgt_{abs(hash(name_elem.text)) % 10000000}",
                    "name": name_elem.text.strip(),
                    "price": self._extract_price(price_elem.text),
                    "original_price": self._extract_price(old_price_elem.text) if old_price_elem else None,
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Target",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                print(f"⚠️ Target parse error: {e}")
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
                print(f"⚠️ eBay parse error: {e}")
                continue
        
        return products