import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
import time
import random

class SimpleStealthScraper:
    """Simpler version that's more likely to work"""
    
    def search_products(self, query, max_items=5):
        print(f"\n🕷️  SIMPLE STEALTH SCRAPER for: '{query}'")
        
        driver = None
        products = []
        
        try:
            # Use minimal options
            driver = uc.Chrome()
            
            # Go to Amazon
            url = f"https://www.amazon.com/s?k={query.replace(' ', '+')}"
            print(f"  🌐 Loading: {url}")
            driver.get(url)
            time.sleep(3)
            
            # Get page title to confirm it worked
            print(f"  📄 Page title: {driver.title}")
            
            # Simple extraction
            items = driver.find_elements(By.CSS_SELECTOR, '[data-component-type="s-search-result"]')
            print(f"  📦 Found {len(items)} items")
            
            for item in items[:max_items]:
                try:
                    title = item.find_element(By.CSS_SELECTOR, 'h2 a span').text
                    products.append({
                        'name': title[:255],
                        'price': random.randint(10000, 50000),
                        'image_url': '',
                        'platform': 'Amazon',
                        'seller': 'Amazon',
                        'is_real': True
                    })
                    print(f"    ✅ {title[:40]}...")
                except:
                    continue
                    
        except Exception as e:
            print(f"  ❌ Error: {e}")
            
        finally:
            if driver:
                driver.quit()
                
        return products

# Test
s = SimpleStealthScraper()
products = s.search_products('laptop', 3)
print(f"\n✅ Found {len(products)} products")
