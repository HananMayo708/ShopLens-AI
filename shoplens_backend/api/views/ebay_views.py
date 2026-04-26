from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from ..services.ebay_service import EbayProductService

class EbaySearchView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '')
        limit = int(request.query_params.get('limit', 20))
        
        if not query:
            return Response({'error': 'No search query'}, status=400)
        
        service = EbayProductService()
        products = service.search_products(query, limit)
        
        return Response({
            'success': True,
            'products': products,
            'total': len(products),
            'source': 'eBay'
        })
