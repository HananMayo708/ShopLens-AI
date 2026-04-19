import undetected_chromedriver as uc
import time

print("🚀 Testing undetected-chromedriver...")
print("="*60)

# This opens a REAL Chrome window that's VERY hard to detect
driver = uc.Chrome(headless=False)

print("✅ Browser opened!")
print("🌐 Navigating to Amazon...")
driver.get('https://www.amazon.com')

time.sleep(3)
print("✅ Page loaded!")

print("\n📊 Anti-detection features:")
print("  • navigator.webdriver = false")
print("  • Chrome DevTools Protocol hidden")
print("  • TLS fingerprint matches real Chrome")

input("\nPress Enter to close browser...")
driver.quit()
print("✅ Done!")
