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

  // Variables pour les news dynamiques
  List<dynamic> _realNews = [];
  bool _isLoadingNews = true;
  late Future<List<dynamic>> _myReportsFuture; // On stocke le futur ici

  @override
  void initState() {
    super.initState();
    _fetchRealNews();
    _fetchUnreadCount();
    _myReportsFuture = _fetchMyRecentReports();

    // Timer pour le défilement automatique des news
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_realNews.isNotEmpty) {
        if (_currentPage < _realNews.length - 1) {
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
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- LOGIQUE API ---

  Future<void> _fetchRealNews() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/news'),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _realNews = jsonDecode(response.body);
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      print("🔥 Erreur News: $e");
      if (mounted) setState(() => _isLoadingNews = false);
    }
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

  // --- WIDGETS DE LA SECTION NEWS ---
  Widget _buildNewsSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Actualités du jour",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
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
          height: 200, // Légèrement plus haut pour le côté chic
          child: _isLoadingNews
              ? const Center(child: CircularProgressIndicator())
              : _realNews.isEmpty
              ? _buildEmptyNewsCard()
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _realNews.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final news = _realNews[index];

                    // --- LOGIQUE DE L'URL CORRIGÉE ---
                    String rawImageUrl = news['image_url'] ?? "";
                    String finalImageUrl = rawImageUrl.startsWith('http')
                        ? rawImageUrl
                        : "${AppConfig.baseUrl}$rawImageUrl";

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          20,
                        ), // Coins arrondis chics
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image de fond
                            Image.network(
                              finalImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                            // Overlay Gradient pour le texte
                            _buildGradientOverlay(news['title'] ?? "Actualité"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyNewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            "https://images.unsplash.com/photo-1584824486509-112e4181ff6b?q=80&w=500",
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: _buildGradientOverlay(
        "Pas d'actualité aujourd'hui. Repassez plus tard !",
      ),
    );
  }

  Widget _buildGradientOverlay(String title) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(15),
      alignment: Alignment.bottomLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // --- RESTE DU UI ---

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CityCare",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Espace Citoyen",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  _buildHeaderIcon(
                    Icons.notifications_none_rounded,
                    unreadNotificationsCount,
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
          if (isSearchExpanded) _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Container(
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
    );
  }

  Widget _buildHeaderIcon(IconData icon, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A73B8),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : '$count',
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionCard(
            "Signalements",
            'assets/images/signalements.png', // Chemin de l'image
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
            'assets/images/nouveau.png', // Chemin de l'image
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
    String imagePath,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 140, // Hauteur fixe pour que les deux cartes soient égales
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // 1. L'image de fond qui remplit tout
                Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover, // Remplit tout le container
                ),

                // 2. Un calque de dégradé pour assombrir le bas (et rendre le texte lisible)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(
                          0.7,
                        ), // Noir transparent en bas
                      ],
                    ),
                  ),
                ),

                // 3. Le texte positionné en bas
                Positioned(
                  bottom: 15,
                  left: 15,
                  right: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .white, // Texte en blanc car le fond est sombre
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        height: 3,
                        width: 30,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: color, // Petite barre de rappel de la couleur
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SIGNALEMENTS RECENTS ---

  Future<List<dynamic>> _fetchMyRecentReports() async {
    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/signalements"),
    );
    if (response.statusCode == 200) {
      List allData = jsonDecode(response.body);
      return allData
          .where((r) => r['user_id'].toString() == widget.user.id.toString())
          .toList();
    }
    return [];
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyReportsScreen(user: widget.user),
              ),
            ).then((_) => setState(() {})),
            child: const Text("Voir tout"),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReportsList() {
    return FutureBuilder<List<dynamic>>(
      future: _myReportsFuture,
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
          itemCount: reports.length > 3
              ? 3
              : reports.length, // On en affiche max 3 sur l'accueil
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildModernReportCard(
              report['titre'],
              report['lieu'],
              report['statut'],
              report['statut'] == 'resolu'
                  ? Colors.green
                  : (report['statut'] == 'en_cours'
                        ? Colors.orange
                        : Colors.blueGrey),
              _getIconForType(report['type_signalement'] ?? ""),
              _formatTimeAgo(report['date_signalement']),
              false, // or provide actual isTablet value if available
            );
          },
        );
      },
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        // Une petite bordure subtile pour le côté "chic"
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // --- L'icône stylisée (Le focus central) ---
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),

          // --- Infos du signalement ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F4C75),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w400,
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

          // --- Badge de statut & Temps ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge Minimaliste
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'en_attente' ? 'Attente' : status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODALS ET NAVIGATION ---

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
            _buildSettingsTile(
              Icons.person_outline,
              "Mon Profil",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetailScreen(user: widget.user),
                ),
              ),
            ),
            _buildSettingsTile(
              Icons.history,
              "Mes Signalements",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyReportsScreen(user: widget.user),
                ),
              ),
            ),
            _buildSettingsTile(
              Icons.help_outline,
              "Centre d'aide",
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Déconnexion",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
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
      (route) => false,
    );
  }

  void _showNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(currentUser: widget.user),
      ),
    ).then((_) => _fetchUnreadCount());
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A73B8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // --- HELPERS ---
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
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    return "${date.day}/${date.month}/${date.year}";
  }
}
