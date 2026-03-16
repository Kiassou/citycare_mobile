import 'dart:convert';
import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:citycare_mobile/screens/all_reports_screen.dart';
import 'package:citycare_mobile/screens/help_center_screen.dart';
import 'package:citycare_mobile/screens/login_screen.dart';
import 'package:citycare_mobile/screens/my_reports_screen.dart';
import 'package:citycare_mobile/screens/new_signalement_screen.dart';
import 'package:citycare_mobile/screens/news_screen.dart';
import 'package:citycare_mobile/screens/notifications_screen.dart';
import 'package:citycare_mobile/screens/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:http/http.dart' as http;

class CitizenHomeScreen extends StatefulWidget {
  final UserModel user;
  const CitizenHomeScreen({super.key, required this.user});

  @override
  _CitizenHomeScreenState createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int unreadNotificationsCount = 0;
  bool isSearchExpanded = false;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

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

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}/api/auth/notifications/${widget.user.id}',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // On filtre pour ne garder que les non-lues
            unreadNotificationsCount = data
                .where((n) => n['is_read'] == 0)
                .length;
          });
        }
      }
    } catch (e) {
      print("Erreur badge: $e");
    }
  }

  final List<Map<String, String>> dailyNews = [
    {
      "image":
          "https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=500",
      "title": "Travaux Avenue Malik : Fin prévue vendredi",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1588880331179-bc9b93a8cb5e?q=80&w=500", 
      "title": "Nouveau parc ouvert dans le quartier Sud",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=500",
      "title": "Collecte de déchets : Nouveaux horaires",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1580582932707-520aed937b7b?q=80&w=500",
      "title": "Marché central : Extension des horaires d'ouverture",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?q=80&w=500",
      "title": "Ecole primaire : Travaux de rénovation terminés",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?q=80&w=500",
      "title": "Campagne de vaccination gratuite au centre de santé",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=500",
      "title": "Rénovation des routes : Quartier ACI 2000 impacté",
    },
  ];


  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < dailyNews.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildNewsSection(),
                  const SizedBox(height: 25),
                  _buildQuickActions(),
                  const SizedBox(height: 25),
                  _buildMyReportsHeader(),
                  _buildMyReportsList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CityCare",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Espace Citoyen",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isSearchExpanded ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        setState(() => isSearchExpanded = !isSearchExpanded),
                  ),
                  // CORRECTION : On passe l'action dans le onTap
                 _buildHeaderIcon(
                    Icons.notifications_none_rounded,
                    unreadNotificationsCount, // On utilise notre variable dynamique
                    () => _showNotifications(),
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(
                    Icons.person_outline,
                    0,
                    () => _showProfileModal(),
                  ),
                ],
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Rechercher...",
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.white70),
                ),
              ),
            ),
            crossFadeState: isSearchExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  widget.user.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour ${widget.user.username} 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Que souhaitez-vous signaler ?",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CORRECTION : Ajout du paramètre onTap
  Widget _buildHeaderIcon(IconData icon, int unreadCount, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior:
            Clip.none, // Permet au badge de déborder légèrement si besoin
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2, // Ajusté pour que le chiffre soit bien visible
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4), // Espace autour du chiffre
                constraints: const BoxConstraints(
                  minWidth: 16, // Largeur minimale pour rester rond
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A73B8),
                    width: 1.5,
                  ), // Rappel de ta couleur primaire
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9
                        ? '9+'
                        : '$unreadCount', // Affiche 9+ si trop de messages
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Actualités du jour",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewsScreen()),
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
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: dailyNews.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(dailyNews[index]["image"]!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(15),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    dailyNews[index]["title"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionCard(
            "Signalements",
            Icons.list_alt_rounded,
            const Color(0xFF1A73B8),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllReportsScreen(user: widget.user),
                ),
              );
            },
          ),
          const SizedBox(width: 15),
          _buildActionCard(
            "Nouveau",
            Icons.add_circle_outline,
            const Color(0xFF4CAF50),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewSignalementScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>> _fetchMyRecentReports() async {
    // On utilise la route qui marche (celle de l'admin)
    final url = "${AppConfig.baseUrl}/api/signalements";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List allData = jsonDecode(response.body);

      // On filtre manuellement pour ne garder que les rapports de Kadi
      // ATTENTION: Vérifie bien si c'est 'user_id' ou 'userId' dans ton JSON
      List kadiReports = allData
          .where((r) => r['user_id'].toString() == widget.user.id.toString())
          .toList();

      return kadiReports;
    } else {
      print("Erreur: ${response.statusCode}");
      return [];
    }
  }

  Widget _buildMyReportsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Mes signalements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
           onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyReportsScreen(user: widget.user),
                ),
              ).then((value) {
                // Cette partie s'exécute quand on revient sur l'accueil
                setState(() {
                  // Cela va relancer le FutureBuilder des 5 récents
                });
              });
            },
            child: const Text("Voir tout"),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsList() {
    return FutureBuilder<List<dynamic>>(
      future: _fetchMyRecentReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Aucun signalement."));
        }

        final reports = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];

            // Intelligence ici :
            IconData icon = _getIconForType(report['type_signalement'] ?? "");
            String timeAgo = _formatTimeAgo(report['date_signalement']);

            // Gestion des couleurs de statut
            Color statusColor;
            switch (report['statut']) {
              case 'resolu':
                statusColor = Colors.green;
                break;
              case 'en_cours':
                statusColor = Colors.orange;
                break;
              default:
                statusColor = Colors.blueGrey;
            }

            return _buildModernReportCard(
              report['titre'],
              report['lieu'],
              report['statut'],
              statusColor,
              icon,
              timeAgo, // On passe notre "Il y a..."
            );
          },
        );
      },
    );
  }

  Widget _buildModernReportCard(
    String title,
    String subtitle,
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // CORRECTION : On utilise widget.user directement, pas besoin de passerUserModel en paramètre
  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF1A73B8),
              child: Text(
                widget.user.prenom[0].toUpperCase(),
                style: const TextStyle(fontSize: 35, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "${widget.user.prenom} ${widget.user.nom}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 30),
            const Text(
              "Mon Espace Citoyen",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C75),
              ),
            ),
            const Divider(),
           _buildSettingsTile(Icons.person_outline, "Mon Profil", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetailScreen(user: widget.user),
                ),
              );
            }),
            _buildSettingsTile(Icons.history, "Mes Signalements", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyReportsScreen(user: widget.user),
                ),
              );
            }),
            _buildSettingsTile(Icons.help_outline, "Centre d'aide", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              );
            }),
            const SizedBox(height: 10),
            // CORRECTION : Suppression du paramètre 'color' inexistant dans _buildSettingsTile
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Déconnexion",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

 void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(currentUser: widget.user),
      ),
    ).then((_) {
      // Cette partie s'exécute quand on revient en arrière
      _fetchUnreadCount();
    });
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A73B8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
