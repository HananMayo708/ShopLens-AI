import logging
from celery import shared_task
import requests
from django.conf import settings
import time

logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=5)
def fetch_products_from_rapidapi(self, query, country='us', language='en', limit=20):
    """
    Celery task to fetch products from RapidAPI asynchronously
    """
    try:
        url = "https://real-time-product-search.p.rapidapi.com/search-v2"
        
        headers = {
            "X-RapidAPI-Key": settings.RAPIDAPI_KEY,
            "X-RapidAPI-Host": settings.RAPIDAPI_HOST
        }
        
        params = {
            "q": query,
            "country": country,
            "language": language,
            "limit": limit,
            "page": 1,
            "sort_by": "BEST_MATCH"
        }
        
        logger.info(f"Fetching products for query: {query} using v2 endpoint")
        
        # Increase timeout to 60 seconds for slow API
        response = requests.get(url, headers=headers, params=params, timeout=60)
        
        if response.status_code == 401:
            logger.error(f"RapidAPI authentication failed - status 401")
            return {
                'success': False,
                'error': 'Authentication failed. Check your API key.',
                'status_code': 401
            }
        
        response.raise_for_status()
        data = response.json()
        
        # Process products
        products = []
        if data.get('data') and data['data'].get('products'):
            product_list = data['data']['products']
            logger.info(f"Found {len(product_list)} raw products")
            
            for item in product_list:
                product = _extract_product(item)
                if product:
                    products.append(product)
        
        logger.info(f"Successfully fetched {len(products)} products for '{query}'")
        return {
            'success': True,
            'query': query,
            'count': len(products),
            'products': products
        }
        
    except requests.exceptions.Timeout:
        logger.error(f"RapidAPI timeout for query: {query}")
        # Retry with longer timeout
        self.retry(countdown=5, max_retries=3)
        return {
            'success': False,
            'error': 'Request timeout',
            'query': query
        }
        
    except requests.exceptions.RequestException as e:
        logger.error(f"RapidAPI request failed: {str(e)}")
        if hasattr(e, 'response') and e.response is not None:
            logger.error(f"Response status: {e.response.status_code}")
            return {
                'success': False,
                'error': f"API error: {e.response.status_code}",
                'status_code': e.response.status_code
            }
        self.retry(countdown=10, max_retries=3)
        return {
            'success': False,
            'error': str(e)
        }
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }


def _extract_product(item):
    """Helper function to extract product data"""
    try:
        if not item:
            return None
        
        # Extract price safely
        price = 0.0
        if item.get('offer'):
            price_str = item['offer'].get('price', '0')
            if isinstance(price_str, (int, float)):
                price = float(price_str)
            else:
                try:
                    # Remove currency symbols and convert
                    price = float(str(price_str).replace('$', '').replace(',', '').replace('£', '').replace('€', ''))
                except:
                    price = 0.0
        
        # Get source/store name
        source = 'Unknown'
        if item.get('offer') and item['offer'].get('store_name'):
            source = item['offer']['store_name']
        
        # Get image URL
        image_url = ''
        if item.get('product_photos') and len(item['product_photos']) > 0:
            image_url = item['product_photos'][0]
        
        # Get brand
        brand = item.get('brand', '')
        if not brand and item.get('product_attributes'):
            brand = item['product_attributes'].get('Brand', '')
        
        return {
            'id': item.get('product_id', ''),
            'name': item.get('product_title', 'Unknown Product'),
            'price': price,
            'brand': brand,
            'imageUrl': image_url,
            'rating': item.get('product_rating'),
            'reviewCount': item.get('product_num_reviews', 0),
            'source': source,
            'product_url': item.get('product_page_url', '')
        }
    except Exception as e:
        logger.error(f"Error extracting product: {e}")
        return None


@shared_task
def fetch_product_details(product_id, country='us', language='en'):
    """
    Celery task to fetch product details
    """
    try:
        url = "https://real-time-product-search.p.rapidapi.com/product-details"
        
        headers = {
            "X-RapidAPI-Key": settings.RAPIDAPI_KEY,
            "X-RapidAPI-Host": settings.RAPIDAPI_HOST
        }
        
        params = {
            "product_id": product_id,
            "country": country,
            "language": language
        }
        
        response = requests.get(url, headers=headers, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get('data'):
            product_data = data['data']
            
            # Extract price
            price = 0.0
            if product_data.get('price'):
                price_data = product_data['price']
                if isinstance(price_data, dict):
                    price = price_data.get('value', 0)
                else:
                    try:
                        price = float(str(price_data).replace('$', '').replace(',', ''))
                    except:
                        price = 0.0
            
            details = {
                'id': product_id,
                'name': product_data.get('title', ''),
                'description': product_data.get('description', ''),
                'price': price,
                'brand': product_data.get('brand', ''),
                'imageUrl': product_data.get('images', [{}])[0].get('link', '') if product_data.get('images') else '',
                'images': [img.get('link') for img in product_data.get('images', [])],
                'rating': product_data.get('rating', {}).get('value'),
                'reviewCount': product_data.get('rating', {}).get('count', 0),
                'inStock': product_data.get('availability', {}).get('inStock', True),
                'source': product_data.get('source', '')
            }
            
            return {
                'success': True,
                'data': details
            }
        
        return {
            'success': False,
            'error': 'Product not found'
        }
        
    except Exception as e:
        logger.error(f"Error fetching product details: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }
