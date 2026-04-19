# DISABLED - sentence_transformers not available
class TextEmbeddingService:
    def __init__(self):
        print("TextEmbeddingService is disabled")
    
    def get_embedding(self, text):
        return []
    
    def calculate_similarity(self, text1, text2):
        return 0.0
