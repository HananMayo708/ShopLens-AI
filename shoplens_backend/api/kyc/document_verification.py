# DISABLED - PyTorch and transformers not available
# All functionality is temporarily disabled

class DocumentVerifier:
    def __init__(self):
        print("DocumentVerifier is disabled (PyTorch/transformers not available)")
    
    def verify_document(self, image_path):
        return {
            "verified": False,
            "error": "Document verification is disabled",
            "extracted_text": {}
        }
