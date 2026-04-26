import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
from django.conf import settings

class MultiStoreProductService:
    def __init__(self):
        self.api_key = settings.SCRAPERAPI_KEY
    
    def search_all_stores_parallel(self, query, limit_per_store=10):
        """Search all stores SIMULTANEOUSLY - FAST!"""
        
        all_products = []
        
        # Define all store functions
        store_functions = [
            ("Amazon", self.search_amazon),
            ("eBay", self.search_ebay),
            ("Walmart", self.search_walmart),
            ("Daraz.pk", self.search_daraz),
            ("AliExpress", self.search_aliexpress),
        ]
        
        # Run all searches in parallel
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {
                executor.submit(func, query, limit_per_store): name 
                for name, func in store_functions
            }
            
            for future in as_completed(futures):
                store_name = futures[future]
                try:
                    products = future.result(timeout=60)
                    all_products.extend(products)
                    print(f"✅ {store_name}: {len(products)} products")
                except Exception as e:
                    print(f"❌ {store_name} failed: {e}")
        
        return all_products
    
    def search_amazon(self, query, limit=10):
        """Scrape Amazon products"""
        response = requests.get(
            "https://api.scraperapi.com/",
            params={"api_key": self.api_key, "url": f"https://www.amazon.com/s?k={query.replace(' ', '+')}", "render": True},
            timeout=60
        )
        soup = BeautifulSoup(response.text, "html.parser")
        items = soup.select('[data-component-type="s-search-result"]')
        
        products = []
        for item in items[:limit]:
            try:
                name_elem = item.select_one("h2 span")
                price_elem = item.select_one(".a-price .a-offscreen")
                image_elem = item.select_one("img.s-image")
                link_elem = item.select_one("h2 a")
                
                if not name_elem or not price_elem:
                    continue
                
                href = link_elem.get("href", "") if link_elem else ""
                if href.startswith("/"):
                    href = "https://amazon.com" + href
                
                products.append({
                    "id": f"amzn_{hash(name_elem.text)}",
                    "name": name_elem.text.strip(),
                    "price": float(price_elem.text.replace('$', '').replace(',', '')),
                    "image_url": image_elem.get("src") if image_elem else "",
                    "source": "Amazon",
                    "product_url": href,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_elem.text.strip(),
                    "category": "Electronics",
                })
            except Exception as e:
                continue
        return products
    
    def search_ebay(self, query, limit=10):
        """Scrape eBay products"""
        response = requests.get(
            "https://api.scraperapi.com/",
            params={"api_key": self.api_key, "url": f"https://www.ebay.com/sch/i.html?_nkw={query.replace(' ', '+')}", "render": True},
            timeout=60
        )
        soup = BeautifulSoup(response.text, "html.parser")
        
        if soup.select("li.s-card"):
            items = soup.select("li.s-card")
            title_selector = ".s-card__title"
            price_selector = ".s-card__price"
            image_selector = ".s-card__image"
            link_selector = "a.su-link"
        elif soup.select("li.s-item"):
            items = soup.select("li.s-item")
            title_selector = ".s-item__title"
            price_selector = ".s-item__price"
            image_selector = ".s-item__image-img"
            link_selector = "a.s-item__link"
        else:
            return []
        
        products = []
        for item in items[:limit]:
            try:
                title = item.select_one(title_selector)
                if not title or "Shop on eBay" in title.text:
                    continue
                price_spans = item.select(price_selector)
                price_text = price_spans[0].get_text(strip=True) if price_spans else "0"
                image = item.select_one(image_selector)
                link = item.select_one(link_selector)
                price = float(price_text.replace('$', '').replace(',', '')) if price_text else 0
                
                products.append({
                    "id": f"ebay_{hash(title.text)}",
                    "name": title.get_text(strip=True),
                    "price": price,
                    "image_url": image.get("src") if image else "",
                    "source": "eBay",
                    "product_url": link.get("href") if link else "",
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": title.get_text(strip=True),
                    "category": "Electronics",
                })
            except Exception:
                continue
        return products
    
    def search_walmart(self, query, limit=10):
        """Scrape Walmart products"""
        response = requests.get(
            "https://api.scraperapi.com/",
            params={"api_key": self.api_key, "url": f"https://www.walmart.com/search?q={query.replace(' ', '+')}", "render": True},
            timeout=60
        )
        soup = BeautifulSoup(response.text, "html.parser")
        items = soup.select('[data-automation-id="product-tile"]') or soup.select('[data-item-id]')
        
        products = []
        for item in items[:limit]:
            try:
                name = item.select_one('[data-automation-id="product-title"]') or item.select_one("h3")
                price = item.select_one('[data-automation-id="product-price"] .f2') or item.select_one(".f2")
                image = item.select_one("img")
                link = item.select_one("a")
                if not name or not price:
                    continue
                price_text = price.text.strip()
                if "Now" in price_text and "Was" in price_text:
                    parts = price_text.split("Was")
                    price_text = parts[0].replace("Now", "").replace("current price", "").strip()
                href = link.get("href", "") if link else ""
                if href.startswith("/"):
                    href = "https://www.walmart.com" + href
                
                products.append({
                    "id": f"wmt_{hash(name.text)}",
                    "name": name.text.strip(),
                    "price": float(price_text) if price_text else 0,
                    "image_url": image.get("src") if image else "",
                    "source": "Walmart",
                    "product_url": href,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name.text.strip(),
                    "category": "Electronics",
                })
            except Exception:
                continue
        return products
    
    def search_daraz(self, query, limit=10):
        """Scrape Daraz.pk products"""
        try:
            response = requests.get(
                "https://www.daraz.pk/catalog/",
                params={"ajax": "true", "q": query, "page": "1", "_keyori": "ss"},
                headers={
                    "User-Agent": "Mozilla/5.0",
                    "Accept": "application/json",
                    "X-Requested-With": "XMLHttpRequest"
                },
                timeout=30
            )
            data = response.json()
            items = data.get("mods", {}).get("listItems", [])
            
            products = []
            for item in items[:limit]:
                name = item.get("name", "")
                price_text = item.get("priceShow", "")
                price = float(price_text.replace('Rs.', '').replace(',', '')) if price_text else 0
                product_url = item.get("itemUrl", "")
                if product_url.startswith("//"):
                    product_url = "https:" + product_url
                
                products.append({
                    "id": f"dz_{hash(name)}",
                    "name": name,
                    "price": price,
                    "image_url": item.get("image", ""),
                    "source": "Daraz.pk",
                    "product_url": product_url,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name,
                    "category": "Electronics",
                })
            return products
        except Exception as e:
            print(f"Daraz error: {e}")
            return []
    
    def search_aliexpress(self, query, limit=10):
        """Scrape AliExpress products"""
        response = requests.get(
            "https://api.scraperapi.com/",
            params={"api_key": self.api_key, "url": f"https://www.aliexpress.com/w/wholesale-{query.replace(' ', '-')}.html", "render": True},
            timeout=60
        )
        soup = BeautifulSoup(response.text, "html.parser")
        items = soup.select('[data-product-id]') or soup.select('.search-card-item')
        
        products = []
        for item in items[:limit]:
            try:
                name = item.select_one('a[title]') or item.select_one('h3')
                if not name:
                    continue
                name_text = name.get("title") or name.text.strip()
                price = item.select_one('.price-current') or item.select_one('[class*="price"]')
                price_text = price.text.strip() if price else "0"
                price = float(price_text.replace('$', '').replace(',', '')) if price_text else 0
                image = item.select_one("img")
                image_url = image.get("src") if image else ""
                if image_url.startswith("//"):
                    image_url = "https:" + image_url
                link = item.select_one("a")
                href = link.get("href", "") if link else ""
                if href.startswith("//"):
                    href = "https:" + href
                
                products.append({
                    "id": f"alx_{hash(name_text)}",
                    "name": name_text,
                    "price": price,
                    "image_url": image_url,
                    "source": "AliExpress",
                    "product_url": href,
                    "rating": 4.0,
                    "review_count": 0,
                    "in_stock": True,
                    "description": name_text,
                    "category": "Electronics",
                })
            except Exception:
                continue
        return products