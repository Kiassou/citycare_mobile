import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Simulation des actualités
  final List<Map<String, String>> _allNews = [
    {
      "title": "Travaux Avenue du Mali",
      "desc":
          "Une rénovation complète de la chaussée est prévue de lundi à vendredi. Prévoyez des déviations.",
      "date": "Aujourd'hui",
      "category": "TRAVAUX",
      "image": "🚧",
    },
    {
      "title": "Coupure d'eau programmée",
      "desc":
          "Le quartier de l'Hippodrome connaîtra une interruption de service demain matin entre 8h et 12h.",
      "date": "Demain",
      "category": "SERVICE",
      "image": "💧",
    },
    {
      "title": "Inauguration du Parc Vert",
      "desc":
          "Le maire inaugurera le nouvel espace vert ce samedi à 10h. Venez nombreux !",
      "date": "15 Mars",
      "category": "EVENT",
      "image": "🌳",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // --- HEADER DYNAMIQUE AVEC DÉGRADÉ ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: _isSearching ? 20 : 25,
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (!_isSearching)
                          const Text(
                            "Infos & Actualités",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Rechercher une info...",
                        prefixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF1A73B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Restez informés ! 📢",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Retrouvez ici les dernières annonces de la mairie et les travaux en cours dans votre ville.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // --- LISTE DES ACTUALITÉS ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _allNews.length,
              itemBuilder: (context, index) {
                final news = _allNews[index];
                return _buildNewsCard(news);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, String> news) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73B8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    news['image']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news['category']!,
                        style: const TextStyle(
                          color: Color(0xFF1A73B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        news['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F4C75),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  news['date']!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
            child: Text(
              news['desc']!,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
