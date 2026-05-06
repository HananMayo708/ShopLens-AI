import numpy as np
from scipy.spatial.distance import cosine
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from products.models import Product, ProductFeature
from api.services.resnet_service import ResNetFeatureExtractor


class ResNetImageSearchView(APIView):
    """
    Search for visually similar products using ResNet50 features
    """
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def __init__(self):
        self.feature_extractor = ResNetFeatureExtractor()

    def post(self, request):
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'No image provided'}, status=400)

        try:
            # Step 1: Extract features from query image
            print("🔍 Extracting features from uploaded image...")
            query_features = self.feature_extractor.extract_features(image_file)

            if query_features is None:
                return Response({'error': 'Feature extraction failed'}, status=500)

            # Step 2: Compare with all products in database
            print("📊 Comparing with database products...")
            results = []
            
            for product_feature in ProductFeature.objects.select_related('product', 'product__seller').all():
                # Get stored feature vector
                db_features = np.array(product_feature.feature_vector)
                
                # Calculate cosine similarity (1 - cosine distance)
                similarity = 1 - cosine(query_features, db_features)
                
                # Get product details
                product = product_feature.product
                
                results.append({
                    'product': {
                        'id': product.id,
                        'name': product.name,
                        'price': float(product.price),
                        'imageUrl': product.image_url,
                        'source': product.seller.name if product.seller else 'Unknown',
                        'product_url': getattr(product, 'product_url', ''),
                        'rating': float(product.average_rating) if product.average_rating else 0,
                        'in_stock': product.stock_quantity > 0 if hasattr(product, 'stock_quantity') else True,
                    },
                    'similarity_score': round(float(similarity), 4)
                })

            # Step 3: Sort by similarity (highest first)
            results.sort(key=lambda x: x['similarity_score'], reverse=True)

            # Return top 20 most similar
            top_results = results[:20]

            print(f"✅ Found {len(top_results)} similar products")

            return Response({
                'success': True,
                'method': 'ResNet50 Feature Extraction + Cosine Similarity',
                'total_matches': len(results),
                'results': top_results
            })

        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': str(e)}, status=500)


class ExtractAndSearchView(APIView):
    """
    Extract features from image and search - with product recognition
    """
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser)

    def __init__(self):
        self.feature_extractor = ResNetFeatureExtractor()

    def post(self, request):
        image_file = request.FILES.get('image')
        
        if not image_file:
            return Response({'error': 'No image provided'}, status=400)

        try:
            # Step 1: Recognize what's in the image
            print("🔍 Recognizing image content...")
            search_term = self.feature_extractor.recognize_image(image_file)
            print(f"   Detected: {search_term}")
            
            # Step 2: Extract features (if needed for similarity)
            image_file.seek(0)  # Reset file pointer
            features = self.feature_extractor.extract_features(image_file)
            
            # Step 3: Search products by the detected term
            from api.services.multi_store_service import MultiStoreService
            store_service = MultiStoreService()
            limit = int(request.POST.get('limit', 30))
            
            results = store_service.search_all_stores(search_term, limit, save_to_db=False)
            
            return Response({
                'success': True,
                'detected_product': search_term,
                'features_extracted': features is not None,
                'feature_dimension': len(features) if features else 0,
                'products': results['products'],
                'total': results['total']
            })
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': str(e)}, status=500)


class IndexProductFeaturesView(APIView):
    """
    ADMIN ONLY: Index all existing products with feature vectors
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Check if user is admin
        if not request.user.is_staff:
            return Response({'error': 'Admin only. Staff privileges required.'}, status=403)

        try:
            from api.services.resnet_service import ResNetFeatureExtractor
            from products.models import Product, ProductFeature
            import requests
            from PIL import Image
            from io import BytesIO
            
            feature_extractor = ResNetFeatureExtractor()
            
            # Get products with images
            products = Product.objects.filter(
                image_url__isnull=False, 
                image_url__gt=''
            )
            
            total_products = products.count()
            print(f"📦 Total products to index: {total_products}")
            
            indexed_count = 0
            failed_count = 0
            skipped_count = 0
            
            for product in products:
                # Skip if already indexed and not forcing reindex
                if ProductFeature.objects.filter(product=product).exists():
                    skipped_count += 1
                    continue
                    
                try:
                    print(f"🔄 Indexing: {product.name[:50]}...")
                    
                    # Download image from URL
                    response = requests.get(product.image_url, timeout=30)
                    img = Image.open(BytesIO(response.content))
                    
                    # Convert to RGB if needed
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    
                    # Save to bytes
                    img_bytes = BytesIO()
                    img.save(img_bytes, format='JPEG')
                    img_bytes.seek(0)
                    
                    # Extract features
                    features = feature_extractor.extract_features(img_bytes)
                    
                    if features is not None:
                        # Save feature record
                        ProductFeature.objects.create(
                            product=product,
                            feature_vector=features,
                            model_version='resnet50_imagenet'
                        )
                        indexed_count += 1
                        print(f"   ✅ Indexed (total: {indexed_count})")
                    else:
                        failed_count += 1
                        print(f"   ❌ Feature extraction failed")
                        
                except requests.exceptions.Timeout:
                    failed_count += 1
                    print(f"   ❌ Timeout downloading image")
                except Exception as e:
                    failed_count += 1
                    print(f"   ❌ Error: {str(e)[:100]}")
            
            return Response({
                'success': True,
                'total_products': total_products,
                'indexed': indexed_count,
                'skipped': skipped_count,
                'failed': failed_count,
                'message': f"Indexed {indexed_count} products. {failed_count} failed. {skipped_count} already indexed."
            })
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({'error': str(e)}, status=500)


class ReindexAllFeaturesView(APIView):
    """
    ADMIN ONLY: Force reindex all products (overwrite existing features)
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # Check if user is admin
        if not request.user.is_staff:
            return Response({'error': 'Admin only. Staff privileges required.'}, status=403)

        try:
            from api.services.resnet_service import ResNetFeatureExtractor
            from products.models import Product, ProductFeature
            import requests
            from PIL import Image
            from io import BytesIO
            
            feature_extractor = ResNetFeatureExtractor()
            
            # Delete all existing features
            deleted_count = ProductFeature.objects.all().delete()
            print(f"🗑️ Deleted {deleted_count[0]} existing feature records")
            
            # Get products with images
            products = Product.objects.filter(
                image_url__isnull=False, 
                image_url__gt=''
            )
            
            total_products = products.count()
            print(f"📦 Total products to index: {total_products}")
            
            indexed_count = 0
            failed_count = 0
            
            for product in products:
                try:
                    print(f"🔄 Indexing: {product.name[:50]}...")
                    
                    # Download image
                    response = requests.get(product.image_url, timeout=30)
                    img = Image.open(BytesIO(response.content))
                    
                    if img.mode != 'RGB':
                        img = img.convert('RGB')
                    
                    img_bytes = BytesIO()
                    img.save(img_bytes, format='JPEG')
                    img_bytes.seek(0)
                    
                    features = feature_extractor.extract_features(img_bytes)
                    
                    if features is not None:
                        ProductFeature.objects.create(
                            product=product,
                            feature_vector=features,
                            model_version='resnet50_imagenet'
                        )
                        indexed_count += 1
                        print(f"   ✅ Indexed ({indexed_count}/{total_products})")
                    else:
                        failed_count += 1
                        print(f"   ❌ Feature extraction failed")
                        
                except Exception as e:
                    failed_count += 1
                    print(f"   ❌ Error: {str(e)[:100]}")
            
            return Response({
                'success': True,
                'total_products': total_products,
                'indexed': indexed_count,
                'failed': failed_count,
                'message': f"Reindex complete! {indexed_count} indexed, {failed_count} failed."
            })
            
        except Exception as e:
            return Response({'error': str(e)}, status=500)


class GetProductFeaturesView(APIView):
    """
    Get feature vector for a specific product
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, product_id):
        try:
            product = Product.objects.get(id=product_id)
            feature = ProductFeature.objects.filter(product=product).first()
            
            if feature:
                return Response({
                    'success': True,
                    'product_id': product.id,
                    'product_name': product.name,
                    'has_features': True,
                    'feature_dimension': len(feature.feature_vector),
                    'model_version': feature.model_version,
                    'created_at': feature.created_at
                })
            else:
                return Response({
                    'success': True,
                    'product_id': product.id,
                    'product_name': product.name,
                    'has_features': False,
                    'message': 'No features indexed for this product yet.'
                })
                
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=404)
        except Exception as e:
            return Response({'error': str(e)}, status=500)