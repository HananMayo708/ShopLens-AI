#!/usr/bin/env python
import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shoplens_ai.settings')
django.setup()

from products.models import Product

count = Product.objects.count()
print(f"\n{'='*50}")
print(f"📊 TOTAL PRODUCTS IN DATABASE: {count}")
print(f"{'='*50}")

if count > 0:
    print("\n📦 SAMPLE PRODUCTS:")
    print(f"{'-'*50}")
    for i, p in enumerate(Product.objects.all()[:10]):
        print(f"{i+1}. {p.name[:50]}...")
        print(f"   💰 Price: ")
        print(f"   🏪 Source: {p.source}")
        print(f"   🖼️ Image: {p.image_url[:50] if p.image_url else 'No image'}...")
        print(f"{'-'*50}")
    
    # Count by source
    print("\n🏪 PRODUCTS BY STORE:")
    sources = Product.objects.values('source').distinct()
    for s in sources:
        if s['source']:
            cnt = Product.objects.filter(source=s['source']).count()
            print(f"   {s['source']}: {cnt} products")
else:
    print("\n❌ No products found in database!")
    print("\n💡 TIP: Run a search first to populate products")
