# DISABLED - PyTorch not available
class LogoVerifier:
    def __init__(self):
        print("LogoVerifier is disabled (PyTorch not available)")
    
    def verify_logo(self, image_path, brand_name):
        return {
            "verified": False,
            "error": "Logo verification is disabled",
            "confidence": 0
        }
