import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../providers/compare_provider.dart';
import '../services/currency_service.dart';

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

  String _formatPrice(double usdPrice, CurrencyService currencyService) {
    final convertedPrice = currencyService.convertPrice(usdPrice);
    final symbol = currencyService.getCurrencySymbol();

    if (currencyService.currentCurrency == Currency.PKR) {
      return '$symbol ${convertedPrice.toStringAsFixed(0)}';
    } else {
      return '$symbol ${convertedPrice.toStringAsFixed(2)}';
    }
  }

  double _getBasePrice() {
    // Daraz.pk shows prices in PKR - convert to USD base
    if (product.source == 'Daraz.pk') {
      return product.price / 278.5;
    }
    // Use priceUsd if available
    if (product.priceUsd != null && product.priceUsd! > 0) {
      return product.priceUsd!;
    }
    // Fallback: assume current price is in USD
    return product.price;
  }

  @override
  Widget build(BuildContext context) {
    final currencyService = Provider.of<CurrencyService>(context);
    final basePrice = _getBasePrice();
    final formattedPrice = _formatPrice(basePrice, currencyService);

    return cardType == CardType.compact
        ? _buildCompactCard(context, formattedPrice, currencyService)
        : _buildDetailedCard(context, formattedPrice, currencyService);
  }

  Widget _buildCompactCard(BuildContext context, String formattedPrice,
      CurrencyService currencyService) {
    final colorScheme = Theme.of(context).colorScheme;
    final basePrice = _getBasePrice();

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (product.source.isNotEmpty)
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
                          product.source,
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                    if (product.rating > 0)
                      Row(
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (currencyService.currentCurrency != Currency.USD &&
                        basePrice > 0)
                      Text(
                        '\$${basePrice.toStringAsFixed(2)} USD',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey,
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

  Widget _buildDetailedCard(BuildContext context, String formattedPrice,
      CurrencyService currencyService) {
    final colorScheme = Theme.of(context).colorScheme;
    final compareProvider =
        Provider.of<CompareProvider>(context, listen: false);
    final isInCompare = compareProvider.isInComparison(product);
    final basePrice = _getBasePrice();

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.source.isNotEmpty)
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
                              product.source,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            if (currencyService.currentCurrency !=
                                    Currency.USD &&
                                basePrice > 0)
                              Text(
                                '\$${basePrice.toStringAsFixed(2)} USD',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    Row(
                      children: [
                        if (product.brand.isNotEmpty)
                          Text(
                            product.brand,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        if (product.brand.isNotEmpty && product.rating > 0)
                          const SizedBox(width: 8),
                        if (product.rating > 0)
                          Row(
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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

  Widget _buildNetworkImage(ColorScheme colorScheme, {required BoxFit fit}) {
    if (product.imageUrl.isEmpty) {
      return _buildNoImage(colorScheme);
    }

    final String imageUrl =
        'https://wsrv.nl/?url=${Uri.encodeComponent(product.imageUrl)}&w=200&h=200&fit=cover&output=jpg';

    return Image.network(
      imageUrl,
      fit: fit,
      headers: const {
        'User-Agent': 'Mozilla/5.0',
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          product.imageUrl,
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

enum CardType {
  compact,
  detailed,
}
