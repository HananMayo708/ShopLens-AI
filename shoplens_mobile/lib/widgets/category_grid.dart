import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedCategory;
  final Function(int) onCategorySelected;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == index;
          return GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (category['color'] as Color).withOpacity(0.2)
                          : colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? category['color'] as Color
                            : colorScheme.outline.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected
                          ? category['color'] as Color
                          : colorScheme.onSurface.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? category['color'] as Color
                          : colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
