import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../providers/compare_provider.dart';
import '../theme/app_theme.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CompareProvider>(context, listen: false);
      provider.loadProductsForComparison();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _proxyUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}&w=200&h=200&fit=cover&output=jpg';
  }

  Widget _buildImage({required String? imageUrl, required double size}) {
    if (imageUrl == null || imageUrl.isEmpty) return _buildNoImage(size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        _proxyUrl(imageUrl),
        height: size,
        width: size,
        fit: BoxFit.cover,
        headers: const {'User-Agent': 'Mozilla/5.0'},
        errorBuilder: (context, error, stack) => Image.network(
          imageUrl,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildNoImage(size),
          loadingBuilder: _buildLoadingIndicator,
        ),
        loadingBuilder: _buildLoadingIndicator,
      ),
    );
  }

  Widget _buildNoImage(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.image_not_supported,
          color: Colors.grey.shade400, size: size * 0.4),
    );
  }

  Widget _buildLoadingIndicator(
      BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Compare Products',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Group Comparison'),
            Tab(text: 'Side by Side'),
          ],
        ),
      ),
      body: Consumer<CompareProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGroupComparison(provider),
              _buildSideBySideComparison(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupComparison(CompareProvider provider) {
    final groups = provider.filterGroupsBySearch(_searchQuery);
    if (groups.isEmpty) return _buildEmptyState(provider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: GoogleFonts.poppins(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        _buildStatsBar(provider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final entry = groups.entries.elementAt(index);
              return _buildProductGroup(entry.key, entry.value, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar(CompareProvider provider) {
    final stats = provider.getStats();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              '${stats['totalGroups']}', 'Products', Icons.inventory_2_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem(
              '${stats['uniqueStores']}', 'Stores', Icons.store_rounded),
          Container(width: 1, height: 30, color: Colors.grey.shade200),
          _buildStatItem('${stats['totalProducts']}', 'Listings',
              Icons.shopping_bag_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
        Text(label,
            style:
                GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildProductGroup(
      String groupName, List<Product> products, CompareProvider provider) {
    final bestImageProduct = provider.getBestImageProduct(products);
    final priceRange = provider.getPriceRangeForGroup(products);
    final displayProducts = products.take(3).toList();
    final extraCount = products.length - 3;
    final cheapest = products.reduce((a, b) => a.price < b.price ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImage(imageUrl: bestImageProduct?.imageUrl, size: 80),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '\$${priceRange['min']?.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor),
                          ),
                          Text(
                            ' – \$${priceRange['max']?.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_rounded,
                                    size: 11, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'On ${products.length} platform${products.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_offer_rounded,
                                    size: 11, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Best: ${cheapest.source ?? 'Unknown'}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Available Platforms',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5),
            ),
          ),
          ...displayProducts
              .map(
                  (product) => _buildStorePriceRow(product, provider, cheapest))
              .toList(),
          if (extraCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                '+ $extraCount more platform${extraCount > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500),
              ),
            ),
          if (extraCount <= 0) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStorePriceRow(
      Product product, CompareProvider provider, Product cheapest) {
    final badgeColor = provider.getSellerBadgeColor(product);
    final isVerified = provider.isSellerVerified(product);
    final isCheapest = product.id == cheapest.id;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCheapest
              ? AppTheme.primaryColor.withOpacity(0.04)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCheapest
                ? AppTheme.primaryColor.withOpacity(0.2)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.store_rounded, size: 18, color: badgeColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.source ?? 'Unknown Store',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isVerified
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        size: 13,
                        color: badgeColor,
                      ),
                    ],
                  ),
                  if (isVerified)
                    Text(
                      'Verified Seller',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCheapest ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
                if (isCheapest)
                  Text(
                    'Best Price',
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideComparison(CompareProvider provider) {
    if (provider.allProducts.isEmpty) return _buildEmptyState(provider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeatureColumn(),
            ...provider.allProducts
                .take(20)
                .map((product) =>
                    _buildProductComparisonColumn(product, provider))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureColumn() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          _buildFeatureRow('Price'),
          _buildFeatureRow('Seller'),
          _buildFeatureRow('Status'),
          _buildFeatureRow('Trust Score'),
          _buildFeatureRow('Rating'),
          _buildFeatureRow('Returns'),
          _buildFeatureRow('Shipping'),
          _buildFeatureRow('Years Active'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600)),
    );
  }

  Widget _buildProductComparisonColumn(
      Product product, CompareProvider provider) {
    final badgeColor = provider.getSellerBadgeColor(product);
    final isVerified = provider.isSellerVerified(product);
    final trustScore = provider.getTrustScore(product);
    final returnsPolicy = provider.getReturnsPolicy(product);
    final shippingSpeed = provider.getShippingSpeed(product);

    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildImage(imageUrl: product.imageUrl, size: 90),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor),
          ),
          const Divider(height: 20),
          Text(
            product.source ?? 'Unknown',
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 20),
          _buildInfoRow('$trustScore/100', Icons.shield_rounded,
              trustScore > 80 ? Colors.green : Colors.orange),
          const Divider(height: 10),
          _buildRatingRow(product.rating),
          const Divider(height: 10),
          _buildInfoRow(returnsPolicy, Icons.autorenew_rounded, Colors.green),
          const Divider(height: 10),
          _buildInfoRow(
              shippingSpeed, Icons.local_shipping_rounded, Colors.blue),
          const Divider(height: 10),
          _buildInfoRow(
              '${provider.getSellerVerification(product)['yearsInBusiness']} yrs',
              Icons.history_rounded,
              Colors.purple),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/product', arguments: product),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('View',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(double? rating) {
    if (rating == null) {
      return Text('No rating',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style:
                GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfoRow(String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style:
                GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CompareProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows_rounded,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No products to compare',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
              provider.error ??
                  'Products from multiple stores will appear here',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => provider.loadProductsForComparison(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text('Load Products',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

