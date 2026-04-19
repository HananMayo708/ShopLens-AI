from api.services.text_embedding_service import TextEmbeddingService
from api.services.multimodal_fusion import MultimodalFusion
from api.kyc.document_verification import DocumentVerifier
from api.kyc.face_verification import FaceVerifier
from api.brand.logo_detection import LogoVerifier

print("="*50)
print("Testing all AI services...")
print("="*50)

# Test Text Embedding
print("\n1/5 Testing Text Embedding Service...")
text_service = TextEmbeddingService()
test_product = {'brand': 'Apple', 'name': 'MacBook Pro 14 M3', 'description': 'Laptop computer'}
embedding = text_service.encode_product(test_product)
print(f"✅ Embedding shape: {embedding.shape}")

# Test Multimodal Fusion
print("\n2/5 Testing Multimodal Fusion...")
fusion = MultimodalFusion()
print("✅ Fusion initialized")

# Test Document Verifier (will load model)
print("\n3/5 Testing Document Verifier...")
doc_verifier = DocumentVerifier()
print("✅ Document Verifier ready")

# Test Face Verifier (will load model)
print("\n4/5 Testing Face Verifier...")
face_verifier = FaceVerifier()
print("✅ Face Verifier ready")

# Test Logo Verifier (will load model)
print("\n5/5 Testing Logo Verifier...")
logo_verifier = LogoVerifier()
print("✅ Logo Verifier ready")

print("\n" + "="*50)
print("✅ All services tested successfully!")
print("="*50)
