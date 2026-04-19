import requests

class ITunesScraper:
    """iTunes API - 100% WORKING, FREE, REAL PRODUCTS"""
    
    def search_products(self, query, max_items=15):
        print(f"\n🎵 FETCHING from iTunes for: '{query}'")
        
        url = "https://itunes.apple.com/search"
        params = {
            "term": query,
            "limit": max_items,
            "media": "all",
            "country": "US"
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            data = response.json()
            
            products = []
            for item in data.get('results', [])[:max_items]:
                name = item.get('trackName', item.get('collectionName', 'Unknown'))
                artist = item.get('artistName', 'Unknown')
                
                # Determine category
                kind = item.get('kind', '')
                if 'song' in kind:
                    category = 'Music'
                elif 'movie' in kind:
                    category = 'Movies'
                elif 'podcast' in kind:
                    category = 'Podcasts'
                else:
                    category = 'Apps'
                
                products.append({
                    'name': name[:255],
                    'price': item.get('trackPrice', item.get('collectionPrice', 0.99)) * 280,
                    'image_url': item.get('artworkUrl100', '').replace('100x100', '600x600'),
                    'platform': 'iTunes',
                    'seller': artist,
                    'category': category,
                    'is_real': True
                })
                print(f"    ✅ {name[:40]}...")
            
            print(f"  📦 TOTAL: {len(products)} items")
            return products
            
        except Exception as e:
            print(f"  ❌ iTunes error: {e}")
            return []
