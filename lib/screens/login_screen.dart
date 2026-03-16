import 'dart:ui'; // Obligatoire pour BackdropFilter
import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:citycare_mobile/screens/citizen_home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// On transforme en StatefulWidget pour gérer l'état du bouton et du chargement
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables d'état
  bool _isLoading = false; // Pour afficher le spinner
  bool _isButtonEnabled = false; // Pour activer le bouton

  // Couleurs CityCare
  final Color primaryBlue = const Color(0xFF1A73B8);
  final Color secondaryGreen = const Color(0xFF4A7C32);

  @override
  void initState() {
    super.initState();
    // Ecouter les changements dans les champs pour activer le bouton
    usernameController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Vérifie si les deux champs sont remplis
  void _validateForm() {
    setState(() {
      _isButtonEnabled =
          usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  // Fonction de connexion
  Future<void> _handleLogin() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    var url = Uri.parse('${AppConfig.baseUrl}/api/auth/login');

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text,
          "password": passwordController.text,
        }),
      );

      print("STATUS CODE: ${response.statusCode}");

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data["user"]);

        if (user.role == "admin") {
          // Option A : Si tu as défini la route dans main.dart
          Navigator.pushReplacementNamed(
            context,
            "/admin_home",
            arguments: user,
          );

          // Option B (Plus sûre pour le test) : Navigation directe
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminHomeScreen(user: user)));
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CitizenHomeScreen(user: user),
            ),
          );
        }
      }
      // --- NOUVEAU : Gestion des erreurs envoyées par le serveur ---
      else {
        // On récupère le message d'erreur envoyé par ton API (ex: data['message'])
        // Sinon on affiche un message par défaut selon le code HTTP
        String errorMsg = data["message"] ?? "Erreur d'authentification";

        if (response.statusCode == 401) {
          errorMsg = "Mot de passe incorrect";
        } else if (response.statusCode == 404) {
          errorMsg = "Utilisateur introuvable";
        }

        _showErrorSnackBar(errorMsg);
      }
      // -----------------------------------------------------------
    } catch (e) {
      print("ERREUR CONNEXION: $e");
      _showErrorSnackBar("Impossible de joindre le serveur.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pour éviter que le clavier ne pousse tout le contenu de manière moche
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Image de fond NETTE (Même que le Splash pour la cohérence)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/citycare.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay sombre pour le contraste
          Container(color: Colors.black.withOpacity(0.3)),

          // 2. Contenu (Carte transparente)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ClipRRect(
                // Obligatoire pour limiter le flou à la carte
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  // L'effet de verre dépoli (Glassmorphism)
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      // Couleur blanche TRÈS transparente
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),

                        Text(
                          "Bienvenue sur CityCare",

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 25,

                            fontWeight: FontWeight.bold,

                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Connectez-vous pour signaler un incident",

                          style: TextStyle(color: Color.fromARGB(255, 218, 217, 217), fontSize: 14),
                        ),
                        const SizedBox(height: 40),

                        /// CHAMP USERNAME CHIC (Transparent)
                        _buildTransparentTextField(
                          controller: usernameController,
                          hint: "Nom d'utilisateur",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),

                        /// CHAMP PASSWORD CHIC (Transparent)
                        _buildTransparentTextField(
                          controller: passwordController,
                          hint: "Mot de passe",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/forgot"),
                            child: Text(
                              "Mot de passe oublié ?",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        /// BOUTON CONNEXION CHIC ET DYNAMIQUE
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            // Dégradé désactivé si pas cliquable
                            gradient: _isButtonEnabled && !_isLoading
                                ? LinearGradient(
                                    colors: [
                                      primaryBlue,
                                      const Color(0xFF12568A),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.5),
                                      Colors.grey.withOpacity(0.5),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: _isButtonEnabled && !_isLoading
                                ? [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            // La logique cliquable est ici
                            onPressed: (_isButtonEnabled && !_isLoading)
                                ? _handleLogin
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    // Spinner Chic et fin
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "SE CONNECTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// LIEN REGISTER
                        Row(
                           mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Pas encore membre ?",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, "/register"),
                              child: Text(
                                "Créer un compte",
                                style: TextStyle(
                                  color: Colors
                                      .white, // Blanc brillant pour le lien
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour construire les champs de texte transparents 'Chic'
  Widget _buildTransparentTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white), // Texte saisi en blanc
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(
          0.1,
        ), // Fond du champ très légèrement blanc
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.15),
          ), // Bordure subtile
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ), // Plus visible au focus
        ),
      ),
    );
  }
}
