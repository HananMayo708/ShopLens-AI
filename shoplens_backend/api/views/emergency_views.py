from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from products.models import Product

class EmergencyProductView(APIView):
    """Emergency product view - NO AUTH REQUIRED"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            products = Product.objects.all()[:20]
            data = []
            for p in products:
                data.append({
                    'id': p.id,
                    'name': p.name,
                    'price': str(p.price),
                    'image_url': p.image_url or '',
                })
            return Response({
                'status': 'success',
                'count': len(data),
                'products': data
            })
        except Exception as e:
            return Response({
                'status': 'error',
                'error': str(e)
            }, status=500)
