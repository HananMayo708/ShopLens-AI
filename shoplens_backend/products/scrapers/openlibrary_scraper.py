import requests

class OpenLibraryScraper:
    def search_products(self, query, max_items=10):
        print(f"\n📚 FETCHING from OpenLibrary for: '{query}'")
        url = "https://openlibrary.org/search.json"
        params = {"q": query, "limit": max_items}
        response = requests.get(url, params=params)
        data = response.json()
        
        products = []
        for doc in data.get('docs', [])[:max_items]:
            title = doc.get('title', 'Unknown')
            cover_id = doc.get('cover_i')
            if cover_id:
                image_url = f"https://covers.openlibrary.org/b/id/{cover_id}-L.jpg"
            else:
                image_url = "https://openlibrary.org/static/images/ol-logo.png"
            
            products.append({
                'name': title[:255],
                'price': 0.0,
                'image_url': image_url,
                'platform': 'OpenLibrary',
                'seller': 'OpenLibrary',
                'is_real': True
            })
            print(f"    ✅ {title[:40]}...")
        
        print(f"  📦 TOTAL: {len(products)} books")
        return products
