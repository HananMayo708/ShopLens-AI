# DISABLED - PyTorch not available
class FaceVerifier:
    def __init__(self):
        print("FaceVerifier is disabled (PyTorch not available)")
    
    def verify_face(self, selfie_path, id_card_path):
        return {
            "verified": False,
            "error": "Face verification is disabled",
            "similarity_score": 0
        }
