import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Ton IP PC actuelle sur le réseau
  static const String _pcIp = "192.168.88.50";
  static const String _port = "5000";

  static String get baseUrl {
    // Si on est sur un navigateur Web (PC)
    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    // Pour Android (Emulateur ou Physique) et iOS
    // On utilise l'IP locale du PC car 127.0.0.1 ne fonctionne pas sur mobile
    return 'http://$_pcIp:$_port';
  }
}
