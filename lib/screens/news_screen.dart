import 'dart:convert';
import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allNews = [];
  List<dynamic> _filteredNews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/news'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allNews = data;
            _filteredNews = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNews(String query) {
    setState(() {
      _filteredNews = _allNews
          .where(
            (news) => news['title'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "--/--";
    try {
      DateTime date = DateTime.parse(dateStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return "--/--";
    }
  }

  // --- MODAL DE DÉTAILS AMÉLIORÉ ---
  void _showNewsDetails(dynamic news) {
    final imageUrl = news['image_url'] != null
        ? "${AppConfig.baseUrl}${news['image_url']}"
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barre de fermeture élégante
            Container(
              margin: const EdgeInsets.fromLTRB(0, 20, 0, 15),
              height: 5,
              width: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _heroImagePlaceholder(),
                        ),
                      ),
                    const SizedBox(height: 25),
                    // Badge catégorie amélioré
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        news['category']?.toString().toUpperCase() ?? "INFO",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Titre avec dégradé
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0F4C75), Color(0xFF1A73B8)],
                      ).createShader(bounds),
                      child: Text(
                        news['title'] ?? "",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Date élégante
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 16,
                            color: const Color(0xFF0F4C75),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(news['created_at']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Contenu
                    Text(
                      news['content'] ?? "Aucun contenu disponible.",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey[800],
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(isTablet),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : RefreshIndicator(
                    onRefresh: _fetchNews,
                    color: const Color(0xFF1A73B8),
                    child: _filteredNews.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              isTablet ? 30 : 20,
                              20,
                              30,
                            ),
                            itemCount: _filteredNews.length,
                            itemBuilder: (context, index) =>
                                _buildNewsCard(_filteredNews[index], isTablet),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

 Widget _buildHeader(bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 25,
        right: 25,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre d'outils supérieure (Back et Search)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleIcon(Icons.arrow_back, () => Navigator.pop(context)),
              _buildSimpleIcon(
                _isSearching ? Icons.close : Icons.search,
                () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredNews = _allNews;
                  }
                }),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Titre et Description (Masqués si on recherche pour gagner de la place)
          if (!_isSearching) ...[
            const Text(
              "Actualités de la Ville",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Restez informé sur les travaux, événements et décisions de votre commune en temps réel.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],

          // Champ de recherche
          if (_isSearching)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterNews,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Rechercher une actualité...",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF1A73B8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget utilitaire pour des icônes simples et propres
  Widget _buildSimpleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildNewsCard(dynamic news, bool isTablet) {
    final imageUrl = news['image_url'] != null
        ? "${AppConfig.baseUrl}${news['image_url']}"
        : null;

    return GestureDetector(
      onTap: () => _showNewsDetails(news),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image améliorée avec effet glass
            Hero(
              tag: 'news_${news['id'] ?? news.hashCode}_image',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: isTablet ? 100 : 85,
                  height: isTablet ? 100 : 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _iconPlaceholder(),
                        )
                      : _iconPlaceholder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            // Contenu avec hiérarchie visuelle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge catégorie avec dégradé
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      news['category']?.toString().toUpperCase() ?? "INFO",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Titre avec dégradé subtil
                  Text(
                    news['title'] ?? "",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F4C75),
                      height: 1.3,
                    ),
                    maxLines: isTablet ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Date avec icône améliorée
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(news['created_at']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Flèche animée
            Transform.translate(
              offset: const Offset(5, 0),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.newspaper_outlined,
        color: Color(0xFF1A73B8),
        size: 30,
      ),
    );
  }

  Widget _heroImagePlaceholder() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Icon(Icons.newspaper, color: Colors.white, size: 60),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73B8)),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            "Chargement des actualités...",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching ? "Aucune info trouvée" : "Aucune actualité",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tirez pour actualiser",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
