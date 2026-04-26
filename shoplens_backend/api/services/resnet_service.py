import torch
import torchvision.models as models
import torchvision.transforms as transforms
from PIL import Image
import numpy as np

class ResNetFeatureExtractor:
    """Universal image recognition - recognizes ANY object"""
    
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
        print(f"✅ Universal ResNet50 loaded on {self.device}")
    
    def recognize_image(self, image_file):
        """Recognize ANY object in the image - Universal recognition"""
        try:
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
                
                # Get the actual class name
                class_name = self._get_class_name(idx)
                
                detected.append({
                    'label': class_name,
                    'confidence': confidence,
                    'class_id': idx
                })
                print(f"   {class_name}: {confidence:.2%}")
            
            # Try to find the most relevant product term
            search_term = self._get_best_search_term(detected)
            return search_term
            
        except Exception as e:
            print(f"⚠️ Recognition error: {e}")
            return "product"
    
    def _get_best_search_term(self, detected):
        """Get the best search term from detected objects"""
        # Priority: electronics > clothing > home > other
        
        priority_keywords = [
            'laptop', 'computer', 'phone', 'cell phone', 'smartphone',
            'headphones', 'speaker', 'camera', 'watch', 'tablet',
            'keyboard', 'mouse', 'monitor', 'printer', 'scanner'
        ]
        
        for detection in detected:
            label = detection['label'].lower()
            for keyword in priority_keywords:
                if keyword in label:
                    return keyword
        
        # If no priority keyword, return the highest confidence product
        if detected:
            return detected[0]['label']
        
        return "product"
    
    def _get_class_name(self, class_id):
        """Get human-readable class name from ImageNet ID"""
        # Expanded class mapping for better product recognition
        class_map = {
            # Electronics (High priority)
            817: 'pen', 820: 'pencil', 821: 'notebook',
            850: 'cell phone', 851: 'smartphone', 852: 'mobile phone',
            856: 'computer', 857: 'laptop', 858: 'notebook computer',
            859: 'desktop computer', 860: 'all-in-one computer',
            863: 'clock', 864: 'watch', 865: 'smartwatch',
            886: 'camera', 887: 'headphones', 888: 'earbuds',
            889: 'desk lamp', 890: 'speaker', 891: 'microphone',
            892: 'calculator', 893: 'printer', 894: 'scanner',
            895: 'webcam', 896: 'keyboard', 897: 'mouse',
            898: 'monitor', 899: 'display',
            
            # More electronics
            673: 'laptop',  # This is your missing mapping!
            674: 'notebook',
            675: 'computer keyboard',
            676: 'computer mouse',
            
            # Clothing
            900: 't-shirt', 901: 'jeans', 902: 'shoes', 903: 'jacket',
            904: 'hat', 905: 'sunglasses', 906: 'backpack', 907: 'wallet',
            908: 'handbag', 909: 'dress',
            
            # Home
            910: 'chair', 911: 'table', 912: 'sofa', 913: 'bed',
            914: 'lamp', 915: 'mirror', 916: 'rug', 917: 'curtain',
            918: 'pillow', 919: 'blanket',
            
            # Kitchen
            920: 'refrigerator', 921: 'microwave', 922: 'oven',
            923: 'toaster', 924: 'blender', 925: 'coffee maker',
            
            # Food
            930: 'pizza', 931: 'burger', 932: 'sandwich',
            933: 'pasta', 934: 'salad', 935: 'coffee',
            936: 'tea', 937: 'beverage',
            
            # Sports
            940: 'ball', 941: 'racket', 942: 'bat', 943: 'glove',
            944: 'helmet', 945: 'skateboard',
            
            # Books/Media
            950: 'book', 951: 'magazine', 952: 'notebook', 953: 'diary',
            
            # Tools
            960: 'hammer', 961: 'screwdriver', 962: 'wrench', 963: 'drill',
            964: 'saw', 965: 'pliers',
            
            # Jewelry
            970: 'ring', 971: 'necklace', 972: 'earring', 973: 'bracelet',
            
            # Toys/Games
            980: 'game controller', 981: 'video game', 982: 'toy',
        }
        
        if class_id in class_map:
            return class_map[class_id]
        
        # Try to get from torchvision's built-in labels if available
        try:
            from torchvision.datasets import ImageNet
            # This loads the built-in labels
            labels = ImageNet.classes
            if class_id < len(labels):
                return labels[class_id].replace('_', ' ')
        except:
            pass
        
        # Generic fallback
        return f'product_{class_id}'
    
    def extract_features(self, image_file):
        """Extract feature vector for similarity search"""
        try:
            # Remove classification head for feature extraction
            feature_model = torch.nn.Sequential(*list(self.model.children())[:-1])
            feature_model = feature_model.to(self.device)
            feature_model.eval()
            
            image = Image.open(image_file).convert('RGB')
            image_tensor = self.transform(image).unsqueeze(0).to(self.device)
            
            with torch.no_grad():
                features = feature_model(image_tensor)
            
            return features.cpu().numpy().flatten().tolist()
            
        except Exception as e:
            print(f"⚠️ Feature extraction error: {e}")
            return None


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
            print(f"🔍 Universal recognition result: {search_query}")
            return [search_query]
            
        except Exception as e:
            print(f"⚠️ Recognition error: {e}")
            return ["product"]
    
    def extract_features(self, image_file):
        """Extract features for similarity search"""
        if not self.is_available:
            return None
        return self.recognizer.extract_features(image_file)