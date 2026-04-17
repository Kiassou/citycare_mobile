import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AllReportsScreen extends StatefulWidget {
  final dynamic user;
  const AllReportsScreen({super.key, required this.user});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> {
  List<dynamic> _allReports = [];
  List<dynamic> _filteredReports = [];
  bool _isLoading = true;
  bool _isSearching = false; // Par défaut, la barre est cachée
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Les fonctions _getIconForType et _formatTimeAgo
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'déchets':
      case 'ordures':
        return Icons.delete_outline;
      case 'eau':
      case 'fuite d\'eau':
        return Icons.water_drop;
      case 'électricité':
      case 'éclairage':
        return Icons.lightbulb_outline;
      case 'route':
      case 'nids de poule':
        return Icons.add_road;
      default:
        return Icons.report_problem_outlined;
    }
  }

  String _formatTimeAgo(String dateStr) {
    DateTime date = DateTime.parse(dateStr).toLocal();
    Duration diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    if (diff.inDays < 7) return "Il y a ${diff.inDays} j";
    if (diff.inDays < 30) return "Il y a ${(diff.inDays / 7).floor()} sem";

    return "${date.day}/${date.month}/${date.year}"; // Date classique si trop vieux
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/signalements"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _allReports = jsonDecode(response.body);
          _filteredReports = _allReports;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  void _filterReports(String query) {
    setState(() {
      _filteredReports = _allReports
          .where(
            (r) =>
                r['titre'].toLowerCase().contains(query.toLowerCase()) ||
                r['lieu'].toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // Fonction pour voter (Validation)
  Future<void> _confirmSignalement(int reportId) async {
    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/signalements/validate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"signalement_id": reportId, "user_id": widget.user.id}),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Merci ! Signalement confirmé."),
          backgroundColor: Colors.green,
        ));
      _loadData(); // Rafraîchir les compteurs
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Vous avez déjà confirmé ce signalement."),
          backgroundColor: Colors.orange,
        ));
    }
  }

  @override
@override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // Pas d'AppBar classique car on utilise le Container dégradé avec MediaQuery
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
                // Première ligne : Retour, Titre ou Barre de Recherche
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
                            "Communauté CityCare",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    // Icone Loupe / Fermer
                    IconButton(
                      icon: Icon(
                        _isSearching ? Icons.close : Icons.search,
                        color: Colors.white,
                      ),
                      // Remplace ton onPressed actuel par celui-ci
                      onPressed: () {
                        setState(() {
                          // On utilise ?? false pour dire : "si c'est null, considère que c'est false"
                          _isSearching = !(_isSearching);

                          if (!_isSearching) {
                            _searchController.clear();
                            _filterReports("");
                          }
                        });
                      },
                    ),
                  ],
                ),


                // Contenu changeant : Barre de recherche OU Message de bienvenue
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
                      onChanged: _filterReports,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Rechercher un quartier, un titre...",
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
                          "Agissons ensemble ! 🌍",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Consultez les incidents signalés par vos concitoyens.\nVotre validation aide les autorités à prioriser les interventions.",
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

          // --- LISTE DES SIGNALEMENTS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh:
                        _loadData, // Permet de rafraîchir en glissant vers le bas
                    child: _filteredReports.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(child: Text("Aucun signalement trouvé.")),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filteredReports.length,
                            padding: const EdgeInsets.only(
                              top: 20,
                              left: 15,
                              right: 15,
                              bottom: 20,
                            ),
                            itemBuilder: (context, index) {
                              final report = _filteredReports[index];
                              return _buildCleanReportCard(report);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanReportCard(dynamic report) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showDetailsModal(report),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icone de catégorie stylisée
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73B8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_getIconForType(report['type_signalement']), color: const Color(0xFF1A73B8), size: 28),
                ),
                const SizedBox(width: 16),
                
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['titre'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(report['lieu'], style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Badge de score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        "${report['nb_validations']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Color(0xFFF1F4F8), thickness: 1.5),
            ),
            
            // Footer de la carte
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeAgo(report['date_signalement']),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                ElevatedButton(
                  onPressed: () => _confirmSignalement(report['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73B8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text("Approuver", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showDetailsModal(dynamic report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              report['titre'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Type: ${report['type_signalement']}",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Description:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(report['description'] ?? "Pas de description."),
            const SizedBox(height: 20),
            if (report['photo_url'] != null && report['photo_url'] != "NULL")
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  // CONDITION : Si l'url contient déjà "http", on l'utilise direct, sinon on ajoute le baseUrl
                  report['photo_url'].startsWith('http')
                      ? report['photo_url']
                      : "${AppConfig.baseUrl}${report['photo_url']}",
                  fit: BoxFit.cover,
                  width:
                      double.infinity, // Pour que l'image prenne bien la place
                  height: 200, // Ajuste selon tes besoins
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
