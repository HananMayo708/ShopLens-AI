import logging

from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.services.rapidapi_service import RapidAPIProductService

logger = logging.getLogger(__name__)

# Single shared service instance
rapidapi_service = RapidAPIProductService()


@api_view(["GET"])
def rapidapi_search(request):
    """
    Search products directly from RapidAPI.
    Endpoint: GET /api/rapidapi/search/?q=<query>&limit=<limit>
    """
    query = request.query_params.get("q", "").strip()
    if not query:
        return Response(
            {"error": "Search query is required", "products": []},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        limit = int(request.query_params.get("limit", 20))
    except ValueError:
        limit = 20

    try:
        print(f"🔍 Searching RapidAPI for: {query}")
        results = rapidapi_service.search_products(query, limit=limit)

        if "error" in results:
            print(f"❌ API Error: {results['error']}")
            return Response(
                {"error": results["error"], "products": []},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        results.setdefault("products", [])
        print(f"✅ Found {len(results['products'])} products")
        return Response(results)

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        logger.error(f"RapidAPI search error: {str(e)}")
        return Response(
            {"error": str(e), "products": []},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["GET"])
def rapidapi_trending(request):
    """
    Get trending products from RapidAPI.
    Endpoint: GET /api/rapidapi/trending/
    """
    try:
        print("🔥 Getting trending products")
        trending = rapidapi_service.get_trending_products()
        return Response({"trending": trending})

    except Exception as e:
        print(f"❌ Trending error: {e}")
        logger.error(f"RapidAPI trending error: {str(e)}")
        return Response(
            {"error": str(e), "trending": []},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["GET"])
def get_product_details(request, product_id):
    """
    Get product details by ID.
    Endpoint: GET /api/product/<product_id>/
    """
    try:
        print(f"📦 Getting details for product: {product_id}")
        product = rapidapi_service.get_product_details(product_id)
        if product:
            return Response(product)
        return Response(
            {"error": "Product not found"},
            status=status.HTTP_404_NOT_FOUND,
        )

    except Exception as e:
        print(f"❌ Product details error: {e}")
        logger.error(f"Product details error: {str(e)}")
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


# Backward-compatible alias
@api_view(["GET"])
def search_products(request):
    """Alias for rapidapi_search (backward compatibility)."""
    return rapidapi_search(request)