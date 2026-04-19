import os
from django.core.management.base import BaseCommand
from products.models import Product, ProductFeature
from api.services.resnet_service import ResNetFeatureExtractor
import requests
from io import BytesIO

class Command(BaseCommand):
    help = 'Extract ResNet50 features for all products'
    
    def handle(self, *args, **options):
        extractor = ResNetFeatureExtractor()
        products = Product.objects.all()
        
        self.stdout.write(f"Found {products.count()} products to process")
        
        for i, product in enumerate(products):
            self.stdout.write(f"Processing {i+1}/{products.count()}: {product.name}")
            
            if not product.imageUrl:
                self.stdout.write(f"  ⏭️ No image, skipping")
                continue
                
            try:
                # Download image
                response = requests.get(product.imageUrl, timeout=10)
                if response.status_code == 200:
                    # Extract features
                    features = extractor.extract_features(response.content)
                    
                    if features:
                        # Save or update features
                        ProductFeature.objects.update_or_create(
                            product=product,
                            defaults={'feature_vector': features}
                        )
                        self.stdout.write(f"  ✅ Features extracted")
                    else:
                        self.stdout.write(f"  ❌ Feature extraction failed")
                else:
                    self.stdout.write(f"  ❌ Failed to download image")
                    
            except Exception as e:
                self.stdout.write(f"  ❌ Error: {e}")
        
        self.stdout.write(self.style.SUCCESS('✅ Feature extraction complete'))