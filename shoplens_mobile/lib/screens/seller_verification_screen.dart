import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class SellerVerificationScreen extends StatefulWidget {
  const SellerVerificationScreen({super.key});

  @override
  State<SellerVerificationScreen> createState() => _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends State<SellerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _brandController = TextEditingController();
  
  File? _businessLicenseImage;
  File? _selfieImage;
  File? _idCardImage;
  File? _logoImage;
  
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _verificationResults;

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        switch(type) {
          case 'license':
            _businessLicenseImage = File(image.path);
            break;
          case 'selfie':
            _selfieImage = File(image.path);
            break;
          case 'id':
            _idCardImage = File(image.path);
            break;
          case 'logo':
            _logoImage = File(image.path);
            break;
        }
      });
    }
  }

  // Submit verification
  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/marketplace/verify/')
      );

      // Add text fields
      request.fields['business_name'] = _businessNameController.text;
      request.fields['brand'] = _brandController.text;

      // Add images
      if (_businessLicenseImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'business_license', 
          _businessLicenseImage!.path
        ));
      }
      if (_selfieImage != null && _idCardImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'selfie', 
          _selfieImage!.path
        ));
        request.files.add(await http.MultipartFile.fromPath(
          'id_card', 
          _idCardImage!.path
        ));
      }
      if (_logoImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'logo', 
          _logoImage!.path
        ));
      }

      // Add token
      final token = await ApiService.getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      setState(() {
        _isLoading = false;
        _verificationResults = jsonResponse;
        _isVerified = jsonResponse['success'] == true;
      });

      if (!_isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['error'] ?? 'Verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Verification'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: _isVerified 
          ? _buildSuccessScreen()
          : _buildVerificationForm(),
    );
  }

  Widget _buildVerificationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify Your Business',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete these steps to become a verified seller',
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 24),
            
            // Business Info
            const Text('Business Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            
            const SizedBox(height: 16),
            
            // Document Upload
            const Text('Business License', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildImageUploader(
              title: 'Upload Business License',
              image: _businessLicenseImage,
              onTap: () => _pickImage(ImageSource.gallery, 'license'),
            ),
            
            const SizedBox(height: 24),
            
            // Identity Verification
            const Text('Identity Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(child: _buildImageUploader(
                  title: 'Selfie',
                  image: _selfieImage,
                  onTap: () => _pickImage(ImageSource.camera, 'selfie'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildImageUploader(
                  title: 'ID Card',
                  image: _idCardImage,
                  onTap: () => _pickImage(ImageSource.gallery, 'id'),
                )),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Brand Verification
            const Text('Brand Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            
            const SizedBox(height: 16),
            
            _buildImageUploader(
              title: 'Upload Brand Logo',
              image: _logoImage,
              onTap: () => _pickImage(ImageSource.gallery, 'logo'),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Verification', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploader({required String title, File? image, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, color: Colors.grey.shade400, size: 30),
                  const SizedBox(height: 4),
                  Text(title, style: TextStyle(color: Colors.grey.shade600)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(image, fit: BoxFit.cover),
              ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final results = _verificationResults?['results'] ?? {};
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            const Text(
              'Verification Successful!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are now a verified seller',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            if (results['document_verified'] == true)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.description, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Document Verified ✓'),
                  ],
                ),
              ),
            if (results['face_verified'] == true)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.face, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Identity Verified ✓'),
                  ],
                ),
              ),
            if (results['logo_verified'] == true)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.branding_watermark, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Brand Verified ✓'),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                minimumSize: const Size(200, 45),
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
