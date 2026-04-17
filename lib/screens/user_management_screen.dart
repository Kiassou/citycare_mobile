import 'dart:async';
import 'dart:convert';
import 'package:citycare_mobile/screens/activity_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = []; 
  List<dynamic> _activities = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // On lance les deux appels en parallèle pour gagner du temps
      final responses = await Future.wait([
        http.get(Uri.parse('${AppConfig.baseUrl}/api/auth/users')),
        http.get(
          Uri.parse('${AppConfig.baseUrl}/api/auth/activities'),
        ), // Nouvelle route
      ]);

      if (mounted &&
          responses[0].statusCode == 200 &&
          responses[1].statusCode == 200) {
        setState(() {
          _users = jsonDecode(responses[0].body);
          _filteredUsers = _users;
          _activities = jsonDecode(responses[1].body); // On remplit la liste
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur de récupération : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 void _filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users; // On réaffiche tout si c'est vide
      } else {
        _filteredUsers = _users.where((user) {
          final nom = user['nom']?.toString().toLowerCase() ?? '';
          final prenom = user['prenom']?.toString().toLowerCase() ?? '';
          final username = user['username']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return nom.contains(searchLower) ||
              prenom.contains(searchLower) ||
              username.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _deleteUser(int id) async {
    try {
      final response = await http.delete(
        // Correction de l'URL ici :
        Uri.parse('${AppConfig.baseUrl}/api/auth/users/$id'),
      );

      if (response.statusCode == 200) {
        // IMPORTANT : On rafraîchit les données AVANT de fermer le modal
        _fetchData();

        if (mounted) {
          Navigator.pop(context); // Fermer le modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Utilisateur supprimé avec succès"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        debugPrint("Erreur API (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("Erreur connexion suppression: $e");
    }
  }

  Future<void> _toggleStatus(dynamic userId, dynamic currentStatus) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/auth/users/toggle-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId, 'currentStatus': currentStatus}),
      );

      if (response.statusCode == 200) {
        // ✅ On rafraîchit la liste pour voir le changement de couleur (Vert <-> Gris)
        _fetchData();

        final newStatusText = (currentStatus == 1 || currentStatus == true)
            ? "compte désactivé"
            : "compte activé";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Succès : $newStatusText"),
            backgroundColor: Colors.blueAccent,
          ),
        );
      } else {
        print("Erreur Status API: ${response.body}");
      }
    } catch (e) {
      print("Erreur de connexion: $e");
    }
  }

  Future<void> _toggleUserRole(Map<String, dynamic> user) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/auth/users/toggle-role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': user['id'], 'currentRole': user['role']}),
      );

      if (response.statusCode == 200) {
        // ✅ Si l'API répond 200, on rafraîchit la liste immédiatement
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rôle de ${user['username']} mis à jour !")),
        );
      } else {
        print("Erreur changement rôle: ${response.body}");
      }
    } catch (e) {
      print("Erreur de connexion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculs basés sur la liste filtrée pour que les stats s'adaptent à la recherche
    int adminCount = _filteredUsers
        .where((u) => u['role'].toString().toLowerCase() == 'admin')
        .length;
    int citizenCount = _filteredUsers
        .where((u) => u['role'].toString().toLowerCase() != 'admin')
        .length;
    int inactiveCount = _filteredUsers
        .where((u) => u['is_active'] == 0 || u['is_active'] == false)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A73B8)),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildAdminHeader(),
                    const SizedBox(
                      height: 20,
                    ), // Espace pour décoller du header
                    _buildStatsGrid(adminCount, citizenCount, inactiveCount),
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 30),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _filterSearch('');
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _filterSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: "Rechercher un nom ou email...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    border: InputBorder.none,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contrôle Citoyen",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Gérez les accès et surveillez l'activité.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int admin, int citizen, int inactive) {
    double _ = MediaQuery.of(context).size.width;
return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          // Breakpoints 🔥
          int crossAxisCount;
          double childAspectRatio;

          if (width < 600) {
            // 📱 Mobile
            crossAxisCount = 2;
            childAspectRatio = 1.2;
          } else if (width < 900) {
            // 📱 Tablette
            crossAxisCount = 3;
            childAspectRatio = 1.3;
          } else if (width < 1200) {
            // 💻 Petit desktop
            crossAxisCount = 4;
            childAspectRatio = 1.4;
          } else {
            // 🖥️ Grand écran
            crossAxisCount = 5;
            childAspectRatio = 1.5;
          }

          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
            children: [
              _buildStatCard(
                "Total",
                "${_filteredUsers.length}",
                Icons.people,
                Colors.blue,
                () => _showUserListModal("Liste Complète", _filteredUsers),
              ),
              _buildStatCard(
                "Admins",
                "$admin",
                Icons.admin_panel_settings,
                Colors.orange,
                () => _showUserListModal(
                  "Admins",
                  _filteredUsers.where((u) => u['role'] == 'admin').toList(),
                ),
              ),
              _buildStatCard(
                "Citoyens",
                "$citizen",
                Icons.group,
                Colors.green,
                () => _showUserListModal(
                  "Citoyens",
                  _filteredUsers.where((u) => u['role'] != 'admin').toList(),
                ),
              ),
              _buildStatCard(
                "Inactifs",
                "$inactive",
                Icons.person_off,
                Colors.red,
                () => _showUserListModal(
                  "Inactifs",
                  _filteredUsers.where((u) => u['is_active'] == 0).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activités récentes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F4C75),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  ActivityHistoryScreen(activities: _activities),
                    ),
                  );
                },
                child: const Text(
                  "Voir plus",
                  style: TextStyle(
                    color: Color(0xFF1A73B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_activities.isEmpty)
            const Center(child: Text("Aucune activité récente"))
          else
            ..._activities.take(10).map((a) => _buildActivityTile(a)),
        ],
      ),
    );
  }

  Widget _buildActivityTile(dynamic activity) {
    // Définition de l'icône et de la couleur selon le type
    IconData iconData = Icons.history;
    Color iconColor = Colors.grey;

    if (activity['type'] == 'report') {
      iconData = Icons.campaign_rounded; // Icône de haut-parleur/alerte
      iconColor = Colors.orangeAccent;
    } else if (activity['type'] == 'work') {
      iconData = Icons.build_circle_rounded; // Icône d'outil
      iconColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cercle de couleur pour l'icône
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 20, color: iconColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'] ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F4C75),
                  ),
                ),
                const SizedBox(height: 4),
                // Petit texte pour la date (optionnel si tu renvoies la date)
                Text(
                  "Il y a quelques instants",
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserListModal(String title, List<dynamic> list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final user = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user['role'] == 'admin'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      child: Text(
                        user['nom'][0],
                        style: TextStyle(
                          color: user['role'] == 'admin'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                    ),
                    title: Text("${user['nom']} ${user['prenom'] ?? ''}"),
                    subtitle: Text(user['email']),
trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. CHANGER LE STATUT (Activer/Désactiver)
                        IconButton(
                          icon: Icon(
                            user['is_active'] == 1
                                ? Icons.check_circle
                                : Icons.block,
                            color: user['is_active'] == 1
                                ? Colors.green
                                : Colors.grey,
                          ),
                          tooltip: user['is_active'] == 1
                              ? "Désactiver"
                              : "Activer",
                          onPressed: () =>
                              _toggleStatus(user['id'], user['is_active'] ?? 1),
                        ),

                        // 2. CHANGER LE RÔLE
                        IconButton(
                          icon: Icon(
                            user['role'] == 'admin'
                                ? Icons.security
                                : Icons.person_outline,
                            color: user['role'] == 'admin'
                                ? Colors.orange
                                : Colors.blueGrey,
                          ),
                          // On remplace le print par l'appel à l'API
                          onPressed: () => _toggleUserRole(user),
                        ),

                        // 3. SUPPRIMER
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(
                            user,
                          ), // Ta fonction de confirmation
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirmation"),
        content: Text(
          "Voulez-vous vraiment supprimer le compte de ${user['nom']} ? Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Ferme le dialogue
              _deleteUser(user['id']); // Lance la suppression
              Navigator.pop(
                context,
              ); // Ferme le modal de liste pour voir l'actualisation
            },
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

}
