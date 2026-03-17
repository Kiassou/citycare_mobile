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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header dégradé cohérent
          _buildPremiumHeader(isTablet),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: const Color(0xFF1A73B8),
              child: FutureBuilder<List<dynamic>>(
                future: _fetchAllMyReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final reports = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      25,
                      isTablet ? 30 : 25,
                      25,
                      30,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Dismissible(
                          key: Key(report['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: _buildDeleteBackground(),
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
                                  "✅ Signalement supprimé",
                                  Colors.green,
                                );
                              } else {
                                setState(() {});
                                _showSnackBar(
                                  "❌ Erreur lors de la suppression",
                                  Colors.red,
                                );
                              }
                            } catch (e) {
                              setState(() {});
                              _showSnackBar("⚠️ Erreur réseau", Colors.red);
                            }
                          },
                          child: Hero(
                            tag: 'report_${report['id']}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: () => _showReportDetails(context, report),
                              child: _buildModernReportCard(
                                report['titre'] ?? "Sans titre",
                                report['lieu'] ?? "Lieu non précisé",
                                report['statut'],
                                _getStatusColor(report['statut']),
                                _getIconForType(
                                  report['type_signalement'] ?? "",
                                ),
                                _formatTimeAgo(report['date_signalement']),
                                isTablet,
                              ),
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

  Widget _buildPremiumHeader(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        25,
        MediaQuery.of(context).padding.top + 20,
        15,
        15,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barre de navigation
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  "Mes Signalements",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            // Message d'instruction premium
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                "👈 Glissez vers la gauche pour supprimer\nConsultez l'état de vos signalements en temps réel",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
    bool isTablet,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône de statut avec dégradé
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 18 : 20),
          ),
          const SizedBox(width: 20),
          // Contenu principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre avec ShaderMask
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF0F4C75), Color(0xFF1A73B8)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isTablet ? 15 : 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                // Lieu avec icône stylée
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF1A73B8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Statut et temps
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge statut premium
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.red],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 25),
      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
    );
  }

  void _showReportDetails(BuildContext context, dynamic report) {
    final photoUrl = report['photo_url'] != null
        ? "${AppConfig.baseUrl}${report['photo_url']}"
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Barre de fermeture gradient
            Container(
              margin: const EdgeInsets.fromLTRB(0, 25, 0, 20),
              height: 5,
              width: 70,
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
                    // Titre avec dégradé
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0F4C75), Color(0xFF1A73B8)],
                      ).createShader(bounds),
                      child: Text(
                        report['titre'],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Infos avec icônes stylées
                    _buildInfoRow(
                      Icons.location_on,
                      "Lieu: ${report['lieu']}",
                      const Color(0xFF1A73B8),
                    ),
                    _buildInfoRow(
                      Icons.category,
                      "Type: ${report['type_signalement']}",
                      Colors.orange,
                    ),
                    _buildInfoRow(
                      Icons.schedule,
                      "Date: ${_formatTimeAgo(report['date_signalement'])}",
                      Colors.purple,
                    ),
                    const SizedBox(height: 30),
                    // Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            report['description'] ??
                                "Aucune description fournie.",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.grey[800],
                              height: 1.7,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (photoUrl != null) ...[
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          photoUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(15),
      ),
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
            "Chargement de vos signalements...",
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
          Icon(Icons.assignment_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 30),
          Text(
            "Aucun signalement",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Créez votre premier signalement pour commencer !",
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
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
        return const Color(0xFF1A73B8);
      default:
        return const Color(0xFF1A73B8);
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'déchets':
      case 'ordures':
        return Icons.delete_outline;
      case 'eau':
      case "fuite d'eau":
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
    return "${date.day}/${date.month}/${date.year}";
  }
}
