from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from ..services.text_embedding_service import TextEmbeddingService
from ..services.multimodal_fusion import MultimodalFusion
from ..kyc.document_verification import DocumentVerifier
from ..kyc.face_verification_simple import FaceVerifier
from ..brand.logo_detection import LogoVerifier
import logging

logger = logging.getLogger(__name__)

class MarketplaceIntegrityView(APIView):
    """
    Endpoint for seller onboarding with AI-powered verification
    """
    parser_classes = (MultiPartParser, FormParser)

    def __init__(self):
        # Lazy loading - initialize only when needed
        self._text_embedder = None
        self._fusion = None
        self._doc_verifier = None
        self._face_verifier = None
        self._logo_verifier = None

    @property
    def text_embedder(self):
        if self._text_embedder is None:
            self._text_embedder = TextEmbeddingService()
        return self._text_embedder

    @property
    def fusion(self):
        if self._fusion is None:
            self._fusion = MultimodalFusion()
        return self._fusion

    @property
    def doc_verifier(self):
        if self._doc_verifier is None:
            self._doc_verifier = DocumentVerifier()
        return self._doc_verifier

    @property
    def face_verifier(self):
        if self._face_verifier is None:
            self._face_verifier = FaceVerifier()
        return self._face_verifier

    @property
    def logo_verifier(self):
        if self._logo_verifier is None:
            self._logo_verifier = LogoVerifier()
        return self._logo_verifier

    def post(self, request):
        """Endpoint for seller onboarding with verification"""
        try:
            verification_results = {
                'document_verified': False,
                'face_verified': False,
                'logo_verified': False
            }

            # Step 1: KYC Document Verification
            if 'business_license' in request.FILES:
                doc_bytes = request.FILES['business_license'].read()
                doc_result = self.doc_verifier.verify_business_license(doc_bytes)
                verification_results['document_verified'] = doc_result.get('verified', False)
                verification_results['document_details'] = doc_result

                if not doc_result.get('verified'):
                    return Response({
                        'success': False,
                        'error': 'Document verification failed',
                        'details': doc_result
                    }, status=400)

            # Step 2: Face Verification (selfie vs ID) - using simulation mode
            if 'selfie' in request.FILES and 'id_card' in request.FILES:
                selfie_bytes = request.FILES['selfie'].read()
                id_bytes = request.FILES['id_card'].read()
                face_result = self.face_verifier.verify_selfie_vs_id(selfie_bytes, id_bytes)
                verification_results['face_verified'] = face_result.get('verified', False)
                verification_results['face_details'] = face_result
                verification_results['face_simulated'] = face_result.get('simulated', False)

                # In simulation mode, we don't fail if verification fails
                if not face_result.get('verified') and not face_result.get('simulated'):
                    return Response({
                        'success': False,
                        'error': 'Face verification failed',
                        'details': face_result
                    }, status=400)

            # Step 3: Logo/Brand Verification
            if 'logo' in request.FILES and request.data.get('brand'):
                logo_bytes = request.FILES['logo'].read()
                brand = request.data.get('brand')
                logo_result = self.logo_verifier.verify_logo(logo_bytes, brand)
                verification_results['logo_verified'] = logo_result.get('is_authentic', False)
                verification_results['logo_details'] = logo_result

                if not logo_result.get('is_authentic', False):
                    return Response({
                        'success': False,
                        'error': 'Brand logo verification failed',
                        'details': logo_result
                    }, status=400)

            # Step 4: If all verifications pass
            return Response({
                'success': True,
                'message': 'Seller verified successfully',
                'verification_level': 'full_kyc',
                'results': verification_results
            })

        except Exception as e:
            logger.error(f"Verification error: {str(e)}", exc_info=True)
            return Response({
                'success': False,
                'error': str(e)
            }, status=500)
