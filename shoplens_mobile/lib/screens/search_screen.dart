import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/search_provider.dart';
import '../widgets/product_card.dart';
import '../services/image_search_service.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  final String? query;

  const SearchScreen({Key? key, this.query}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ImageSearchService _imageSearchService = ImageSearchService();
  bool _isInitialLoad = true;
  bool _isImageSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SearchProvider>(context, listen: false);

      if (widget.query != null && widget.query!.isNotEmpty) {
        _searchController.text = widget.query!;
        provider.searchProducts(widget.query!);
        _isInitialLoad = false;
      } else if (provider.currentQuery != null &&
          provider.currentQuery!.isNotEmpty) {
        _searchController.text = provider.currentQuery!;
        _isInitialLoad = false;
      }

      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a search term',
              style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    _searchFocusNode.unfocus();
    setState(() => _isInitialLoad = false);
    await Provider.of<SearchProvider>(context, listen: false)
        .searchProducts(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    Provider.of<SearchProvider>(context, listen: false).clearResults();
    setState(() => _isInitialLoad = true);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Search by Image',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isImageSearching = true);
                final image = await _imageSearchService.pickImageFromGallery();
                if (image != null) await _performImageSearch(image);
                setState(() => _isImageSearching = false);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Colors.purple),
              ),
              title: Text('Take a Photo',
                  style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isImageSearching = true);
                final image = await _imageSearchService.takePhoto();
                if (image != null) await _performImageSearch(image);
                setState(() => _isImageSearching = false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Professional loading dialog - single clean message
  Future<void> _performImageSearch(XFile image) async {
    try {
      if (!mounted) return;

      // Clean professional loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Finding similar products',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );

      // Read image bytes for preview
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final imageBase64 = 'data:image/jpeg;base64,$base64Image';

      // Call the search service
      debugPrint('Starting image search...');
      final results = await _imageSearchService.searchByImage(image);

      if (!mounted) return;
      Navigator.pop(context);

      // Check for errors
      if (results['success'] == false) {
        _showErrorSnackBar(results['error'] ?? 'Image search failed');
        return;
      }

      // Extract products from the response
      final List<Product> allProducts = [];

      if (results['products'] != null && results['products'] is List) {
        final productsList = results['products'] as List;
        debugPrint('Found ${productsList.length} products in response');

        for (var item in productsList) {
          if (item is Map<String, dynamic>) {
            try {
              allProducts.add(Product.fromJson(item));
            } catch (e) {
              debugPrint('Error parsing product: $e');
            }
          }
        }
      }

      // Get AI detected label
      String? aiLabels = results['ai_detected'] as String?;
      if (aiLabels == null || aiLabels.isEmpty) {
        aiLabels = 'unknown';
      }

      final int total = results['total'] ?? allProducts.length;

      debugPrint(
          'Image search completed: ${allProducts.length} products found');
      debugPrint('AI Detected: $aiLabels');
      debugPrint('Total from API: $total');

      // Update provider with results
      Provider.of<SearchProvider>(context, listen: false)
          .setImageSearchResults(allProducts, aiLabels, imageBase64);

      if (allProducts.isEmpty) {
        _showErrorSnackBar('No products found matching "$aiLabels"');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('Image search error: $e');
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppTheme.primaryColor.withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(Icons.shopping_bag_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search Input
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 52,
                            decoration: BoxDecoration(
                              color: _searchFocusNode.hasFocus
                                  ? AppTheme.surface
                                  : AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _searchFocusNode.hasFocus
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                width: _searchFocusNode.hasFocus ? 1.8 : 1.0,
                              ),
                              boxShadow: _searchFocusNode.hasFocus
                                  ? [
                                      BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.10),
                                          blurRadius: 14)
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search products, brands...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textMuted.withOpacity(0.7),
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Icon(Icons.search_rounded,
                                      color: _searchFocusNode.hasFocus
                                          ? AppTheme.primaryColor
                                          : AppTheme.textMuted,
                                      size: 20),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            size: 18,
                                            color: AppTheme.textMuted),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              onSubmitted: (_) => _performSearch(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _performSearch,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Icon(Icons.search_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap:
                              _isImageSearching ? null : _showImageSourceDialog,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _isImageSearching
                                  ? Colors.grey.shade300
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: _isImageSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Icon(Icons.camera_alt_rounded,
                                    color: AppTheme.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Results / States
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Provider.of<SearchProvider>(context, listen: false)
                          .refreshSearch();
                    },
                    child: Consumer<SearchProvider>(
                      builder: (context, provider, _) {
                        if (_isInitialLoad &&
                            provider.searchResults.isEmpty &&
                            provider.error == null &&
                            provider.currentQuery == null) {
                          return _buildInitialState();
                        }
                        if (provider.isLoading || _isImageSearching) {
                          return _buildLoadingState(provider);
                        }
                        if (provider.error != null) {
                          return _buildErrorState(provider);
                        }
                        if (provider.searchResults.isEmpty) {
                          return _buildEmptyState(provider);
                        }
                        return _buildResultsList(provider);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final suggestions = [
      (
        'Laptops',
        Icons.laptop_rounded,
        AppTheme.primaryColor,
        AppTheme.surfaceAlt
      ),
      (
        'Smartphones',
        Icons.phone_iphone_rounded,
        const Color(0xFF059669),
        const Color(0xFFD1FAE5)
      ),
      (
        'Headphones',
        Icons.headphones_rounded,
        const Color(0xFFD97706),
        const Color(0xFFFEF3C7)
      ),
      (
        'Gaming',
        Icons.sports_esports_rounded,
        const Color(0xFFDC2626),
        const Color(0xFFFEE2E2)
      ),
      (
        'Cameras',
        Icons.camera_rounded,
        const Color(0xFF0891B2),
        const Color(0xFFCFFAFE)
      ),
      (
        'Tablets',
        Icons.tablet_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFEDE9FE)
      ),
    ];

    return FadeIn(
      duration: const Duration(milliseconds: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('AI-Powered Search',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Find any product instantly',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.camera_alt_rounded,
                        color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visual Search',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        Text('Tap the camera icon to search by photo',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('TRENDING CATEGORIES',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.8)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s.$1;
                    _performSearch();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: s.$4,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(s.$2, color: s.$3, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(s.$1,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(SearchProvider provider) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isImageSearching
                  ? 'Finding matching products...'
                  : 'Searching for',
              style:
                  GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
            ),
            if (!_isImageSearching) ...[
              const SizedBox(height: 4),
              Text('"${provider.currentQuery}"',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(SearchProvider provider) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off_rounded,
                    size: 32, color: AppTheme.errorColor),
              ),
              const SizedBox(height: 20),
              Text('Something went wrong',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(provider.error!,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _performSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Try Again',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchProvider provider) {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt, shape: BoxShape.circle),
                child: Icon(Icons.search_off_rounded,
                    size: 32, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              Text('No results found',
                  style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textSecondary),
                  children: [
                    const TextSpan(text: 'No products found for '),
                    TextSpan(
                        text: '"${provider.currentQuery}"',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text('New Search',
                          style: GoogleFonts.poppins(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(SearchProvider provider) {
    return Column(
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                if (provider.searchedImageBase64 != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3)),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(
                            provider.searchedImageBase64!.split(',').last)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textSecondary),
                      children: [
                        const TextSpan(text: 'Found '),
                        TextSpan(
                            text: '${provider.searchResults.length}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor)),
                        const TextSpan(text: ' results'),
                      ],
                    ),
                  ),
                ),
                if (provider.aiDetectedLabels != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.blue]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(provider.aiDetectedLabels!,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: index * 40),
                duration: const Duration(milliseconds: 350),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ProductCard(
                    product: provider.searchResults[index],
                    onTap: () => Navigator.pushNamed(context, '/product',
                        arguments: provider.searchResults[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
