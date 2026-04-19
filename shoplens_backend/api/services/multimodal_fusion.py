import numpy as np

class MultimodalFusion:
    def __init__(self, text_weight=0.6, image_weight=0.4):
        self.text_weight = text_weight
        self.image_weight = image_weight
        print(f"✅ Multimodal Fusion initialized (text: {text_weight}, image: {image_weight}")

    def fuse_similarities(self, text_sim, image_sim):
        """Weighted fusion of text and image similarities"""
        return self.text_weight * text_sim + self.image_weight * image_sim

    def is_duplicate(self, text_sim, image_sim, threshold=0.85):
        """Determine if two products are the same"""
        fused = self.fuse_similarities(text_sim, image_sim)
        return fused > threshold

    def find_best_matches(self, text_sims, image_sims, threshold=0.8):
        """Find best matches from multiple candidates"""
        fused_scores = self.text_weight * text_sims + self.image_weight * image_sims
        return [(i, score) for i, score in enumerate(fused_scores) if score > threshold]
