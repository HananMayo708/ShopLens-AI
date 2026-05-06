from rest_framework import serializers
from django.contrib.auth import get_user_model, authenticate
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    initials = serializers.SerializerMethodField()
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 
            'phone', 'avatar', 'initials', 'full_name', 'date_of_birth',
            'address', 'city', 'country', 'postal_code',
            'is_verified', 'is_email_verified', 'date_joined',
            'preferred_categories', 'price_alert_threshold'
        ]
        read_only_fields = ['id', 'date_joined', 'is_verified', 'is_email_verified']
    
    def get_initials(self, obj):
        return obj.get_initials()
    
    def get_full_name(self, obj):
        return obj.get_full_name()

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True, 
        required=True,
        style={'input_type': 'password'}
    )
    
    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'password2', 
            'first_name', 'last_name', 'phone', 'date_of_birth',
            'address', 'city', 'country', 'postal_code'
        ]
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'email': {'required': True},
        }
    
    def validate(self, attrs):
        # Check if passwords match
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        
        # Check if email already exists
        if User.objects.filter(email=attrs['email']).exists():
            raise serializers.ValidationError({"email": "User with this email already exists."})
        
        # Check if username already exists (if provided)
        if attrs.get('username') and User.objects.filter(username=attrs['username']).exists():
            raise serializers.ValidationError({"username": "Username already exists."})
        
        return attrs
    
    def create(self, validated_data):
        # Remove password2
        validated_data.pop('password2')
        
        # Extract password for create_user
        password = validated_data.pop('password')
        
        # Create user using create_user method (which handles password hashing)
        user = User.objects.create_user(
            username=validated_data.get('username', ''),
            email=validated_data['email'],
            password=password,  # This will be properly hashed
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone=validated_data.get('phone', ''),
            date_of_birth=validated_data.get('date_of_birth'),
            address=validated_data.get('address', ''),
            city=validated_data.get('city', ''),
            country=validated_data.get('country', ''),
            postal_code=validated_data.get('postal_code', '')
        )
        
        return user

class LoginSerializer(serializers.Serializer):
    # Changed from 'username' to 'email' to match USERNAME_FIELD
    email = serializers.CharField(required=True, label="Email or Username")
    password = serializers.CharField(
        required=True, 
        write_only=True,
        style={'input_type': 'password'}
    )
    
    def validate(self, attrs):
        login_input = attrs.get('email')  # Now using email field
        password = attrs.get('password')
        
        print(f"Login attempt - Input: {login_input}")
        
        # Try to authenticate directly with the input
        # Since USERNAME_FIELD = 'email', Django will treat this as email
        authenticated_user = authenticate(
            username=login_input,  # Django will use this as email
            password=password
        )
        
        if authenticated_user:
            print(f"Authentication successful for {authenticated_user.email}")
            attrs['user'] = authenticated_user
            return attrs
        
        # If direct authentication fails, try to find user by username
        # (as fallback for backward compatibility)
        try:
            if '@' not in login_input:  # It might be a username
                user = User.objects.get(username=login_input)
                authenticated_user = authenticate(
                    username=user.email,  # Use the user's email
                    password=password
                )
                if authenticated_user:
                    print(f"Authentication successful via username lookup: {authenticated_user.email}")
                    attrs['user'] = authenticated_user
                    return attrs
        except User.DoesNotExist:
            pass
        
        print(f"Authentication failed for {login_input}")
        raise serializers.ValidationError("Invalid credentials")

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'first_name', 'last_name', 
            'phone', 'avatar', 'date_of_birth', 'address', 'city', 
            'country', 'postal_code', 'is_verified', 'is_email_verified',
            'date_joined', 'last_login', 'preferred_categories', 
            'price_alert_threshold'
        ]
        read_only_fields = [
            'id', 'date_joined', 'last_login', 'is_verified', 
            'is_email_verified', 'username', 'email'
        ]

class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'first_name', 'last_name', 'phone', 'avatar', 
            'date_of_birth', 'address', 'city', 'country', 
            'postal_code', 'preferred_categories', 'price_alert_threshold'
        ]

class TokenSerializer(serializers.Serializer):
    refresh = serializers.CharField()
    access = serializers.CharField()
    user = UserSerializer()