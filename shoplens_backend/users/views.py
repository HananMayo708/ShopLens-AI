# user/views.py - COMPLETE FILE
from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.views import APIView
import random
from datetime import datetime, timedelta
from .serializers import RegisterSerializer, LoginSerializer, UserSerializer

# ==================== AUTHENTICATION APIs ====================

class RegisterView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, created = Token.objects.get_or_create(user=user)
            return Response({
                'user': UserSerializer(user).data,
                'token': token.key,
                'message': 'User created successfully'
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            
            # Authenticate user
            user = authenticate(username=email, password=password)
            
            if user:
                token, created = Token.objects.get_or_create(user=user)
                return Response({
                    'user': UserSerializer(user).data,
                    'token': token.key,
                    'message': 'Login successful'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'error': 'Invalid credentials'
                }, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        return Response({
            'id': user.id,
            'email': user.email,
            'username': user.username,
            'date_joined': user.date_joined
        })

# ==================== SHOPLENS AI PRODUCT APIs ====================

class ProductSearchAPI(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        """API 1: Search products by text query"""
        query = request.GET.get('q', '').lower()
        
        # Dummy product database (replace with real DB later)
        all_products = [
            {
                "id": 1,
                "title": "iPhone 13 128GB",
                "description": "Apple iPhone 13 with A15 Bionic Chip",
                "category": "Electronics",
                "image_url": "https://via.placeholder.com/300x300/007AFF/FFFFFF?text=iPhone+13",
                "platforms": [
                    {
                        "platform": "Daraz",
                        "price": 215000,
                        "seller": "TechStorePK",
                        "seller_rating": 4.2,
                        "delivery_days": 3
                    },
                    {
                        "platform": "Amazon",
                        "price": 245000, 
                        "seller": "AppleOfficial",
                        "seller_rating": 4.7,
                        "delivery_days": 7
                    }
                ]
            },
            {
                "id": 2,
                "title": "Samsung Galaxy S23 Ultra",
                "description": "Samsung Galaxy S23 Ultra 256GB",
                "category": "Electronics",
                "image_url": "https://via.placeholder.com/300x300/000000/FFFFFF?text=S23+Ultra",
                "platforms": [
                    {
                        "platform": "Daraz",
                        "price": 325000,
                        "seller": "MobileWorld",
                        "seller_rating": 4.0,
                        "delivery_days": 5
                    },
                    {
                        "platform": "eBay",
                        "price": 315000,
                        "seller": "GadgetHub",
                        "seller_rating": 3.8,
                        "delivery_days": 10
                    }
                ]
            },
            {
                "id": 3,
                "title": "Wireless Mouse Logitech MX Master 3",
                "description": "Wireless Ergonomic Mouse",
                "category": "Accessories",
                "image_url": "https://via.placeholder.com/300x300/FF6B6B/FFFFFF?text=Logitech+Mouse",
                "platforms": [
                    {
                        "platform": "Daraz",
                        "price": 12500,
                        "seller": "ComputerZone",
                        "seller_rating": 4.5,
                        "delivery_days": 2
                    },
                    {
                        "platform": "Amazon",
                        "price": 14500,
                        "seller": "LogitechStore",
                        "seller_rating": 4.8,
                        "delivery_days": 14
                    },
                    {
                        "platform": "Goto.pk",
                        "price": 11500,
                        "seller": "TechMart",
                        "seller_rating": 3.9,
                        "delivery_days": 1
                    }
                ]
            },
            {
                "id": 4,
                "title": "Dell XPS 13 Laptop",
                "description": "Dell XPS 13 9315 Touchscreen Laptop",
                "category": "Laptops",
                "image_url": "https://via.placeholder.com/300x300/008000/FFFFFF?text=Dell+XPS+13",
                "platforms": [
                    {
                        "platform": "Daraz",
                        "price": 285000,
                        "seller": "ComputerZone",
                        "seller_rating": 4.3,
                        "delivery_days": 4
                    },
                    {
                        "platform": "Amazon",
                        "price": 315000,
                        "seller": "DellOfficial",
                        "seller_rating": 4.6,
                        "delivery_days": 12
                    }
                ]
            },
            {
                "id": 5,
                "title": "Nike Air Max 270",
                "description": "Men's Running Shoes",
                "category": "Fashion",
                "image_url": "https://via.placeholder.com/300x300/FF4500/FFFFFF?text=Nike+Air+Max",
                "platforms": [
                    {
                        "platform": "Daraz",
                        "price": 14500,
                        "seller": "SportsHub",
                        "seller_rating": 4.1,
                        "delivery_days": 3
                    },
                    {
                        "platform": "eBay",
                        "price": 16500,
                        "seller": "ShoeStore",
                        "seller_rating": 3.7,
                        "delivery_days": 8
                    }
                ]
            }
        ]
        
        # Filter by search query
        if query:
            filtered_products = []
            for product in all_products:
                if (query in product['title'].lower() or 
                    query in product['description'].lower() or
                    query in product['category'].lower()):
                    filtered_products.append(product)
        else:
            filtered_products = all_products
        
        # Add best price calculation
        for product in filtered_products:
            prices = [p['price'] for p in product['platforms']]
            product['best_price'] = min(prices) if prices else 0
            product['platform_count'] = len(product['platforms'])
            product['currency'] = 'PKR'
        
        return Response({
            "success": True,
            "query": query,
            "count": len(filtered_products),
            "results": filtered_products
        })

class ProductDetailAPI(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, product_id):
        """API 2: Get detailed product info with price comparison"""
        # Map product_id to titles
        product_titles = {
            1: "iPhone 13 128GB",
            2: "Samsung Galaxy S23 Ultra",
            3: "Wireless Mouse Logitech MX Master 3",
            4: "Dell XPS 13 Laptop",
            5: "Nike Air Max 270"
        }
        
        title = product_titles.get(product_id, f"Product {product_id}")
        
        product_data = {
            "id": product_id,
            "title": title,
            "description": f"Detailed description for {title}...",
            "category": "Electronics" if product_id <= 4 else "Fashion",
            "specifications": {
                "Brand": "Apple" if product_id == 1 else "Samsung" if product_id == 2 else "Logitech" if product_id == 3 else "Dell" if product_id == 4 else "Nike",
                "Model": title.split()[0],
                "Color": "Midnight" if product_id == 1 else "Phantom Black" if product_id == 2 else "Black" if product_id == 3 else "Silver" if product_id == 4 else "White/Red",
                "Warranty": "1 Year"
            },
            "price_comparison": [
                {
                    "platform": "Daraz",
                    "price": 215000 if product_id == 1 else 325000 if product_id == 2 else 12500 if product_id == 3 else 285000 if product_id == 4 else 14500,
                    "original_price": 225000 if product_id == 1 else 340000 if product_id == 2 else 13500 if product_id == 3 else 295000 if product_id == 4 else 15500,
                    "discount": "4%" if product_id == 1 else "4%" if product_id == 2 else "7%" if product_id == 3 else "3%" if product_id == 4 else "6%",
                    "seller": "TechStorePK" if product_id == 1 else "MobileWorld" if product_id == 2 else "ComputerZone" if product_id == 3 else "ComputerZone" if product_id == 4 else "SportsHub",
                    "seller_trust_score": 8.5 if product_id == 1 else 8.0 if product_id == 2 else 9.0 if product_id == 3 else 8.3 if product_id == 4 else 8.1,
                    "delivery": "3-5 days",
                    "shipping_fee": 200,
                    "return_policy": "30 days"
                },
                {
                    "platform": "Amazon",
                    "price": 245000 if product_id == 1 else 0 if product_id == 2 else 14500 if product_id == 3 else 315000 if product_id == 4 else 0,
                    "original_price": 245000 if product_id == 1 else 0 if product_id == 2 else 14500 if product_id == 3 else 315000 if product_id == 4 else 0,
                    "discount": "0%" if product_id == 1 else "0%" if product_id == 2 else "0%" if product_id == 3 else "0%" if product_id == 4 else "0%",
                    "seller": "AppleOfficial" if product_id == 1 else "Not Available" if product_id == 2 else "LogitechStore" if product_id == 3 else "DellOfficial" if product_id == 4 else "Not Available",
                    "seller_trust_score": 9.2 if product_id == 1 else 0 if product_id == 2 else 9.5 if product_id == 3 else 9.0 if product_id == 4 else 0,
                    "delivery": "7-10 days",
                    "shipping_fee": 500,
                    "return_policy": "14 days"
                },
                {
                    "platform": "eBay",
                    "price": 225000 if product_id == 1 else 315000 if product_id == 2 else 0 if product_id == 3 else 0 if product_id == 4 else 16500,
                    "original_price": 240000 if product_id == 1 else 330000 if product_id == 2 else 0 if product_id == 3 else 0 if product_id == 4 else 17500,
                    "discount": "6%" if product_id == 1 else "5%" if product_id == 2 else "0%" if product_id == 3 else "0%" if product_id == 4 else "6%",
                    "seller": "GadgetWorld" if product_id == 1 else "GadgetHub" if product_id == 2 else "Not Available" if product_id == 3 else "Not Available" if product_id == 4 else "ShoeStore",
                    "seller_trust_score": 7.8 if product_id == 1 else 7.5 if product_id == 2 else 0 if product_id == 3 else 0 if product_id == 4 else 7.3,
                    "delivery": "10-14 days",
                    "shipping_fee": 800,
                    "return_policy": "30 days"
                }
            ],
            "trust_analysis": {
                "overall_trust_score": 8.5 if product_id == 1 else 7.8 if product_id == 2 else 9.0 if product_id == 3 else 8.3 if product_id == 4 else 7.7,
                "review_count": 1247 if product_id == 1 else 856 if product_id == 2 else 342 if product_id == 3 else 567 if product_id == 4 else 234,
                "positive_reviews": 85,
                "negative_reviews": 12,
                "fake_review_detected": 3
            },
            "ai_insights": {
                "best_value": "Daraz" if product_id in [1, 2, 3, 4] else "Daraz",
                "fastest_delivery": "Goto.pk" if product_id == 3 else "Daraz",
                "most_trusted": "Amazon" if product_id in [1, 3, 4] else "Daraz"
            }
        }
        
        # Remove unavailable platforms
        product_data['price_comparison'] = [p for p in product_data['price_comparison'] if p['price'] > 0]
        
        return Response(product_data)

class PriceTrendAPI(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request, product_id):
        """API 3: Get price history and forecast"""
        # Generate dummy price history (last 30 days)
        today = datetime.now()
        price_history = []
        
        # Base prices for different products
        base_prices = {
            1: 220000,  # iPhone
            2: 330000,  # Samsung
            3: 13000,   # Mouse
            4: 290000,  # Laptop
            5: 15000    # Shoes
        }
        
        base_price = base_prices.get(product_id, 100000)
        
        for i in range(30, 0, -1):
            date = today - timedelta(days=i)
            # Simulate price fluctuations
            fluctuation = random.randint(-5000, 5000) if product_id <= 4 else random.randint(-500, 500)
            price = base_price + fluctuation + (i * 300)
            
            price_history.append({
                "date": date.strftime("%Y-%m-%d"),
                "price": price,
                "platform": random.choice(["Daraz", "Amazon", "eBay", "Goto.pk"])
            })
        
        # Forecast next 7 days
        forecast = []
        current_price = price_history[-1]['price'] if price_history else base_price
        trend_options = ['rising', 'falling', 'stable']
        current_trend = random.choice(trend_options)
        
        for i in range(1, 8):
            date = today + timedelta(days=i)
            
            if current_trend == 'rising':
                change = random.randint(100, 1000)
            elif current_trend == 'falling':
                change = random.randint(-1000, -100)
            else:
                change = random.randint(-50, 50)
            
            forecast_price = current_price + change
            
            forecast.append({
                "date": date.strftime("%Y-%m-%d"),
                "predicted_price": forecast_price,
                "trend": current_trend,
                "confidence": random.randint(75, 92)
            })
        
        # AI recommendation logic
        if current_trend == 'falling':
            recommendation = 'WAIT_FOR_DROP'
        elif current_trend == 'rising':
            recommendation = 'BUY_NOW'
        else:
            recommendation = 'MONITOR'
        
        return Response({
            "product_id": product_id,
            "current_price": current_price,
            "currency": "PKR",
            "price_history": price_history[-10:],  # Last 10 days
            "forecast": forecast,
            "ai_recommendation": recommendation,
            "confidence": 85
        })

# ==================== BOOKMARK APIs ====================

@api_view(['GET', 'POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def bookmark_api(request, product_id=None):
    """Simple bookmark functionality"""
    if request.method == 'GET':
        # Return user's bookmarks
        dummy_bookmarks = [
            {"id": 1, "product_id": 1, "added_date": "2024-01-15", "title": "iPhone 13 128GB"},
            {"id": 2, "product_id": 3, "added_date": "2024-01-10", "title": "Logitech MX Master 3"}
        ]
        return Response({
            "success": True,
            "count": len(dummy_bookmarks),
            "bookmarks": dummy_bookmarks
        })
    
    elif request.method == 'POST':
        # Add to bookmarks
        return Response({
            "success": True,
            "message": "Product bookmarked successfully",
            "product_id": product_id,
            "user": request.user.username
        }, status=status.HTTP_201_CREATED)
    
    elif request.method == 'DELETE':
        # Remove from bookmarks
        return Response({
            "success": True,
            "message": "Bookmark removed successfully"
        }, status=status.HTTP_200_OK)

# ==================== HEALTH CHECK ====================

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """Simple health check endpoint"""
    return Response({
        "status": "healthy",
        "service": "ShopLens AI API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "endpoints_available": [
            "/api/register/",
            "/api/login/",
            "/api/products/search/?q=query",
            "/api/products/{id}/",
            "/api/products/{id}/trends/",
            "/api/bookmarks/",
            "/api/profile/"
        ]
    })