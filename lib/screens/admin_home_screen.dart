import 'dart:async';
import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:citycare_mobile/screens/admin_reports_screen.dart';
import 'package:citycare_mobile/screens/app_statistics_screen.dart';
import 'package:citycare_mobile/screens/manage_news_screen.dart';
import 'package:citycare_mobile/screens/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminHomeScreen extends StatefulWidget {
  final UserModel user; // Reçu du login
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int totalReports = 0;
  int totalCitizens = 0;
  int totalEmergencies = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  // Récupération des données réelles
  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/admin/stats'),
      );

      print("🔹 Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalReports = (data['totalReports'] ?? 0).toInt();
          totalCitizens = (data['totalCitizens'] ?? 0).toInt();
          totalEmergencies = (data['totalEmergencies'] ?? 0).toInt();
          _isLoading = false;
        });

        print(
          "✅ Stats mises à jour : $totalReports Rapports, $totalCitizens Citoyens, $totalEmergencies Urgences",
        );
      } else {
        print("⚠️ Erreur API Status: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("🔥 Erreur Connexion: $e");
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    // Nettoyer la session si nécessaire et retourner au login
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFD,
      ), // Un gris bleuté très clair et propre
      body: Column(
        children: [
          // --- HEADER ADMIN PREMIUM ---
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C75), Color(0xFF3282B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F4C75).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                // --- HEADER TEXT & PROFILE ICON ---
                const Text(
                  "CityCare",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "ESPACE ADMINISTRATION",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Bonjour ${widget.user.username} 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ), // Espacement pour la description
                          Text(
                            "Gérez les signalements et suivez l'activité de la ville en temps réel.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Petit bouton profil chic à droite
                    GestureDetector(
                      onTap: () => _showAdminProfile(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),

          // --- SECTION ACTIONS ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F4C75)),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SECTION STATS AVEC IMAGES ---
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildQuickStat(
                              "Signalements",
                              totalReports.toString(),
                              Icons.whatshot_rounded,
                              "https://images.unsplash.com/photo-1582139329536-e7284fece509?w=200",
                              const Color(0xFFE67E22),
                            ),
                            _buildQuickStat(
                              "Citoyens",
                              totalCitizens.toString(),
                              Icons.people_alt_rounded,
                              "https://images.unsplash.com/photo-1517486808906-6ca8b3f04846?w=200",
                              const Color(0xFF27AE60),
                            ),
                            _buildQuickStat(
                              "Urgences",
                              totalEmergencies.toString(),
                              Icons.warning_amber_rounded,
                              "https://images.unsplash.com/photo-1530260626688-0482ed938961?w=200",
                              const Color(0xFFC0392B),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --- TITRE CHIC AVEC DESCRIPTION ---
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F4C75),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Gestion municipale",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B262C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            "Pilotez les services de la ville et interagissez avec les citoyens.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- GRILLE D'ACTIONS ---
                        Expanded(
                          child: GridView.count(
                            physics:
                                const BouncingScrollPhysics(), // Pour un effet de défilement iOS fluide
                            padding: const EdgeInsets.only(bottom: 20),
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.1,
                            children: [
                              _buildMenuCard(
                                context,
                                "Signalements",
                                Icons.location_on_rounded,
                                Colors.orange,
                                "Voir les alertes",
                              ),
                              _buildMenuCard(
                                context,
                                "Actualités",
                                Icons.campaign_rounded,
                                Colors.blue,
                                "Informer la ville",
                              ),
                              _buildMenuCard(
                                context,
                                "Utilisateurs",
                                Icons.people_alt_rounded,
                                Colors.green,
                                "Modérer la base",
                              ),
                              _buildMenuCard(
                                context,
                                "Statistiques",
                                Icons.analytics_rounded, 
                                Colors.blueGrey, 
                                "Analyses Globales",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET STATS REVISITÉ ---

  // Popup Infos Admin
  void _showAdminProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Nécessaire pour l'arrondi personnalisé
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de tirage grise en haut
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),

            // Avatar de l'Admin
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF0F4C75).withOpacity(0.1),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: Color(0xFF0F4C75),
              ),
            ),
            const SizedBox(height: 15),

            Text(
              "${widget.user.prenom} ${widget.user.nom}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "@${widget.user.username}",
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 25),
            const Divider(thickness: 1),

            // Détails de l'utilisateur
            _buildInfoTile(Icons.email_outlined, "Email", widget.user.email),
            _buildInfoTile(
              Icons.phone_android_outlined,
              "Téléphone",
              widget.user.telephone,
            ),
            _buildInfoTile(
              Icons.verified_user_outlined,
              "Statut du compte",
              widget.user.role.toUpperCase(),
              isPrimary: true,
            ),

            const SizedBox(height: 30),

            // Bouton Déconnexion Chic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Ferme le modal
                  _handleLogout(); // Ta fonction de déconnexion
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "SE DÉCONNECTER",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget d'aide pour les lignes d'info
  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    bool isPrimary = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A73B8), size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isPrimary ? Colors.blue[800] : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    String imagePath,
    Color accentColor,
  ) {
    return Expanded(
      child: Container(
        height: 100, // Hauteur fixe pour l'harmonie
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 1. Image de fond (tu peux utiliser des images Network ou Assets)
              Positioned.fill(
                child: Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: accentColor.withOpacity(0.8)),
                ),
              ),
              // 2. Filtre de dégradé pour que le texte ressorte
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.9),
                        accentColor.withOpacity(0.4),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // 3. Contenu (Icon + Chiffre + Label)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const Spacer(),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String desc,
  ) {
    return InkWell(
      onTap: () {
        if (title == "Signalements") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminReportsScreen()),
          );
        }
        if (title == "Actualités") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageNewsScreen()),
          );
        }
        if (title == "Utilisateurs") {
          _showSecurePinGate(context);
        }
        if (title == "Statistiques") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AppStatisticsScreen()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurePinGate(BuildContext context) {
    int attempts = 0;
    bool isLocked = false;
    int secondsRemaining = 30;
    // ignore: unused_local_variable
    Timer? lockTimer;
    final controller = TextEditingController();
    
    // On capture le Navigator ici pour qu'il reste stable
    final rootNavigator = Navigator.of(context);

    // Couleurs de la charte CityCare
    const primaryColor = Color(0xFF1B262C); // Dark Navy
    const accentColor = Color(0xFF0F4C75); // Deep Blue
    const dangerColor = Color(0xFFE74C3C); // Soft Red

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          void verifyPin(String pin) {
            if (pin.length == 4) {
              if (pin == "2026") {
                Navigator.pop(context); // Ferme le dialogue PIN

                _showStatusModal(
                  context,
                  isSuccess: true,
                  onFinished: () {
                    // Utilisation de rootNavigator pour la redirection
                    rootNavigator.push(
                      MaterialPageRoute(
                        builder: (context) => UserManagementScreen(),
                      ),
                    );
                  },
                );
              } else {
                attempts++;
                controller.clear();
                if (attempts >= 3) {
                  setModalState(() {
                    isLocked = true;
                    secondsRemaining = 30;
                  });

                  lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    setModalState(() {
                      if (secondsRemaining > 0) {
                        secondsRemaining--;
                      } else {
                        isLocked = false;
                        attempts = 0;
                        timer.cancel();
                      }
                    });
                  });
                } else {
                  _showStatusModal(context, isSuccess: false);
                }
              }
            }
          }

          return PopScope(
            canPop: !isLocked,
            child: AlertDialog(
              backgroundColor: Colors.white,
              elevation: 20,
              shadowColor: Colors.black45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isLocked
                            ? [dangerColor, const Color(0xFFC0392B)]
                            : [primaryColor, accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isLocked
                              ? Icons.lock_clock_rounded
                              : Icons.admin_panel_settings_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Text(
                          isLocked ? "SÉCURITÉ ACTIVÉE" : "ESPACE ADMINISTRATION",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLocked
                              ? "Trop de tentatives. Veuillez patienter."
                              : "Veuillez saisir votre code d'accès.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (isLocked) ...[
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 80,
                                width: 80,
                                child: CircularProgressIndicator(
                                  value: secondsRemaining / 30,
                                  strokeWidth: 8,
                                  color: dangerColor,
                                  backgroundColor: dangerColor.withOpacity(0.1),
                                ),
                              ),
                              Text(
                                "$secondsRemaining",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: dangerColor,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: 180,
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7F6),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: TextField(
                              controller: controller,
                              obscureText: true,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 4,
                              onChanged: verifyPin,
                              style: const TextStyle(
                                fontSize: 32,
                                letterSpacing: 20,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                hintText: "****",
                                hintStyle: TextStyle(color: Colors.black12),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        if (!isLocked)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "RETOUR",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStatusModal(
    BuildContext context, {
    required bool isSuccess,
    VoidCallback? onFinished,
  }) {
    const primaryColor = Color(0xFF1B262C);
    const successColor = Color(0xFF27AE60);
    const dangerColor = Color(0xFFE74C3C);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (Navigator.canPop(modalContext)) {
            Navigator.pop(modalContext);
            if (onFinished != null) {
              // On lance le callback juste après la fermeture
              Future.microtask(() => onFinished());
            }
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
              margin: const EdgeInsets.symmetric(horizontal: 50),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: (isSuccess ? successColor : dangerColor).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle_rounded : Icons.gpp_bad_rounded,
                      color: isSuccess ? successColor : dangerColor,
                      size: 65,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isSuccess ? "ACCÈS AUTORISÉ" : "CODE INCORRECT",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSuccess ? "Bienvenue dans l'espace gestion" : "Veuillez réessayer",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}
