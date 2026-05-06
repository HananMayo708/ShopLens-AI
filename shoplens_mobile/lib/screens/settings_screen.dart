import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/currency_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CurrencyService>(
        builder: (context, currencyService, child) {
          return ListView(
            children: [
              _buildSectionHeader('Currency Preference'),
              _buildCurrencyOption(
                context,
                currencyService,
                Currency.PKR,
                'Pakistani Rupee',
                'Rs',
                '₨',
              ),
              _buildCurrencyOption(
                context,
                currencyService,
                Currency.USD,
                'US Dollar',
                '\$',
                'USD',
              ),
              _buildCurrencyOption(
                context,
                currencyService,
                Currency.EUR,
                'Euro',
                '€',
                'EUR',
              ),
              _buildCurrencyOption(
                context,
                currencyService,
                Currency.GBP,
                'British Pound',
                '£',
                'GBP',
              ),
              _buildCurrencyOption(
                context,
                currencyService,
                Currency.AED,
                'UAE Dirham',
                'د.إ',
                'AED',
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('About'),
              ListTile(
                leading: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                title: Text('Version'),
                trailing: Text('2.0.0', style: TextStyle(color: Colors.grey)),
              ),
              ListTile(
                leading: Icon(Icons.copyright, color: AppTheme.primaryColor),
                title: Text('ShopLens AI'),
                trailing: Text('2026', style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    CurrencyService service,
    Currency currency,
    String name,
    String symbol,
    String code,
  ) {
    final isSelected = service.currentCurrency == currency;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          code,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : null,
        onTap: () {
          service.setCurrency(currency);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Currency changed to $name ($symbol)'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
