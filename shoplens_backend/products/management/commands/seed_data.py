# products/management/commands/seed_data.py
from django.core.management.base import BaseCommand
from django.conf import settings
from products.models import Product, Category, Seller, Review
import random
from decimal import Decimal
from datetime import datetime, timedelta

class Command(BaseCommand):
    help = 'Seed database with sample data'

    def handle(self, *args, **kwargs):
        self.stdout.write('🚀 Seeding database with sample data...')
        
        # 1. Get or create admin user
        from django.contrib.auth import get_user_model
        User = get_user_model()
        
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser(
                username='admin',
                email='admin@shoplens.com',
                password='admin123',
                first_name='Admin',
                last_name='User'
            )
            self.stdout.write('✅ Created admin user: admin / admin123')
        else:
            self.stdout.write('⚠️ Admin user already exists')
        
        # 2. Create test users
        test_users = []
        for i in range(1, 4):
            username = f'testuser{i}'
            if not User.objects.filter(username=username).exists():
                user = User.objects.create_user(
                    username=username,
                    email=f'user{i}@example.com',
                    password='testpass123',
                    first_name=f'Test{i}',
                    last_name=f'User{i}'
                )
                test_users.append(user)
                self.stdout.write(f'✅ Created user: {username} / testpass123')
            else:
                user = User.objects.get(username=username)
                test_users.append(user)
                self.stdout.write(f'⚠️ User exists: {username}')
        
        # 3. Create categories
        categories_data = [
            {'name': 'Electronics', 'description': 'Devices and gadgets'},
            {'name': 'Clothing', 'description': 'Apparel and fashion'},
            {'name': 'Books', 'description': 'Books and publications'},
            {'name': 'Home & Kitchen', 'description': 'Home appliances and utensils'},
            {'name': 'Sports', 'description': 'Sports equipment'},
        ]
        
        categories = []
        for cat_data in categories_data:
            cat, created = Category.objects.get_or_create(
                name=cat_data['name'],
                defaults={'description': cat_data['description']}
            )
            categories.append(cat)
            if created:
                self.stdout.write(f'✅ Created category: {cat.name}')
        
        # 4. Create sellers
        sellers_data = [
            {'name': 'Amazon', 'rating': 4.5, 'website': 'https://amazon.com'},
            {'name': 'BestBuy', 'rating': 4.2, 'website': 'https://bestbuy.com'},
            {'name': 'Walmart', 'rating': 4.0, 'website': 'https://walmart.com'},
            {'name': 'Target', 'rating': 4.1, 'website': 'https://target.com'},
            {'name': 'Newegg', 'rating': 4.3, 'website': 'https://newegg.com'},
        ]
        
        sellers = []
        for seller_data in sellers_data:
            seller, created = Seller.objects.get_or_create(
                name=seller_data['name'],
                defaults={
                    'rating': seller_data['rating'],
                    'website': seller_data['website'],
                    'contact_email': f'contact@{seller_data["name"].lower()}.com'
                }
            )
            sellers.append(seller)
            if created:
                self.stdout.write(f'✅ Created seller: {seller.name}')
        
        # 5. Create sample products
        products_data = [
            # Electronics
            {'name': 'iPhone 15 Pro', 'price': 999.99, 'category': 'Electronics', 'seller': 'Apple'},
            {'name': 'Samsung Galaxy S24', 'price': 799.99, 'category': 'Electronics', 'seller': 'Samsung'},
            {'name': 'MacBook Air M2', 'price': 1199.99, 'category': 'Electronics', 'seller': 'Apple'},
            {'name': 'Sony WH-1000XM5', 'price': 399.99, 'category': 'Electronics', 'seller': 'Sony'},
            {'name': 'iPad Pro', 'price': 1099.99, 'category': 'Electronics', 'seller': 'Apple'},
            
            # Clothing
            {'name': 'Nike Air Max', 'price': 129.99, 'category': 'Clothing', 'seller': 'Nike'},
            {'name': 'Levi\'s Jeans', 'price': 69.99, 'category': 'Clothing', 'seller': 'Levi\'s'},
            {'name': 'North Face Jacket', 'price': 199.99, 'category': 'Clothing', 'seller': 'North Face'},
            
            # Books
            {'name': 'The Great Gatsby', 'price': 12.99, 'category': 'Books', 'seller': 'Penguin'},
            {'name': 'Python Crash Course', 'price': 39.99, 'category': 'Books', 'seller': 'No Starch Press'},
        ]
        
        # Create additional sellers for product-specific sellers
        additional_sellers = ['Apple', 'Samsung', 'Sony', 'Nike', 'Levi\'s', 'North Face', 'Penguin', 'No Starch Press']
        for seller_name in additional_sellers:
            seller_exists = False
            for s in sellers:
                if s.name == seller_name:
                    seller_exists = True
                    break
            
            if not seller_exists:
                seller, _ = Seller.objects.get_or_create(
                    name=seller_name,
                    defaults={
                        'rating': round(random.uniform(4.0, 5.0), 1),
                        'website': f'https://{seller_name.lower().replace(" ", "").replace("\'", "")}.com',
                        'contact_email': f'contact@{seller_name.lower().replace(" ", "").replace("\'", "")}.com'
                    }
                )
                sellers.append(seller)
                self.stdout.write(f'✅ Created seller: {seller.name}')
        
        products = []
        for i, prod_data in enumerate(products_data):
            # Find category
            category = None
            for c in categories:
                if c.name == prod_data['category']:
                    category = c
                    break
            if not category:
                category = categories[0]
            
            # Find seller
            seller = None
            for s in sellers:
                if s.name == prod_data['seller']:
                    seller = s
                    break
            if not seller:
                seller = sellers[0]
            
            product, created = Product.objects.get_or_create(
                name=prod_data['name'],
                defaults={
                    'price': Decimal(str(prod_data['price'])),
                    'category': category,
                    'seller': seller,
                    'description': f'High-quality {prod_data["name"].lower()} for everyday use.',
                    'stock_quantity': random.randint(10, 100),
                    'sku': f'PROD{1000 + i}',
                    'image_url': f'/media/products/{prod_data["name"].lower().replace(" ", "_").replace("\'", "")}.jpg',
                    'is_active': True,
                }
            )
            
            if created:
                products.append(product)
                self.stdout.write(f'✅ Created product: {product.name} ()')
        
        # 6. Create sample reviews (with duplicate check)
        review_texts = [
            'Excellent product! Highly recommend.',
            'Good value for money.',
            'Fast shipping and good packaging.',
            'Average product, does the job.',
            'Best purchase I\'ve made!',
            'Could be better, but works fine.',
            'Exactly as described, very happy.',
            'Good quality but a bit expensive.',
        ]
        
        review_count = 0
        for product in products:
            # Each product gets 2-4 reviews
            for _ in range(random.randint(2, 4)):
                try:
                    # Check if review already exists for this user-product combination
                    user = random.choice(test_users)
                    if not Review.objects.filter(product=product, user=user).exists():
                        Review.objects.create(
                            product=product,
                            user=user,
                            rating=random.randint(3, 5),
                            comment=random.choice(review_texts),
                            created_at=datetime.now() - timedelta(days=random.randint(1, 30))
                        )
                        review_count += 1
                except Exception as e:
                    self.stdout.write(f'⚠️ Error creating review: {e}')
        
        # 7. Summary
        self.stdout.write('\n' + '='*50)
        self.stdout.write('📊 SEEDING COMPLETE - DATABASE SUMMARY')
        self.stdout.write('='*50)
        self.stdout.write(f'👥 Users: {User.objects.count()} total')
        self.stdout.write(f'📁 Categories: {Category.objects.count()} total')
        self.stdout.write(f'🏪 Sellers: {Seller.objects.count()} total')
        self.stdout.write(f'🛒 Products: {Product.objects.count()} total')
        self.stdout.write(f'⭐ Reviews: {Review.objects.count()} total')
        self.stdout.write('='*50)
        self.stdout.write('\n🔗 Access Information:')
        self.stdout.write('🌐 Admin: http://localhost:8000/admin')
        self.stdout.write('🔐 Admin login: admin / admin123')
        self.stdout.write('👤 Test user: testuser1 / testpass123')
        self.stdout.write('='*50)
        
        self.stdout.write(self.style.SUCCESS('\n✅ Database seeding completed successfully!'))
