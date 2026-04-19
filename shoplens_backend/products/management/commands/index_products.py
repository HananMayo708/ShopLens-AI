import requests
from io import BytesIO
from django.core.management.base import BaseCommand
from products.models import Product, ProductFeature
from api.services.resnet_service import ResNetFeatureExtractor
from PIL import Image
import numpy as np

class Command(BaseCommand):
    help = 'Index all products by extracting ResNet50 features'
    
    def __init__(self):
        super().__init__()
        self.extractor = ResNetFeatureExtractor()
    
    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, help='Limit number of products to index')
    
    def handle(self, *args, **options):
        limit = options.get('limit')
        products = Product.objects.all()
        
        if limit:
            products = products[:limit]
        
        self.stdout.write(f"📊 Found {products.count()} products to index")
        
        indexed = 0
        skipped = 0
        failed = 0
        
        for product in products:
            if ProductFeature.objects.filter(product=product).exists():
                skipped += 1
                continue
            
            try:
                self.stdout.write(f"🔄 Indexing: {product.name[:50]}...")
                
                if not product.imageUrl:
                    self.stdout.write(f"⚠️ No image URL for product {product.id}")
                    failed += 1
                    continue
                
                response = requests.get(product.imageUrl, timeout=10)
                if response.status_code != 200:
                    failed += 1
                    continue
                
                features = self.extractor.extract_features(response.content)
                
                if features is None:
                    failed += 1
                    continue
                
                ProductFeature.objects.create(
                    product=product,
                    feature_vector=features.tobytes()
                )
                
                indexed += 1
                self.stdout.write(f"✅ Indexed {indexed}/{products.count()}")
                
            except Exception as e:
                self.stdout.write(f"❌ Error indexing product {product.id}: {str(e)}")
                failed += 1
        
        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Done! Indexed: {indexed}, Skipped: {skipped}, Failed: {failed}"
        ))