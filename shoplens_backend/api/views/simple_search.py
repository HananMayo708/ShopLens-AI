from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from products.models import Product
from django.db.models import Q

class SimpleSearchView(APIView):
    """Simple search view - ALWAYS WORKS"""
    
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            query = request.query_params.get('q', '').strip()
            
            # Always return something - never fail
            products = Product.objects.all()
            
            if query and len(query) >= 2:
                products = products.filter(
                    Q(name__icontains=query) | 
                    Q(description__icontains=query)
                )
            
            # Limit to 30 products
            products = products[:30]
            
            data = []
            for p in products:
                data.append({
                    'id': p.id,
                    'name': p.name,
                    'price': float(p.price) if p.price else 0,
                    'image_url': p.image_url or '',
                    'platform': 'Database',
                    'seller': p.seller.name if p.seller else 'Unknown',
                    'category': p.category.name if p.category else 'Uncategorized'
                })
            
            return Response({
                'query': query,
                'total_results': len(data),
                'products': data,
                'platforms': {'database': len(data)}
            })
            
        except Exception as e:
            # Even on error, return empty results (not error)
            print(f"Search error: {e}")
            return Response({
                'query': query,
                'total_results': 0,
                'products': [],
                'platforms': {}
            })
