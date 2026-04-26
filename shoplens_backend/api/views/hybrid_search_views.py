from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser
from api.services.multistore_service import MultiStoreService
from api.services.resnet_service import ResNetService

class HybridImageSearchView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def __init__(self):
        self.multistore_service = MultiStoreService()
        self.resnet_service = ResNetService()
    
    def post(self, request):
        try:
            if 'image' not in request.FILES:
                return Response(
                    {'error': 'No image provided'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            image = request.FILES['image']
            
            # Universal image recognition - recognizes ANY object
            print("📸 Analyzing image with ResNet50...")
            detected = self.resnet_service.analyze_image(image)
            
            search_query = detected[0] if detected else "product"
            print(f"🔍 AI recognized: {search_query}")
            print(f"🔎 Searching stores for: {search_query}")
            
            # Search all stores
            results = self.multistore_service.search_all_stores(search_query, limit=20)
            
            return Response({
                'success': True,
                'products': results.get('products', []),
                'ai_detected': [search_query],
                'search_query': search_query,
                'total': results.get('total', 0),
                'message': f'AI recognized this as: {search_query}'
            })
            
        except Exception as e:
            print(f"❌ Image search error: {e}")
            return Response({'error': str(e)}, status=500)