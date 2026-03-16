import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  static String get baseUrl {
    // WEB (Chrome)
    if (kIsWeb) {
      return 'http://192.168.88.50:5000';
    }

    // Android (Téléphone ou émulateur)
    if (Platform.isAndroid) {
      return 'http://192.168.88.50:5000';
    }

    // Desktop / iOS
    return 'http://192.168.88.50:5000';
  }
}
