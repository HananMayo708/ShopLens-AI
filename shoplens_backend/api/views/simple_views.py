from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from products.models import Product

class SimpleProductView(APIView):
    """Ultra simple product view - NO ERRORS"""
    permission_classes = [AllowAny]
    
    def get(self, request):
        try:
            products = Product.objects.all()[:10]
            data = []
            for p in products:
                data.append({
                    'id': p.id,
                    'name': p.name,
                    'price': str(p.price),
                    'image_url': p.image_url or '',
                })
            return Response({'products': data, 'count': len(data)})
        except Exception as e:
            return Response({'error': str(e)}, status=500)
