import 'dart:convert';
import 'package:citycare_mobile/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class AppStatisticsScreen extends StatefulWidget {
  const AppStatisticsScreen({super.key});

  @override
  State<AppStatisticsScreen> createState() => _AppStatisticsScreenState();
}

class _AppStatisticsScreenState extends State<AppStatisticsScreen> {
  // --- ÉTATS ET DONNÉES ---
  bool _isLoading = false;
  List<FlSpot> reportSpots = [];
  List<BarChartGroupData> maintenanceGroups = [];
  List<PieChartSectionData> pieSections = [];

  @override
  void initState() {
    super.initState();
    _fetchAllStats();
  }

  // Fonction pour tout charger en une fois
  Future<void> _fetchAllStats() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchReportStats(),
        _fetchCategoryStats(),
        _fetchMaintenanceStats(),
      ]);
    } catch (e) {
      debugPrint("Erreur lors du chargement global : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- APPELS API ---

  Future<void> _fetchReportStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/stats/reports'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        print("Stats Reports Reçues: ${data.length} items");
        setState(() {
          reportSpots = data.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), (e.value['count'] ?? 0).toDouble());
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur reports: $e");
    }
  }

  Future<void> _fetchCategoryStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/stats/categories'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        print("Stats Categories Reçues: ${data.length} items");
        List<Color> colors = [
          Colors.blue,
          Colors.orange,
          Colors.red,
          Colors.green,
          Colors.purple,
        ];
        setState(() {
          pieSections = data.asMap().entries.map((e) {
            double val = (e.value['count'] ?? 0).toDouble();
            return PieChartSectionData(
              color: colors[e.key % colors.length],
              value: val,
              title: val.toInt().toString(),
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur categories: $e");
    }
  }

  Future<void> _fetchMaintenanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/stats/maintenance'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        print("Stats Maintenance Reçues: ${data.length} items");
        setState(() {
          maintenanceGroups = data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (e.value['total'] ?? 0).toDouble(),
                  color: const Color(0xFF3282B8),
                  width: 10,
                ),
                BarChartRodData(
                  toY: (e.value['resolved'] ?? 0).toDouble(),
                  color: const Color(0xFF27AE60),
                  width: 10,
                ),
              ],
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur maintenance: $e");
    }
  }

  // --- WIDGETS DE GRAPHIQUES ---

  Widget _buildAdminChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1),
              const FlSpot(2, 4),
              const FlSpot(4, 2),
              const FlSpot(6, 5),
            ],
            isCurved: true,
            color: const Color(0xFF0F4C75),
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0F4C75).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenPieChart() {
    if (pieSections.isEmpty)
      return const Center(child: Text("Aucune donnée disponible"));
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 40,
        sections: pieSections,
      ),
    );
  }

  Widget _buildReportLineChart() {
    if (reportSpots.isEmpty)
      return const Center(child: Text("Pas de données disponibles"));
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: reportSpots,
            isCurved: true,
            color: Colors.orange,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemBarChart() {
    if (maintenanceGroups.isEmpty)
      return const Center(child: Text("Aucune donnée disponible"));
    return BarChart(
      BarChartData(
        barGroups: maintenanceGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  // --- COMPOSANTS UI ---

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 20,
        bottom: 25,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "CityCare Analytics",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "STATISTIQUES ET ÉVOLUTION DES DONNÉES",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatModal(String title, Widget chart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C75),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(10), child: chart),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchAllStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Analyses Globales",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B262C),
                      ),
                    ),
                    Text(
                      "Données synchronisées en temps réel",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildStatCard(
                            "Admin",
                            Icons.admin_panel_settings_rounded,
                            Colors.blue.shade800,
                            "Flux gestion",
                            () => _showStatModal(
                              "Activité Administrative",
                              _buildAdminChart(),
                            ),
                          ),
                          _buildStatCard(
                            "Répartition",
                            Icons.pie_chart_rounded,
                            Colors.green.shade600,
                            "Par catégorie",
                            () => _showStatModal(
                              "Répartition Signalements",
                              _buildCitizenPieChart(),
                            ),
                          ),
                          _buildStatCard(
                            "Évolution",
                            Icons.analytics_rounded,
                            Colors.orange.shade700,
                            "Signalements/jour",
                            () => _showStatModal(
                              "Évolution Temporelle",
                              _buildReportLineChart(),
                            ),
                          ),
                          _buildStatCard(
                            "Maintenance",
                            Icons.build_circle_rounded,
                            Colors.blueGrey,
                            "Taux résolution",
                            () => _showStatModal(
                              "Performance Maintenance",
                              _buildSystemBarChart(),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
