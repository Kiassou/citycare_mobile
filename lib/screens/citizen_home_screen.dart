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

  @override
  void initState() {
    super.initState();
    _fetchRealNews();
    _fetchUnreadCount();

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
          child: _isLoadingNews
              ? const Center(child: CircularProgressIndicator())
              : _realNews.isEmpty
              ? _buildEmptyNewsCard()
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _realNews.length,
                  onPageChanged: (index) => _currentPage = index,
                  itemBuilder: (context, index) {
                    final news = _realNews[index];
                    final imageUrl = "${AppConfig.baseUrl}${news['image_url']}";
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          onError: (err, stack) => const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      child: _buildGradientOverlay(
                        news['title'] ?? "Actualité",
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
      future: _fetchMyRecentReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text("Aucun signalement."));
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
    if (type.contains('échets')) return Icons.delete_outline;
    if (type.contains('eau')) return Icons.water_drop;
    if (type.contains('électri')) return Icons.lightbulb_outline;
    if (type.contains('route')) return Icons.add_road;
    return Icons.report_problem_outlined;
  }

  String _formatTimeAgo(String dateStr) {
    DateTime date = DateTime.parse(dateStr).toLocal();
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours} h";
    return "${date.day}/${date.month}/${date.year}";
  }
}
