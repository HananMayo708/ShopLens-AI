import undetected_chromedriver as uc
import time

print("="*60)
print("🕷️  TESTING UNDETECTED-CHROMEDRIVER")
print("="*60)

try:
    # Try without any options first
    print("🚀 Launching Chrome (visible mode)...")
    driver = uc.Chrome()
    print("✅ Chrome started successfully!")
    
    # Navigate to Google
    print("🌐 Navigating to Google...")
    driver.get('https://www.google.com')
    time.sleep(2)
    
    print(f"📄 Page title: {driver.title}")
    print("✅ Test successful!")
    
    input("Press Enter to close browser...")
    driver.quit()
    
except Exception as e:
    print(f"❌ Error: {e}")

print("="*60)
