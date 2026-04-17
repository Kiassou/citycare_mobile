
class AppConfig {
  // L'URL de base de ton serveur Render (sans le /api final et sans le port :5000)
  static const String _renderUrl = "https://citycare-backend-4r5z.onrender.com";

  static String get baseUrl {
    // Plus besoin de distinguer Web, Android ou iOS.
    // L'URL Render est universelle et sécurisée (HTTPS).
    return _renderUrl;
  }
}
