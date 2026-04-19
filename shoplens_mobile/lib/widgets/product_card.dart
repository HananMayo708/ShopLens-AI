import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../providers/compare_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final CardType cardType;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.cardType = CardType.detailed,
  });

  void _addToCompare(BuildContext context) {
    final compareProvider =
        Provider.of<CompareProvider>(context, listen: false);
    compareProvider.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to compare'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return cardType == CardType.compact
        ? _buildCompactCard(context)
        : _buildDetailedCard(context);
  }

  // 🔹 COMPACT CARD - For home screen
  Widget _buildCompactCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 250,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: colorScheme.primary.withOpacity(0.05),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildNetworkImage(colorScheme, fit: BoxFit.cover),
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Source/Badge
                    if (product.source != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.source!,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Product Name
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Rating
                    if (product.rating != null)
                      Row(
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.rating!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),

                    // Price
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 DETAILED CARD - For search screen
  Widget _buildDetailedCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compareProvider =
        Provider.of<CompareProvider>(context, listen: false);
    final isInCompare = compareProvider.isInComparison(product);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Left side
            Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary.withOpacity(0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildNetworkImage(colorScheme, fit: BoxFit.cover),
              ),
            ),

            // Product Details - Right side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.source != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.source!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Product Name
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Brand and Rating Row
                    Row(
                      children: [
                        if (product.brand != null)
                          Text(
                            product.brand!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        if (product.brand != null && product.rating != null)
                          const SizedBox(width: 8),
                        if (product.rating != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Compare Button
                        IconButton(
                          icon: Icon(
                            isInCompare
                                ? Icons.compare_arrows
                                : Icons.compare_arrows_outlined,
                            size: 20,
                            color:
                                isInCompare ? colorScheme.primary : Colors.grey,
                          ),
                          onPressed: () => _addToCompare(context),
                          tooltip: 'Add to compare',
                        ),

                        // Wishlist Button
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to wishlist'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED IMAGE WIDGET - wsrv.nl proxy (reliable CORS fix for Flutter Web)
  Widget _buildNetworkImage(ColorScheme colorScheme, {required BoxFit fit}) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return _buildNoImage(colorScheme);
    }

    // wsrv.nl is a reliable image CDN proxy that fixes CORS for Flutter Web
    final String imageUrl =
        'https://wsrv.nl/?url=${Uri.encodeComponent(product.imageUrl!)}&w=200&h=200&fit=cover&output=jpg';

    return Image.network(
      imageUrl,
      fit: fit,
      headers: const {
        'User-Agent': 'Mozilla/5.0',
      },
      errorBuilder: (context, error, stackTrace) {
        // If wsrv.nl fails, try loading original URL directly
        return Image.network(
          product.imageUrl!,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildNoImage(colorScheme);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingSpinner(colorScheme, loadingProgress);
          },
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingSpinner(colorScheme, loadingProgress);
      },
    );
  }

  // Loading spinner widget
  Widget _buildLoadingSpinner(
      ColorScheme colorScheme, ImageChunkEvent loadingProgress) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildNoImage(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withOpacity(0.05),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 30,
          color: colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}

// Enum for card types
enum CardType {
  compact, // Vertical layout for home screen
  detailed, // Horizontal layout for search screen
}
