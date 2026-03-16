import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyReportsScreen extends StatefulWidget {
  final dynamic user;
  const MyReportsScreen({super.key, required this.user});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  Future<List<dynamic>> _fetchAllMyReports() async {
    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/signalements/user/${widget.user.id}"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur de chargement');
    }
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      // Fond gris perle pour faire ressortir les cartes blanches
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Tous mes signalements",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A73B8), // Bleu fixe
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- Header fixe (Description) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: const Color(0xFF1A73B8),
            child: const Text(
              "Consultez l'état de vos signalements et glissez vers la gauche pour en supprimer un.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // --- Corps de la liste ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: const Color(0xFF1A73B8),
              child: FutureBuilder<List<dynamic>>(
                future: _fetchAllMyReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A73B8),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final reports = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 16,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(report['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 25.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onDismissed: (direction) async {
                            final reportId = report['id'];
                            try {
                              final response = await http.delete(
                                Uri.parse(
                                  "${AppConfig.baseUrl}/api/signalements/$reportId",
                                ),
                              );
                              if (response.statusCode == 200) {
                                _showSnackBar(
                                  "Signalement supprimé",
                                  Colors.green,
                                );
                              } else {
                                setState(() {}); // Refresh si erreur
                                _showSnackBar(
                                  "Erreur lors de la suppression",
                                  Colors.red,
                                );
                              }
                            } catch (e) {
                              setState(() {});
                              _showSnackBar("Erreur réseau", Colors.red);
                            }
                          },
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showReportDetails(context, report),
                            child: _buildModernReportCard(
                              report['titre'] ?? "Sans titre",
                              report['lieu'] ?? "Lieu non précisé",
                              report['statut'],
                              _getStatusColor(report['statut']),
                              _getIconForType(report['type_signalement'] ?? ""),
                              _formatTimeAgo(report['date_signalement']),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fonction utilitaire pour les SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- WIDGETS DE SOUTIEN (À réutiliser ou importer) ---

  void _showReportDetails(BuildContext context, dynamic report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.location_on, report['lieu'], Colors.blue),
              _buildInfoRow(
                Icons.category,
                report['type_signalement'],
                Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                "Description",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                report['description'] ?? "Aucune description fournie.",
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 20),
              if (report['photo_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    // On s'assure que l'URL est bien formée
                    "${AppConfig.baseUrl}${report['photo_url']}",
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Si l'image ne charge pas, on affiche un message d'erreur précis
                      print(
                        "❌ Erreur chargement image: ${AppConfig.baseUrl}${report['photo_url']}",
                      );
                      return Container(
                        height: 100,
                        color: Colors.grey,
                        child: const Center(
                          child: Text("Image non disponible sur le serveur"),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildModernReportCard(
    String title,
    String location,
    String status,
    Color statusColor,
    IconData icon,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
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
          Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 15),
          const Text(
            "Vous n'avez aucun signalement",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'resolu':
        return Colors.green;
      case 'en_cours':
        return Colors.orange;
      case 'en_attente':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  // Utilise les fonctions _getIconForType et _formatTimeAgo que nous avons faites avant
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
}
