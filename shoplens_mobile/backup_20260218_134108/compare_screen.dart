import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/compare_provider.dart';
import '../widgets/product_card.dart';

class CompareScreen extends StatefulWidget {
  @override
  _CompareScreenState createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Products'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<CompareProvider>(context, listen: false).clearSelection();
            },
            tooltip: 'Clear Selection',
          ),
        ],
      ),
      body: Consumer2<ProductProvider, CompareProvider>(
        builder: (context, productProvider, compareProvider, child) {
          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product 1:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                          SizedBox(height: 4),
                          Text(compareProvider.product1?.name ?? 'Not selected', style: TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Product 2:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                          SizedBox(height: 4),
                          Text(compareProvider.product2?.name ?? 'Not selected', style: TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: compareProvider.product1 != null && compareProvider.product2 != null
                        ? () async {
                            final success = await compareProvider.matchProducts();
                            if (success && compareProvider.matchingResult != null) {
                              _showComparisonResult(context, compareProvider.matchingResult!);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: compareProvider.isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Compare Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              if (compareProvider.error != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        SizedBox(width: 8),
                        Expanded(child: Text(compareProvider.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 14))),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: productProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return GestureDetector(
                            onTap: () {
                              _showProductSelectionDialog(context, product, compareProvider);
                            },
                            child: ProductCard(product: product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProductSelectionDialog(BuildContext context, Product product, CompareProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Product'),
          content: Text('Do you want to set this as Product 1 or Product 2?'),
          actions: [
            TextButton(onPressed: () { provider.setProduct1(product); Navigator.of(context).pop(); }, child: Text('Product 1')),
            TextButton(onPressed: () { provider.setProduct2(product); Navigator.of(context).pop(); }, child: Text('Product 2')),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
          ],
        );
      },
    );
  }

  void _showComparisonResult(BuildContext context, Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              SizedBox(height: 16),
              Text('Comparison Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              _buildResultRow('Similarity Score', '%', Icons.compare_arrows),
              SizedBox(height: 12),
              _buildResultRow('Image Similarity', '%', Icons.image),
              SizedBox(height: 12),
              _buildResultRow('Text Similarity', '%', Icons.text_fields),
              SizedBox(height: 12),
              _buildResultRow('Match Status', result['is_match'] ? 'Match Found' : 'No Match', 
                result['is_match'] ? Icons.check_circle : Icons.cancel,
                color: result['is_match'] ? Colors.green : Colors.red),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.blue.shade100).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color ?? Colors.blue.shade800),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.blue.shade800)),
            ],
          ),
        ),
      ],
    );
  }
}
