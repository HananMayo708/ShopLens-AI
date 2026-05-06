from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from products.models import PriceAlert

class PriceAlertListView(APIView):
    """Get all price alerts for the authenticated user"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        alerts = PriceAlert.objects.filter(user=request.user).order_by('-created_at')
        
        data = [{
            'id': alert.id,
            'product_id': alert.product_id,
            'product_name': alert.product_name,
            'product_url': alert.product_url,
            'product_image': alert.product_image,
            'target_price': float(alert.target_price),
            'current_price': float(alert.current_price),
            'is_notified': alert.is_notified,
            'source_store': alert.source_store,
            'created_at': alert.created_at.isoformat(),
        } for alert in alerts]
        
        return Response({
            'success': True,
            'alerts': data,
            'count': len(data)
        })


class CreatePriceAlertView(APIView):
    """Create a new price alert"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        product_id = request.data.get('product_id')
        product_name = request.data.get('product_name')
        product_url = request.data.get('product_url', '')
        product_image = request.data.get('product_image', '')
        target_price = request.data.get('target_price')
        source_store = request.data.get('source_store', 'Amazon')
        
        if not all([product_id, product_name, target_price]):
            return Response(
                {'error': 'Missing required fields: product_id, product_name, target_price'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            target_price = float(target_price)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid target price'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if alert already exists
        alert, created = PriceAlert.objects.get_or_create(
            user=request.user,
            product_id=product_id,
            defaults={
                'product_name': product_name,
                'product_url': product_url,
                'product_image': product_image,
                'target_price': target_price,
                'source_store': source_store,
            }
        )
        
        if not created:
            # Update existing alert with new target price
            alert.target_price = target_price
            alert.is_notified = False
            alert.save()
        
        return Response({
            'success': True,
            'message': 'Price alert created successfully' if created else 'Price alert updated successfully',
            'alert_id': alert.id
        }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class DeletePriceAlertView(APIView):
    """Delete a price alert"""
    permission_classes = [IsAuthenticated]
    
    def delete(self, request, alert_id):
        try:
            alert = PriceAlert.objects.get(id=alert_id, user=request.user)
            alert.delete()
            return Response({
                'success': True,
                'message': 'Price alert deleted successfully'
            })
        except PriceAlert.DoesNotExist:
            return Response(
                {'error': 'Price alert not found'},
                status=status.HTTP_404_NOT_FOUND
            )