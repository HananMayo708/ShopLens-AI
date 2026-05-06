import requests
from bs4 import BeautifulSoup
import re
import concurrent.futures
from django.conf import settings
from django.utils import timezone

class MultiStoreService:
    def __init__(self):
        self.api_key = settings.SCRAPERAPI_KEY
        self.base_url = "https://api.scraperapi.com/"
    
    def search_all_stores(self, query, limit=20, save_to_db=True):
        print(f"Searching all stores for: {query}")
        
        all_products = []
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = {
                executor.submit(self.search_amazon, query, limit): "Amazon",
                executor.submit(self.search_ebay, query, limit): "eBay",
                executor.submit(self.search_walmart, query, limit): "Walmart",
                executor.submit(self.search_daraz, query, limit): "Daraz.pk",
                executor.submit(self.search_aliexpress, query, limit): "AliExpress",
            }
            
            for future in concurrent.futures.as_completed(futures):
                store_name = futures[future]
                try:
                    products = future.result(timeout=60)
                    all_products.extend(products)
                    print(f"Store {store_name}: {len(products)} products")
                except Exception as e:
                    print(f"Store {store_name}: Error - {str(e)[:50]}")
        
        # SAVE TO DATABASE
        if save_to_db and all_products:
            try:
                from products.models import Product, Seller, Category
                
                saved_count = 0
                for product_data in all_products:
                    try:
                        # Get or create seller with required fields
                        seller, created = Seller.objects.get_or_create(
                            name=product_data['source'],
                            defaults={
                                'website': f"https://www.{product_data['source'].lower().replace('.pk', '')}.com",
                                'rating': 4.0,
                                'contact_email': f"contact@{product_data['source'].lower().replace('.pk', '')}.com"
                            }
                        )
                        
                        # Update seller if no website
                        if not created and not seller.website:
                            seller.website = f"https://www.{product_data['source'].lower().replace('.pk', '')}.com"
                            seller.save()
                        
                        # Get or create category
                        category, _ = Category.objects.get_or_create(name='Electronics')
                        
                        # Create unique SKU
                        sku = f"{product_data['source'][:3]}_{product_data['id']}"
                        
                        # Check if product already exists
                        if not Product.objects.filter(sku=sku).exists():
                            Product.objects.create(
                                name=product_data['name'][:200],
                                description=product_data.get('description', '')[:500],
                                price=product_data['price'],
                                seller=seller,
                                category=category,
                                sku=sku,
                                stock_quantity=100,
                                image_url=product_data.get('image_url', ''),
                                average_rating=product_data.get('rating', 4.0),
                                review_count=0,
                                is_active=True,
                                created_at=timezone.now(),
                                updated_at=timezone.now(),
                            )
                            saved_count += 1
                    except Exception as e:
                        print(f"Error saving product: {e}")
                        continue
                
                print(f"💾 SAVED {saved_count} products to database!")
            except Exception as e:
                print(f"Database error: {e}")
        
        print(f"Total products: {len(all_products)}")
        
        return {
            'success': True,
            'products': all_products,
            'total': len(all_products)
        }
    
    def _fetch_page(self, url, render=True):
        """Fetch page using ScraperAPI"""
        try:
            response = requests.get(
                self.base_url,
                params={
                    "api_key": self.api_key,
                    "url": url,
                    "render": render,
                    "country_code": "us",
                },
                timeout=60,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                }
            )
            return BeautifulSoup(response.text, "html.parser")
        except Exception as e:
            print(f"Fetch error: {e}")
            return None
    
    def _extract_price(self, price_text):
        """Extract numeric price from text"""
        if not price_text:
            return 19.99
        # Handle currency symbols and commas
        cleaned = re.sub(r'[^\d.,]', '', str(price_text))
        match = re.search(r'[\d,]+\.?\d*', cleaned)
        if match:
            try:
                return float(match.group().replace(',', ''))
            except:
                return 19.99
        return 19.99
    
    def search_amazon(self, query, limit=20):
        """Scrape Amazon search results"""
        print(f"🔍 Searching Amazon for: '{query}'...")
        
        url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        
        if not soup:
            return []
        
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
                
                name = name_elem.text.strip()
                price = self._extract_price(price_elem.text)
                image_url = image_elem.get("src") if image_elem else ""
                
                href = ""
                if link_elem:
                    href = link_elem.get("href", "")
                    if href.startswith("/"):
                        href = "https://amazon.com" + href
                    elif href and not href.startswith("http"):
                        href = "https://amazon.com/" + href
                
                products.append({
                    "id": f"amzn_{abs(hash(name)) % 10000000}",
                    "name": name,
                    "price": price,
                    "image_url": image_url,
                    "source": "Amazon",
                    "product_url": href,
                    "rating": 4.0,
                    "description": name,
                    "category": "Electronics",
                    "in_stock": True,
                })
            except Exception as e:
                continue
        
        print(f"   Found {len(products)} Amazon products")
        return products
    
    def search_ebay(self, query, limit=20):
        """Scrape eBay search results with layout detection"""
        print(f"🔍 Searching eBay for: '{query}'...")
        
        url = f"https://www.ebay.com/sch/i.html?_nkw={query.replace(' ', '+')}"
        soup = self._fetch_page(url)
        
        if not soup:
            return []
        
        # Detect eBay layout
        if soup.select("li.s-card"):
            items = soup.select("li.s-card")
            title_selector = ".s-card__title"
            price_selector = ".s-card__price"
            image_selector = ".s-card__image"
            link_selector = "a.su-link"
            print(f"   Detected layout: s-card ({len(items)} items)")
        elif soup.select("li.s-item"):
            items = soup.select("li.s-item")
            title_selector = ".s-item__title"
            price_selector = ".s-item__price"
            image_selector = ".s-item__image-img"
            link_selector = "a.s-item__link"
            print(f"   Detected layout: s-item ({len(items)} items)")
        else:
            print("   ⚠️ Unknown eBay layout")
            return []
        
        products = []
        for item in items[:limit]:
            try:
                title = item.select_one(title_selector)
                if not title:
                    continue
                
                title_text = title.get_text(strip=True)
                if "Shop on eBay" in title_text or not title_text or len(title_text) < 5:
                    continue
                
                price_spans = item.select(price_selector)
                if len(price_spans) > 1:
                    price_text = " ".join([span.get_text(strip=True) for span in price_spans])
                elif price_spans:
                    price_text = price_spans[0].get_text(strip=True)
                else:
                    continue
                
                price = self._extract_price(price_text)
                image = item.select_one(image_selector)
                image_url = image.get("src") if image else ""
                link = item.select_one(link_selector)
                href = link.get("href") if link else ""
                
                products.append({
                    "id": f"ebay_{abs(hash(title_text)) % 10000000}",
                    "name": title_text,
                    "price": price,
                    "image_url": image_url,
                    "source": "eBay",
                    "product_url": href,
                    "rating": 4.0,
                    "description": title_text,
                    "category": "Electronics",
                    "in_stock": True,
                })
            except Exception as e:
                continue
        
        print(f"   Found {len(products)} eBay products")
        return products
    
    def search_walmart(self, query, limit=20):
        """Scrape Walmart search results with multiple strategies"""
        print(f"🔍 Searching Walmart for: '{query}'...")
        
        strategies = [
            {"name": "Main site", "render": True},
            {"name": "No render (faster)", "render": False}
        ]
        
        for strategy in strategies:
            print(f"   Trying {strategy['name']}...")
            
            url = f"https://www.walmart.com/search?q={query.replace(' ', '+')}"
            soup = self._fetch_page(url, render=strategy["render"])
            
            if not soup:
                continue
            
            title = soup.find("title")
            if title and any(word in title.text for word in ["Robot", "Verify", "Captcha", "Access Denied"]):
                print(f"   ⚠️ Blocked on {strategy['name']}")
                continue
            
            items = (soup.select('[data-automation-id="product-tile"]') or 
                     soup.select('[data-item-id]'))
            
            print(f"   Found {len(items)} items on {strategy['name']}")
            
            if items:
                products = []
                for item in items[:limit]:
                    try:
                        name = (item.select_one('[data-automation-id="product-title"]') or 
                                item.select_one("h3") or
                                item.select_one("h3 a span"))
                        
                        if not name:
                            continue
                        
                        name_text = name.text.strip()
                        if not name_text or len(name_text) < 5:
                            continue
                        
                        price = None
                        for selector in ['[data-automation-id="product-price"] .f2',
                                         '[data-automation-id="product-price"] span',
                                         '[data-automation-id="product-price"]',
                                         ".f2"]:
                            price_el = item.select_one(selector)
                            if price_el:
                                price = price_el
                                break
                        
                        if not price:
                            continue
                        
                        price_text = price.text.strip()
                        if "Now" in price_text and "Was" in price_text:
                            parts = price_text.split("Was")
                            price_text = parts[0].replace("Now", "").replace("current price", "").strip()
                        
                        price_value = self._extract_price(price_text)
                        image = item.select_one("img")
                        image_url = image.get("src") if image else ""
                        
                        link = item.select_one("a[href*='/ip/']") or item.select_one("a")
                        href = ""
                        if link:
                            href = link.get("href", "")
                            if href.startswith("/"):
                                href = "https://www.walmart.com" + href
                            elif href and not href.startswith("http"):
                                href = "https://www.walmart.com/" + href
                        
                        products.append({
                            "id": f"wmt_{abs(hash(name_text)) % 10000000}",
                            "name": name_text,
                            "price": price_value,
                            "image_url": image_url,
                            "source": "Walmart",
                            "product_url": href,
                            "rating": 4.0,
                            "description": name_text,
                            "category": "Electronics",
                            "in_stock": True,
                        })
                    except Exception:
                        continue
                
                if products:
                    print(f"   ✅ Success with {strategy['name']}")
                    print(f"   Found {len(products)} Walmart products")
                    return products
        
        print("   ❌ All Walmart strategies failed")
        return []
    
    def search_daraz(self, query, limit=20):
        """Scrape Daraz.pk using their JSON API endpoint"""
        print(f"🔍 Searching Daraz.pk for: '{query}'...")
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "application/json, text/plain, */*",
            "Referer": "https://www.daraz.pk/",
            "X-Requested-With": "XMLHttpRequest"
        }
        
        params = {
            "ajax": "true",
            "q": query,
            "page": "1",
            "_keyori": "ss"
        }
        
        try:
            # Try direct API first
            response = requests.get("https://www.daraz.pk/catalog/", params=params, headers=headers, timeout=30)
            print(f"   Status: {response.status_code}")
            
            try:
                data = response.json()
            except:
                # Fallback to ScraperAPI
                scraper_response = requests.get(
                    self.base_url,
                    params={
                        "api_key": self.api_key,
                        "url": f"https://www.daraz.pk/catalog/?ajax=true&q={query.replace(' ', '+')}&page=1",
                    },
                    timeout=60
                )
                data = scraper_response.json()
            
            products_data = data.get("mods", {}).get("listItems", [])
            print(f"   Found {len(products_data)} products in JSON")
            
            products = []
            for item in products_data[:limit]:
                try:
                    name = item.get("name", "")
                    price_str = item.get("priceShow", "")
                    
                    if not name or not price_str:
                        continue
                    
                    price = self._extract_price(price_str)
                    
                    # Convert PKR to USD approximately
                    if price > 100:
                        price = round(price / 278, 2)
                    
                    image = item.get("image", "")
                    product_url = item.get("itemUrl", "")
                    
                    if product_url.startswith("//"):
                        product_url = "https:" + product_url
                    elif product_url.startswith("/"):
                        product_url = "https://www.daraz.pk" + product_url
                    
                    products.append({
                        "id": f"daraz_{abs(hash(name)) % 10000000}",
                        "name": name,
                        "price": price,
                        "image_url": image,
                        "source": "Daraz.pk",
                        "product_url": product_url,
                        "rating": 4.0,
                        "description": name,
                        "category": "Electronics",
                        "in_stock": True,
                    })
                except Exception:
                    continue
            
            print(f"   Found {len(products)} Daraz products")
            return products
            
        except Exception as e:
            print(f"   Daraz error: {e}")
            return []
    
    def search_aliexpress(self, query, limit=20):
        """Scrape AliExpress search results"""
        print(f"🔍 Searching AliExpress for: '{query}'...")
        
        url = f"https://www.aliexpress.com/w/wholesale-{query.replace(' ', '-')}.html"
        soup = self._fetch_page(url)
        
        if not soup:
            return []
        
        # Try multiple selectors for product cards
        items = (soup.select('[data-product-id]') or 
                 soup.select('.product-snippet') or
                 soup.select('.search-card-item') or
                 soup.select('[class*="productContainer"]') or
                 soup.select('.list-item'))
        
        print(f"   Found {len(items)} items")
        
        products = []
        for item in items[:limit]:
            try:
                # Title
                name = (item.select_one('[data-testid="product-title"]') or 
                        item.select_one('.product-snippet-title') or
                        item.select_one('.search-card-item-title') or
                        item.select_one('a[title]'))
                
                if not name:
                    continue
                
                name_text = name.get("title") or name.text.strip()
                if not name_text or len(name_text) < 5:
                    continue
                
                # Price
                price = (item.select_one('[data-testid="product-price"]') or 
                         item.select_one('.product-snippet-price') or
                         item.select_one('.search-card-item-price') or
                         item.select_one('[class*="price"]'))
                
                price_text = price.text.strip() if price else "9.99"
                price_value = self._extract_price(price_text)
                if price_value == 0:
                    price_value = 9.99
                
                # Image
                image = item.select_one("img")
                image_url = image.get("src") if image else ""
                if image_url.startswith("//"):
                    image_url = "https:" + image_url
                
                # Link
                link = item.select_one("a[href*='/item/']") or item.select_one("a")
                href = ""
                if link:
                    href = link.get("href", "")
                    if href.startswith("//"):
                        href = "https:" + href
                    elif href.startswith("/"):
                        href = "https://www.aliexpress.com" + href
                
                products.append({
                    "id": f"ali_{abs(hash(name_text)) % 10000000}",
                    "name": name_text,
                    "price": price_value,
                    "image_url": image_url,
                    "source": "AliExpress",
                    "product_url": href,
                    "rating": 4.0,
                    "description": name_text,
                    "category": "Electronics",
                    "in_stock": True,
                })
            except Exception:
                continue
        
        print(f"   Found {len(products)} AliExpress products")
        return products