from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from ..services.multi_store_service import MultiStoreService

class MultiStoreSearchView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '')
        limit = int(request.query_params.get('limit', 20))
        
        if not query:
            return Response({'error': 'No search query'}, status=400)
        
        service = MultiStoreService()
        # IMPORTANT: save_to_db=True to save products to PostgreSQL
        results = service.search_all_stores(query, limit, save_to_db=True)
        
        return Response({
            'success': True,
            'products': results['products'],
            'total': results['total'],
            'source': 'Multi-Store (Amazon, eBay, Walmart, Daraz, AliExpress)'
        })