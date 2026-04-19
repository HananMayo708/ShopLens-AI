from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from api.services.rapidapi_service import RapidAPIProductService

rapidapi_service = RapidAPIProductService()

class HybridImageSearchView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Hybrid search using image"""
        try:
            if 'image' not in request.FILES:
                return Response(
                    {'error': 'No image provided'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get search terms from image (simplified for now)
            search_terms = "product"
            
            # Search RapidAPI
            web_results = rapidapi_service.search_products(search_terms)
            
            return Response({
                'success': True,
                'local_products': [],
                'web_products': web_results.get('products', [])
            })
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
