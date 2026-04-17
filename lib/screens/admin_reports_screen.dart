import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/screens/activity_history_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List allReports = [];
  List activities = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Charge les deux sources de données en même temps
  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      print("Rafraîchissement des données...");
      // On lance les deux et on attend qu'ils finissent
      await Future.wait([_fetchReports(), _fetchActivities()]);
    } catch (e) {
      print("Erreur globale lors du rafraîchissement: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print("Chargement terminé. Activités trouvées: ${activities.length}");
      }
    }
  }

  Future<void> _fetchReports() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/admin/reports'),
      );
      if (response.statusCode == 200) {
        List decoded = jsonDecode(response.body);
        
        setState(() => allReports = decoded);
      }
    } catch (e) {
      debugPrint("Erreur reports: $e");
    }
  }

 Future<void> _fetchActivities() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/activities'),
      );

      if (response.statusCode == 200) {
        final List decodedData = jsonDecode(response.body);
        setState(() {
          activities = decodedData;
        });
      } else {
        print("Erreur Serveur: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur fetch: $e");
    }
  }

Future<void> _updateReportStatus(
    Map
    report, // On passe l'objet report entier pour avoir accès à toutes ses infos
    String newStatus,
  ) async {
    final int reportId = report['id'];
    final int userId =
        report['user_id']; // L'ID du citoyen qui recevra la notif

    print("Tentative de mise à jour: ID $reportId, Vers $newStatus");

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/auth/reports/$reportId/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "statut": newStatus,
          "userId": userId,
          "title": "Mise à jour : ${report['type_signalement']}",
          "message":
              "Bonjour, votre signalement concernant '${report['titre']}' à '${report['lieu']}' est désormais passé au statut : ${newStatus.replaceAll('_', ' ').toUpperCase()}.",
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          _refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Statut mis à jour et notification envoyée !"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print("Erreur API: ${response.body}");
      }
    } catch (e) {
      print("Erreur de connexion: $e");
    }
  }

  // --- HELPERS STYLES ---
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    if (status.contains('attente')) return Colors.orange;
    if (status.contains('cours')) return Colors.blue;
    if (status.contains('resolu') || status.contains('Résolu')) {
      return Colors.green;
    }
    return Colors.blueGrey;
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return "--";
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {

    int pendingCount = allReports
        .where((r) => r['statut'] == 'en_attente')
        .length;
    int progressCount = allReports
        .where((r) => r['statut'] == 'en_cours')
        .length;
    int resolvedCount = allReports.where((r) => r['statut'] == 'resolu').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- HEADER CHIC (Style Citizen) ---
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F4C75),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ADMINISTRATION",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                "Signalements",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => isSearching = !isSearching),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSearching ? Icons.close : Icons.search,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isSearching)
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: "Rechercher un dossier...",
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        )
                      else
                        const Text(
                          "Pilotez les interventions de la ville.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- STATS CARDS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Row(
                children: [
                  _buildStatCard(
                    "En attente",
                    pendingCount,
                    Colors.orange,
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    "En cours",
                    progressCount,
                    Colors.blue,
                    Icons.directions_run_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    "Résolus",
                    resolvedCount,
                    Colors.green,
                    Icons.task_alt_rounded,
                  ),
                ],
              ),
            ),
          ),

          // --- SECTION ACTIVITÉS RÉCENTES ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Journal d'activités",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B262C),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityHistoryScreen(activities: activities),
                        ),
                      );
                    },
                    child: const Text("Voir tout"),
                  ),
                ],
              ),
            ),
          ),

          isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : activities.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Aucune action récente"),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ✅ On affiche UNIQUEMENT les activités ici
                      return _buildActivityTile(activities[index]);
                    },
                    // On limite aux 10 dernières activités pour ne pas surcharger
                    childCount: activities.length > 10 ? 10 : activities.length,
                  ),
                ),

          // Espace de sécurité en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ), // Espace en bas
        ],
      ),
    );
  }

  // --- WIDGETS COMPOSANTS ---

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showStatusListModal(label, color),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B262C),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(Map activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getStatusColor(
              activity['description'],
            ).withOpacity(0.1),
            child: Icon(
              Icons.flash_on,
              color: _getStatusColor(activity['description']),
              size: 16,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['report_title'] ?? "Action Admin",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  activity['description'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatFullDate(activity['created_at']),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- MODALS (L'intelligence du Dashboard) ---

  void _showStatusListModal(String title, Color color) {
    String statusKey = title == "En attente"
        ? "en_attente"
        : (title == "En cours" ? "en_cours" : "resolu");
    List filtered = allReports.where((r) => r['statut'] == statusKey).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dossiers $title",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _buildReportListItem(filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportListItem(Map report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        onTap: () => _showDetailsModal(report),
        title: Text(
          report['titre'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(report['lieu'] ?? "Ville"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  void _showDetailsModal(Map report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // On limite la hauteur max à 90% de l'écran pour plus de sécurité
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        // Le SingleChildScrollView permet d'éviter les crashs si le contenu dépasse
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report['titre'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Text("📍 Lieu: ${report['lieu']}"),
              const SizedBox(height: 10),
              Text(
                "📝 Description:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Text(report['description'] ?? "Aucune description."),
              const SizedBox(height: 20),

              // --- CORRECTION IMAGE ICI ---
              if (report['photo_url'] != null)
                SizedBox(
                  height: 200, // On donne une hauteur fixe à l'image
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      "${AppConfig.baseUrl}${report['photo_url']}",
                      fit: BoxFit
                          .cover, // L'image remplira proprement le cadre de 200px
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

              // ----------------------------
              const SizedBox(height: 30),
              if (report['statut'] != 'resolu')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C75),
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      // On détermine le nouveau statut
                      String nextStatus = report['statut'] == 'en_attente'
                          ? 'en_cours'
                          : 'resolu';

                      // On envoie TOUT l'objet report à la fonction
                      _updateReportStatus(report, nextStatus);
                    },
                    icon: const Icon(Icons.update, color: Colors.white),
                    label: Text(
                      report['statut'] == 'en_attente'
                          ? "PRENDRE EN CHARGE"
                          : "MARQUER COMME RÉSOLU",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Retour"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
