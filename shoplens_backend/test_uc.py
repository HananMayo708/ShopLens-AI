import undetected_chromedriver as uc
import time

print("="*60)
print("🕷️  TESTING UNDETECTED-CHROMEDRIVER")
print("="*60)

try:
    # Try to start Chrome
    print("🚀 Launching Chrome in headless mode...")
    options = uc.ChromeOptions()
    options.add_argument('--headless=new')
    
    driver = uc.Chrome(options=options)
    print("✅ Chrome started successfully!")
    
    # Navigate to Google
    print("🌐 Navigating to Google...")
    driver.get('https://www.google.com')
    time.sleep(2)
    
    print(f"📄 Page title: {driver.title}")
    print("✅ Test successful!")
    
    driver.quit()
    
except Exception as e:
    print(f"❌ Error: {e}")

print("="*60)
