from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from ..services.serpapi_service import SerpAPIService

class SerpAPISearchView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        query = request.query_params.get('q', '')
        limit = request.query_params.get('limit', 20)
        
        if not query:
            return Response(
                {'error': 'No search query provided'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            limit = int(limit)
            limit = min(limit, 50)  # Max 50 results
        except ValueError:
            limit = 20
        
        service = SerpAPIService()
        results = service.search_shopping_products(query, limit)
        
        if results['success']:
            return Response(results, status=status.HTTP_200_OK)
        else:
            return Response(
                {'error': results.get('error', 'Search failed')}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
