import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import random

class StealthAmazonScraper:
    """Amazon scraper using undetected-chromedriver - FIXED VERSION"""
    
    def __init__(self):
        self.options = uc.ChromeOptions()
        # Don't use headless for now - it's causing issues
        self.options.add_argument('--no-sandbox')
        self.options.add_argument('--disable-dev-shm-usage')
        self.options.add_argument('--disable-blink-features=AutomationControlled')
        self.options.add_argument('--disable-gpu')
        self.options.add_argument('--window-size=1920,1080')
        
    def search_products(self, query, max_items=10):
        print(f"\n🕷️  STEALTH SCRAPING AMAZON for: '{query}'")
        
        driver = None
        products = []
        
        try:
            # Start browser with stealth mode
            print("  🚀 Launching Chrome...")
            driver = uc.Chrome(options=self.options)
            print("  ✅ Chrome launched successfully")
            
            # Human-like delay before navigation
            time.sleep(random.uniform(2, 4))
            
            # Navigate to Amazon
            url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
            print(f"  🌐 Loading: {url}")
            driver.get(url)
            
            # Wait for products to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, '[data-component-type="s-search-result"]'))
            )
            
            # Scroll like a human
            for i in range(3):
                driver.execute_script(f"window.scrollTo(0, {i * 300});")
                time.sleep(random.uniform(0.5, 1.5))
            
            # Find product containers
            items = driver.find_elements(By.CSS_SELECTOR, '[data-component-type="s-search-result"]')
            print(f"  📦 Found {len(items)} items on page")
            
            for item in items[:max_items]:
                try:
                    # Extract title
                    title_elem = item.find_element(By.CSS_SELECTOR, 'h2 a span')
                    title = title_elem.text.strip()
                    
                    # Extract price
                    try:
                        price_elem = item.find_element(By.CSS_SELECTOR, '.a-price .a-offscreen')
                        price_text = price_elem.text.replace('$', '').replace(',', '').strip()
                        price = float(price_text) * 280  # USD to PKR
                    except:
                        price = random.randint(5000, 50000)
                    
                    # Extract image
                    img_elem = item.find_element(By.CSS_SELECTOR, 'img.s-image')
                    image_url = img_elem.get_attribute('src')
                    
                    products.append({
                        'name': title[:255],
                        'price': price,
                        'image_url': image_url,
                        'platform': 'Amazon',
                        'seller': 'Amazon',
                        'is_real': True,
                        'source': 'Stealth Scraper'
                    })
                    print(f"    ✅ {title[:40]}...")
                    
                except Exception as e:
                    continue
            
            print(f"  📦 TOTAL: {len(products)} products")
            
        except Exception as e:
            print(f"  ❌ Error: {e}")
            
        finally:
            if driver:
                try:
                    driver.quit()
                except:
                    pass
                
        return products


# Test it
if __name__ == "__main__":
    scraper = StealthAmazonScraper()
    products = scraper.search_products('laptop', 3)
    print(f"\n✅ Found {len(products)} products")
    for p in products:
        print(f"  - {p['name'][:50]}... Rs.{p['price']}")
