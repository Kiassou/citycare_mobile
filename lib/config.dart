import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConfig {
  static String get baseUrl {
    // Si on est sur le Web (Chrome)
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    // Si on est sur un émulateur Android
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.88.50:5000';
      }
    } catch (e) {
      // Pour éviter les erreurs sur les plateformes qui ne supportent pas Platform.isAndroid
    }

    // Par défaut (iOS, Desktop ou autre)
    return 'http://localhost:5000';
  }
}
