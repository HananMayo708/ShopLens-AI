import requests
from django.conf import settings
import logging
from typing import Dict, List, Optional
from django.core.cache import cache
import time

logger = logging.getLogger(__name__)


class RapidAPIProductService:
    """
    Service class to interact with Real-Time Product Search API on RapidAPI.
    Uses correct v2 endpoints with improved error handling.
    """

    def __init__(self):
        self.api_key = settings.RAPIDAPI_KEY
        self.api_host = settings.RAPIDAPI_HOST
        self.base_url = f"https://{self.api_host}"
        self.headers = {
            "X-RapidAPI-Key": self.api_key,
            "X-RapidAPI-Host": self.api_host,
            "Content-Type": "application/json",
        }

    def search_products(self, query: str, page: int = 1, limit: int = 20) -> Dict:
        """
        Search for products using the Real-Time Product Search API v2.
        Results are cached for 1 hour.
        """
        cache_key = f"rapidapi_search_{query.replace(' ', '_')}_{page}_{limit}"
        cached_result = cache.get(cache_key)

        if cached_result:
            print(f"🔄 Returning cached result for '{query}'")
            return cached_result

        try:
            endpoint = f"{self.base_url}/search-v2"
            params = {
                "q": query,
                "country": "us",
                "language": "en",
                "page": page,
                "limit": limit,
                "sort_by": "BEST_MATCH",
            }

            print(f"🔍 Calling RapidAPI: {endpoint}")
            print(f"📊 Params: {params}")

            response = requests.get(
                endpoint,
                headers=self.headers,
                params=params,
                timeout=30,
            )

            print(f"📥 Response status: {response.status_code}")

            if response.status_code != 200:
                print(f"❌ Error response: {response.text}")
                
                # Handle rate limiting
                if response.status_code == 429:
                    retry_after = int(response.headers.get('Retry-After', 60))
                    print(f"⏳ Rate limited. Waiting {retry_after} seconds...")
                    time.sleep(retry_after)
                    return self.search_products(query, page, limit)  # Retry
                
                response.raise_for_status()

            result = response.json()
            
            # Extract products based on API response structure
            if "data" in result:
                if isinstance(result["data"], dict):
                    products = result["data"].get("products", [])
                elif isinstance(result["data"], list):
                    products = result["data"]
                else:
                    products = []
            else:
                products = result.get("products", [])
            
            print(f"✅ Found {len(products)} products")

            transformed_result = {
                "products": products,
                "status": result.get("status", "success"),
                "request_id": result.get("request_id", ""),
                "query": query,
            }

            cache.set(cache_key, transformed_result, 3600)  # Cache for 1 hour
            return transformed_result

        except requests.exceptions.HTTPError as e:
            logger.error(f"RapidAPI HTTP error: {str(e)}")
            error_detail = str(e)
            if hasattr(e, "response") and e.response is not None:
                error_detail = f"{str(e)} - {e.response.text}"
            return {"error": error_detail, "products": [], "query": query}

        except requests.exceptions.Timeout:
            logger.error("RapidAPI request timed out")
            return {"error": "Request timed out", "products": [], "query": query}

        except requests.exceptions.RequestException as e:
            logger.error(f"RapidAPI request failed: {str(e)}")
            return {"error": str(e), "products": [], "query": query}

    def get_product_details(self, product_id: str) -> Optional[Dict]:
        """
        Get detailed information about a specific product.
        Results are cached for 24 hours.
        """
        cache_key = f"rapidapi_product_{product_id}"
        cached_result = cache.get(cache_key)

        if cached_result:
            return cached_result

        try:
            endpoint = f"{self.base_url}/product-details"
            params = {
                "product_id": product_id,
                "country": "us",
                "language": "en",
            }

            print(f"📦 Getting details for product: {product_id}")

            response = requests.get(
                endpoint,
                headers=self.headers,
                params=params,
                timeout=30,
            )
            
            if response.status_code != 200:
                print(f"❌ Error fetching product details: {response.status_code}")
                return None
                
            response.raise_for_status()

            result = response.json()
            cache.set(cache_key, result, 86400)  # Cache for 24 hours
            return result

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch product details: {str(e)}")
            return None

    def get_trending_products(self) -> List[Dict]:
        """
        Get trending products by searching popular keywords.
        Results are cached for 6 hours.
        """
        cache_key = "rapidapi_trending"
        cached_result = cache.get(cache_key)

        if cached_result:
            print("🔄 Returning cached trending products")
            return cached_result

        trending_keywords = ["trending", "popular", "bestseller", "top rated"]
        all_products = []
        seen_ids = set()

        try:
            for keyword in trending_keywords[:2]:  # Try first 2 keywords
                if len(all_products) >= 30:
                    break
                    
                print(f"🔥 Getting trending products for: {keyword}")
                
                endpoint = f"{self.base_url}/search-v2"
                params = {
                    "q": keyword,
                    "country": "us",
                    "language": "en",
                    "limit": 20,
                    "sort_by": "BEST_MATCH",
                }

                response = requests.get(
                    endpoint,
                    headers=self.headers,
                    params=params,
                    timeout=30,
                )
                
                if response.status_code == 200:
                    result = response.json()
                    
                    if "data" in result:
                        if isinstance(result["data"], dict):
                            products = result["data"].get("products", [])
                        elif isinstance(result["data"], list):
                            products = result["data"]
                        else:
                            products = []
                    else:
                        products = result.get("products", [])
                    
                    for p in products:
                        product_id = p.get('product_id', '')
                        if product_id and product_id not in seen_ids:
                            seen_ids.add(product_id)
                            all_products.append(p)
                    
                    print(f"✅ Found {len(products)} products for '{keyword}', total unique: {len(all_products)}")

            print(f"✅ Total trending products: {len(all_products)}")
            cache.set(cache_key, all_products, 21600)  # Cache for 6 hours
            return all_products

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to fetch trending products: {str(e)}")
            return []

    def search_by_image(self, image_url: str) -> List[Dict]:
        """
        Search products by image URL (visual search).
        """
        try:
            endpoint = f"{self.base_url}/image-search"
            params = {
                "image_url": image_url,
                "country": "us",
                "language": "en",
            }

            print(f"🖼️ Searching by image: {image_url}")

            response = requests.get(
                endpoint,
                headers=self.headers,
                params=params,
                timeout=30,
            )
            
            if response.status_code != 200:
                print(f"❌ Image search failed: {response.status_code}")
                return []
                
            response.raise_for_status()

            result = response.json()
            
            # Parse response based on structure
            if "data" in result:
                if isinstance(result["data"], dict):
                    products = result["data"].get("products", [])
                elif isinstance(result["data"], list):
                    products = result["data"]
                else:
                    products = []
            else:
                products = result.get("products", [])
                
            print(f"✅ Found {len(products)} products by image search")
            return products

        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to search by image: {str(e)}")
            return []