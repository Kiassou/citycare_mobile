class AppConfig {
  // Ton nouveau lien Render (ton API mondiale)
  static const String _renderUrl = "https://citycare-backend-4r5z.onrender.com";

  static String get baseUrl {
    // Plus besoin de conditions complexes,
    // l'URL Render fonctionne partout (Web, Android, iOS)
    return _renderUrl;
  }
}
