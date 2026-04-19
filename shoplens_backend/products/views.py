from rest_framework.decorators import api_view
from rest_framework.response import Response

@api_view(['POST'])
def compare_prices(request):
    """
    Dummy price comparison API.
    In a real project, this would compare product prices from online stores.
    """
    product_name = request.data.get("product_name", "Unknown Product")

    # Example dummy data
    prices = {
        "Amazon": 15.99,
        "eBay": 14.49,
        "Walmart": 16.10
    }
    

    return Response({
        "product": product_name,
        "prices": prices,
        "best_price": min(prices.values())
    })
