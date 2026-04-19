import numpy as np
from scipy.spatial.distance import cosine
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from products.models import Product, ProductFeature
from api.services.resnet_service import ResNetFeatureExtractor

class ResNetImageSearchView(APIView):
    """
    Search for visually similar products using ResNet50 features
    """
    parser_classes = (MultiPartParser, FormParser)
    
    def __init__(self):
        self.feature_extractor = ResNetFeatureExtractor()
    
    def post(self, request):
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'No image provided'}, status=400)
        
        try:
            # Step 1: Extract features from query image
            query_features = self.feature_extractor.extract_features(image_file.read())
            
            if query_features is None:
                return Response({'error': 'Feature extraction failed'}, status=500)
            
            # Step 2: Compare with all products in database
            results = []
            for product_feature in ProductFeature.objects.select_related('product').all():
                # Calculate cosine similarity (1 - cosine distance) [citation:3]
                db_features = product_feature.get_vector()
                similarity = 1 - cosine(query_features, db_features)
                
                results.append({
                    'product': {
                        'id': product_feature.product.id,
                        'name': product_feature.product.name,
                        'price': product_feature.product.price,
                        'imageUrl': product_feature.product.imageUrl,
                        'source': product_feature.product.source,
                    },
                    'similarity': float(similarity)
                })
            
            # Step 3: Sort by similarity (highest first)
            results.sort(key=lambda x: x['similarity'], reverse=True)
            
            # Return top 10 most similar [citation:6]
            top_results = results[:10]
            
            return Response({
                'success': True,
                'method': 'ResNet50 Feature Matching',
                'results': top_results
            })
            
        except Exception as e:
            return Response({'error': str(e)}, status=500)