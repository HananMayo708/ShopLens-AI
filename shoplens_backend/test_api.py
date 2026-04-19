#!/usr/bin/env python
import os
import django
import requests
import json

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'shoplens_ai.settings')
django.setup()

from products.models import Product
from django.conf import settings

print("\n🔍 Testing RapidAPI connection...")

headers = {
    'X-RapidAPI-Key': 'f159ac9541msh4c17db8373dcb7cp157fc4jsn7e395f4bdd16',
    'X-RapidAPI-Host': 'real-time-product-search.p.rapidapi.com'
}

categories = ['laptop', 'smartphone', 'headphones', 'camera', 'gaming']
total_products = 0

for category in categories:
    print(f"\n📡 Fetching {category}...")
    try:
        response = requests.get(
            'https://real-time-product-search.p.rapidapi.com/search-v2',
            headers=headers,
            params={
                'q': category,
                'country': 'us',
                'language': 'en',
                'limit': 5
            },
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            products = data.get('data', [])
            print(f"✅ Found {len(products)} products for {category}")
            total_products += len(products)
            
            # Print sample product
            if products:
                p = products[0]
                print(f"   Sample: {p.get('product_title', 'N/A')[:50]}")
                print(f"   Price: {p.get('product_price', 'N/A')}")
                print(f"   Store: {p.get('product_source', 'N/A')}")
        else:
            print(f"❌ Error {response.status_code}: {response.text[:100]}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

print(f"\n{'='*50}")
print(f"✅ TOTAL PRODUCTS FOUND: {total_products}")
print(f"{'='*50}")
print("\n💡 To save these to database, you need to implement Product model saving")
