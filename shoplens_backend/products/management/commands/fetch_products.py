from django.core.management.base import BaseCommand
from products.models import Product, Category, Seller
from products.scrapers.serpapi_scraper import SerpAPIScraper
from products.scrapers.shophive_scraper import ShophiveScraper
from django.utils.text import slugify
import random
import uuid

class Command(BaseCommand):
    help = 'Fetch products from APIs and store in database'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🚀 STARTING PRODUCT FETCH...'))
        
        total_saved = 0
        
        # Get or create default category
        electronics, _ = Category.objects.get_or_create(
            name='Electronics',
            defaults={'description': 'Electronic devices'}
        )
        
        # ============ FETCH FROM WALMART ============
        self.stdout.write('\n📦 Fetching from Walmart...')
        serp = SerpAPIScraper()
        
        walmart_products = serp.search_walmart('laptop', 10)
        walmart_products += serp.search_walmart('tv', 10)
        
        saved = self.save_products(walmart_products, 'Walmart', electronics)
        total_saved += saved
        self.stdout.write(self.style.SUCCESS(f'✅ Saved {saved} Walmart products'))
        
        # ============ FETCH FROM GOOGLE SHOPPING ============
        self.stdout.write('\n📦 Fetching from Google Shopping...')
        google_products = serp.search_google_shopping('electronics', 10)
        
        saved = self.save_products(google_products, 'Google Shopping', electronics)
        total_saved += saved
        self.stdout.write(self.style.SUCCESS(f'✅ Saved {saved} Google products'))
        
        # ============ FETCH FROM SHOPHIVE ============
        self.stdout.write('\n📦 Fetching from Shophive.pk...')
        shophive = ShophiveScraper()
        shophive_products = shophive.search_products('laptop', 15)
        shophive_products += shophive.search_products('mobile', 15)
        
        saved = self.save_products(shophive_products, 'Shophive', electronics)
        total_saved += saved
        self.stdout.write(self.style.SUCCESS(f'✅ Saved {saved} Shophive products'))
        
        # Final summary
        self.stdout.write(self.style.SUCCESS('\n' + '='*60))
        self.stdout.write(self.style.SUCCESS(f'🎉 TOTAL PRODUCTS SAVED: {total_saved}'))
        self.stdout.write(self.style.SUCCESS('='*60))
    
    def save_products(self, products, platform_name, default_category):
        """Save products to database"""
        saved_count = 0
        
        # Get or create seller
        seller, _ = Seller.objects.get_or_create(
            name=platform_name,
            defaults={
                'rating': 4.5,
                'contact_email': f'info@{slugify(platform_name)}.com'
            }
        )
        
        for p in products:
            try:
                # Skip if product is mock or has no name
                if p.get('is_mock', False) or not p.get('name'):
                    continue
                
                name = p['name'][:450]
                sku = f"{platform_name[:3].upper()}-{uuid.uuid4().hex[:8].upper()}"
                price = p.get('price', random.randint(5000, 50000))
                if price <= 0:
                    price = random.randint(5000, 50000)
                
                # Check if product already exists
                if not Product.objects.filter(name=name, seller=seller).exists():
                    Product.objects.create(
                        name=name,
                        description=p.get('description', f'Product from {platform_name}')[:500],
                        price=price,
                        category=default_category,
                        seller=seller,
                        stock_quantity=random.randint(10, 100),
                        image_url=p.get('image_url', '')[:500],
                        sku=sku,
                        is_active=True
                    )
                    saved_count += 1
                    self.stdout.write(f'  ✅ Saved: {name[:50]}...')
                else:
                    self.stdout.write(f'  ⏭️ Already exists: {name[:50]}...')
                    
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'  ❌ Error saving product: {e}'))
                continue
        
        return saved_count
