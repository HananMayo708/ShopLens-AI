import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Currency { PKR, USD, EUR, GBP, AED }

class CurrencyService extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  static const String _rateKey = 'exchange_rates';

  Currency _currentCurrency = Currency.PKR;
  Map<String, double> _exchangeRates = {};
  bool _isLoading = true;

  Currency get currentCurrency => _currentCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoading => _isLoading;

  CurrencyService() {
    _loadSavedCurrency();
    _fetchExchangeRates();
  }

  void _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_currencyKey);
    if (savedCurrency != null) {
      _currentCurrency = Currency.values.firstWhere(
        (e) => e.toString() == savedCurrency,
        orElse: () => Currency.PKR,
      );
    }
    notifyListeners();
  }

  Future<void> _fetchExchangeRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Base rates from USD
      _exchangeRates = {
        'USD': 1.0,
        'PKR': 278.5, // Update with live API
        'EUR': 0.92,
        'GBP': 0.79,
        'AED': 3.67,
      };

      // Optional: Fetch live rates from API
      // final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _exchangeRates['PKR'] = data['rates']['PKR'];
      //   _exchangeRates['EUR'] = data['rates']['EUR'];
      //   _exchangeRates['GBP'] = data['rates']['GBP'];
      //   _exchangeRates['AED'] = data['rates']['AED'];
      // }
    } catch (e) {
      print('Failed to fetch exchange rates: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setCurrency(Currency currency) async {
    _currentCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_currencyKey, currency.toString());
    notifyListeners();
  }

  double convertPrice(double usdPrice) {
    if (usdPrice <= 0) return 0;

    switch (_currentCurrency) {
      case Currency.PKR:
        return usdPrice * (_exchangeRates['PKR'] ?? 278.5);
      case Currency.EUR:
        return usdPrice * (_exchangeRates['EUR'] ?? 0.92);
      case Currency.GBP:
        return usdPrice * (_exchangeRates['GBP'] ?? 0.79);
      case Currency.AED:
        return usdPrice * (_exchangeRates['AED'] ?? 3.67);
      case Currency.USD:
      default:
        return usdPrice;
    }
  }

  String getCurrencySymbol() {
    switch (_currentCurrency) {
      case Currency.PKR:
        return 'Rs';
      case Currency.USD:
        return '\$';
      case Currency.EUR:
        return '€';
      case Currency.GBP:
        return '£';
      case Currency.AED:
        return 'د.إ';
    }
  }

  String formatPrice(double usdPrice) {
    final convertedPrice = convertPrice(usdPrice);
    final symbol = getCurrencySymbol();

    // Format based on currency
    if (_currentCurrency == Currency.PKR) {
      return '$symbol ${convertedPrice.toStringAsFixed(0)}';
    } else {
      return '$symbol ${convertedPrice.toStringAsFixed(2)}';
    }
  }
}
