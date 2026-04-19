# api/views/api_root.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.reverse import reverse

@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request, format=None):
    return Response({
        'message': 'Welcome to ShopLensAI API',
        'version': '1.0.0',
        'endpoints': {
            'auth': {
                'register': reverse('register', request=request, format=format),
                'login': reverse('login', request=request, format=format),
                'logout': reverse('logout', request=request, format=format),
                'profile': reverse('profile', request=request, format=format),
                'token_refresh': reverse('token_refresh', request=request, format=format),
            },
            'products': {
                'categories': reverse('category-list', request=request, format=format),
                'sellers': reverse('seller-list', request=request, format=format),
                'products': reverse('product-list', request=request, format=format),
                'reviews': reverse('review-list', request=request, format=format),
            },
            'admin': reverse('admin:index', request=request, format=format),
        }
    })
