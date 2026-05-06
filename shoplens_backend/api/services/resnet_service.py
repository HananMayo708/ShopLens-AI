import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import numpy as np
import json
import os

class ResNetFeatureExtractor:
    """Universal image recognition - recognizes ANY object from ImageNet 1000 classes"""
    
    def __init__(self):
        # Load full ResNet50 with classification head
        self.model = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V1)
        self.model.eval()
        
        self.transform = transforms.Compose([
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
        
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model = self.model.to(self.device)
        
        # Load ImageNet labels
        self.labels = self._load_imagenet_labels()
        
        print(f"✅ Universal ResNet50 loaded on {self.device}")
        print(f"📋 Ready to recognize {len(self.labels)} different objects")
    
    def _load_imagenet_labels(self):
        """Load ImageNet 1000 class labels"""
        try:
            # Try to load from local file
            labels_path = os.path.join(os.path.dirname(__file__), 'imagenet_labels.json')
            
            if os.path.exists(labels_path):
                with open(labels_path, 'r') as f:
                    labels = json.load(f)
                print(f"✅ Loaded {len(labels)} ImageNet labels from file")
                return labels
            else:
                # Download from GitHub
                import urllib.request
                url = "https://raw.githubusercontent.com/pytorch/hub/master/imagenet_classes.txt"
                response = urllib.request.urlopen(url)
                labels = [line.decode('utf-8').strip() for line in response.readlines()]
                
                # Save for future use
                with open(labels_path, 'w') as f:
                    json.dump(labels, f)
                
                print(f"✅ Downloaded and saved {len(labels)} ImageNet labels")
                return labels
                
        except Exception as e:
            print(f"⚠️ Error loading labels: {e}")
            # Fallback to basic labels
            return [f"class_{i}" for i in range(1000)]
    
    def recognize_image(self, image_file):
        """Recognize ANY object in the image - Universal recognition"""
        try:
            print("📸 Analyzing image with ResNet50...")
            
            # Load and preprocess image
            image = Image.open(image_file).convert('RGB')
            image_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            # Get predictions
            with torch.no_grad():
                outputs = self.model(image_tensor)
            
            # Get top predictions
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            top5_prob, top5_idx = torch.topk(probabilities, 5)
            
            detected = []
            
            for i in range(5):
                idx = top5_idx[i].item()
                confidence = top5_prob[i].item()
                
                # Get the actual class name from ImageNet labels
                class_name = self.labels[idx] if idx < len(self.labels) else f"object_{idx}"
                
                # Clean up the class name
                class_name = class_name.replace('_', ' ').split(',')[0]
                
                detected.append({
                    'label': class_name,
                    'confidence': confidence,
                    'class_id': idx
                })
                print(f"   {class_name}: {confidence:.2%}")
            
            # Get the best search term
            search_term = self._get_best_search_term(detected)
            print(f"🔍 Universal recognition result: {search_term}")
            
            return search_term
            
        except Exception as e:
            print(f"⚠️ Recognition error: {e}")
            return "product"
    
    def _get_best_search_term(self, detected):
        """Get the best search term from detected objects"""
        # Use the highest confidence detection above 50%
        for detection in detected:
            if detection['confidence'] > 0.5:
                label = detection['label']
                
                # Clean up the label for better search
                # Remove descriptive words and keep the main object
                main_object = label.split(',')[0].strip()
                
                # Map to search-friendly terms
                search_mapping = {
                    'laptop': ['laptop', 'notebook', 'notebook computer'],
                    'smartphone': ['smartphone', 'cell phone', 'mobile phone', 'iphone'],
                    'headphone': ['headphone', 'earphone', 'headset'],
                    'desktop computer': ['desktop computer', 'computer', 'pc'],
                    'digital camera': ['camera', 'digital camera', 'dslr'],
                    'watch': ['watch', 'wrist watch'],
                    'television': ['television', 'tv', 'monitor'],
                    'radio': ['speaker', 'radio', 'bluetooth speaker'],
                    'microphone': ['microphone', 'mic'],
                    'printer': ['printer'],
                    'mouse': ['mouse', 'computer mouse'],
                    'keyboard': ['keyboard', 'computer keyboard'],
                }
                
                for search_term, keywords in search_mapping.items():
                    if any(keyword in main_object.lower() for keyword in keywords):
                        return search_term
                
                # If no mapping, return the actual object name
                return main_object
        
        # Fallback to highest confidence
        if detected:
            return detected[0]['label']
        
        return "electronics"
    
    def extract_features(self, image_file):
        """Extract feature vector for similarity search"""
        try:
            # Remove classification head for feature extraction
            feature_model = torch.nn.Sequential(*list(self.model.children())[:-1])
            feature_model = feature_model.to(self.device)
            feature_model.eval()
            
            # Handle different input types
            if hasattr(image_file, 'read'):
                image = Image.open(image_file).convert('RGB')
            else:
                image = Image.open(image_file).convert('RGB')
            
            image_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            with torch.no_grad():
                features = feature_model(image_tensor)
            
            # Flatten and normalize
            feature_vector = features.cpu().numpy().flatten()
            norm = np.linalg.norm(feature_vector)
            if norm > 0:
                feature_vector = feature_vector / norm
            
            return feature_vector.tolist()
            
        except Exception as e:
            print(f"⚠️ Feature extraction error: {e}")
            return None
    
    def get_product_category(self, image_file):
        """Get product category from image"""
        search_term = self.recognize_image(image_file)
        
        # Map search term to category
        category_map = {
            'laptop': 'laptops',
            'smartphone': 'smartphones',
            'headphone': 'headphones',
            'computer': 'computers',
            'camera': 'cameras',
            'watch': 'watches',
            'television': 'tvs',
            'speaker': 'speakers',
            'printer': 'printers',
            'mouse': 'mice',
            'keyboard': 'keyboards',
            'tablet': 'tablets',
        }
        
        for key, category in category_map.items():
            if key in search_term.lower():
                return category
        
        return 'electronics'


class ResNetService:
    """Universal image search service"""
    
    def __init__(self):
        try:
            self.recognizer = ResNetFeatureExtractor()
            self.is_available = True
        except Exception as e:
            print(f"⚠️ ResNetService initialization failed: {e}")
            self.is_available = False
    
    def analyze_image(self, image_file):
        """Universal image recognition - works for ANY object"""
        if not self.is_available:
            return ["product"]
        
        try:
            search_query = self.recognizer.recognize_image(image_file)
            print(f"🔍 Recognition result: {search_query}")
            return [search_query]
            
        except Exception as e:
            print(f"⚠️ Recognition error: {e}")
            return ["product"]
    
    def extract_features(self, image_file):
        """Extract features for similarity search"""
        if not self.is_available:
            return None
        return self.recognizer.extract_features(image_file)
    
    def get_category(self, image_file):
        """Get product category from image"""
        if not self.is_available:
            return "electronics"
        return self.recognizer.get_product_category(image_file)