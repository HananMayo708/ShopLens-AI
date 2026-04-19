import logging
import random
import math

logger = logging.getLogger(__name__)

class ProductMatcher:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def load_models(self):
        logger.info("✅ Running in DEMO mode - no AI dependencies required")
        return True
    
    def extract_image_features(self, image_data):
        """Return mock features for demo"""
        # Return a list instead of numpy array
        return [random.random() for _ in range(100)]
    
    def extract_text_features(self, text):
        """Return mock features for demo"""
        # Return a list instead of numpy array
        return [random.random() for _ in range(100)]
    
    def compute_similarity(self, img_features1, text_features1, img_features2, text_features2, alpha=0.6):
        """Return realistic demo similarity scores - NO NUMPY DEPENDENCY"""
        # Generate realistic demo scores without numpy
        img_sim = random.uniform(0.70, 0.95)
        text_sim = random.uniform(0.75, 0.98)
        final_sim = alpha * img_sim + (1 - alpha) * text_sim
        
        # Simple cosine similarity mock
        cos_sim = random.uniform(0.80, 0.95)
        
        return {
            'image_similarity': round(img_sim, 3),
            'text_similarity': round(text_sim, 3),
            'final_similarity': round(final_sim, 3),
            'cosine_similarity': round(cos_sim, 3),
            'is_match': final_sim > 0.85,
            'mode': 'DEMO - No dependencies'
        }
