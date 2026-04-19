import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServerDiscovery {
  static const List<int> ports = [8000, 8080];
  static const String testPath = '/api/auth/login/';
  static const Duration timeout = Duration(seconds: 2);

  static Future<String> getServerUrl() async {
    print('🔍 Auto-discovering Django server...');

    // 1. Check saved URL first
    final savedUrl = await _getSavedUrl();
    if (savedUrl != null && await _testConnection(savedUrl)) {
      print('✅ Using saved server: $savedUrl');
      return savedUrl;
    }

    // 2. Try localhost (same device)
    final localhost = await _tryLocalhost();
    if (localhost != null) {
      await _saveUrl(localhost);
      return localhost;
    }

    // 3. Try computer hostname (works on same WiFi)
    final hostname = await _tryHostname();
    if (hostname != null) {
      await _saveUrl(hostname);
      return hostname;
    }

    // 4. Try emulator special addresses
    final emulator = await _tryEmulator();
    if (emulator != null) {
      await _saveUrl(emulator);
      return emulator;
    }

    // 5. Scan network IPs (works on same WiFi)
    final networkIp = await _tryNetworkScan();
    if (networkIp != null) {
      await _saveUrl(networkIp);
      return networkIp;
    }

    // 6. Fallback to localhost
    print('⚠️ Using fallback: http://127.0.0.1:8000');
    return 'http://127.0.0.1:8000';
  }

  static Future<String?> _tryLocalhost() async {
    print('📡 Checking localhost...');
    final urls = [
      'http://127.0.0.1:8000',
      'http://localhost:8000',
    ];
    for (var url in urls) {
      if (await _testConnection(url)) {
        print('✅ Found server on localhost');
        return url;
      }
    }
    return null;
  }

  static Future<String?> _tryHostname() async {
    print('📡 Trying computer hostname...');
    try {
      final computerName = Platform.localHostname;
      print('💻 Computer name: $computerName');

      final hostnames = [
        'http://$computerName:8000',
        'http://$computerName.local:8000',
      ];

      for (var url in hostnames) {
        if (await _testConnection(url)) {
          print('✅ Found server at: $url');
          return url;
        }
      }
    } catch (e) {
      print('Could not get hostname: $e');
    }
    return null;
  }

  // Special for Android Emulator
  static Future<String?> _tryEmulator() async {
    print('📡 Checking emulator addresses...');
    final urls = [
      'http://10.0.2.2:8000', // Android emulator special IP
      'http://10.0.3.2:8000', // Genymotion emulator
      'http://192.168.1.1:8000',
    ];

    for (var url in urls) {
      if (await _testConnection(url)) {
        print('✅ Found server on emulator: $url');
        return url;
      }
    }
    return null;
  }

  static Future<String?> _tryNetworkScan() async {
    print('📡 Scanning network for Django server...');
    final localIp = await _getLocalIp();
    if (localIp == null) return null;

    print('📍 Your local IP: $localIp');
    final parts = localIp.split('.');
    final base = '${parts[0]}.${parts[1]}.${parts[2]}';

    final ips = <String>[];
    ips.add(localIp);
    ips.add('$base.1'); // Gateway
    ips.add('$base.254'); // Common router

    // Add common IP ranges
    for (var i = 1; i <= 10; i++) ips.add('$base.$i');
    for (var i = 100; i <= 110; i++) ips.add('$base.$i');

    for (var ip in ips.toSet()) {
      for (var port in ports) {
        final url = 'http://$ip:$port';
        if (await _testConnection(url)) {
          print('✅ Found Django server at: $url');
          return url;
        }
      }
    }
    return null;
  }

  static Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            return ip;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> _testConnection(String baseUrl) async {
    try {
      final url = Uri.parse('$baseUrl$testPath');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: '{}',
          )
          .timeout(timeout);
      return response.statusCode == 405 || response.statusCode == 400;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    print('💾 Saved server URL: $url');
  }

  static Future<String?> _getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url');
  }

  static Future<void> resetServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_url');
    print('🔄 Server URL reset');
  }
}
