import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVerified;

  const VerificationButton({
    super.key,
    required this.onTap,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isVerified ? Colors.green : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isVerified ? Icons.verified : Icons.verified_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isVerified ? 'Verified Seller' : 'Become a Verified Seller',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
