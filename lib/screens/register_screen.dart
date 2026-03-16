import 'dart:ui';
import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Contrôleurs
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController telController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // États
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  // Couleurs CityCare
  final Color primaryBlue = const Color(0xFF1A73B8);
  final Color secondaryGreen = const Color(0xFF4A7C32);

  @override
  void initState() {
    super.initState();
    // Ecoute de tous les champs pour valider le formulaire
    List<TextEditingController> controllers = [
      nomController,
      prenomController,
      usernameController,
      telController,
      emailController,
      passwordController,
    ];
    for (var c in controllers) {
      c.addListener(_validateForm);
    }
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled =
          nomController.text.isNotEmpty &&
          prenomController.text.isNotEmpty &&
          usernameController.text.isNotEmpty &&
          telController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  Future<void> _handleRegister() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);

    var url = Uri.parse('${AppConfig.baseUrl}/api/auth/register');

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nom": nomController.text,
          "prenom": prenomController.text,
          "username": usernameController.text,
          "telephone": telController.text,
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Message de succès chic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Inscription réussie ! Connectez-vous."),
            backgroundColor: secondaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // RETOUR AU LOGIN
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        _showError(data["message"] ?? "Erreur lors de l'inscription");
      }
    } catch (e) {
      _showError("Erreur réseau. Vérifiez votre connexion.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fond Image NET
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/citycare.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay dégradé doux
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),

          // 2. Contenu
          SafeArea(
            child: Column(
              children: [
                // Header "Chic & Douce"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        "CITYCARE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: [Shadow(color: primaryBlue, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Créer un profil citoyen",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Carte Inscription
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildChicField(
                                nomController,
                                "Nom",
                                Icons.person_outline,
                              ),
                              _buildChicField(
                                prenomController,
                                "Prénom",
                                Icons.person_outline,
                              ),
                              _buildChicField(
                                usernameController,
                                "Username",
                                Icons.alternate_email,
                              ),
                              _buildChicField(
                                telController,
                                "Téléphone",
                                Icons.phone_android,
                                type: TextInputType.phone,
                              ),
                              _buildChicField(
                                emailController,
                                "Email",
                                Icons.email_outlined,
                                type: TextInputType.emailAddress,
                              ),
                              _buildChicField(
                                passwordController,
                                "Mot de passe",
                                Icons.lock_outline,
                                isPass: true,
                              ),

                              const SizedBox(height: 25),

                              // Bouton Dynamique
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  gradient: _isButtonEnabled && !_isLoading
                                      ? LinearGradient(
                                          colors: [
                                            secondaryGreen,
                                            const Color(0xFF356324),
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                        ),
                                  boxShadow: _isButtonEnabled && !_isLoading
                                      ? [
                                          BoxShadow(
                                            color: secondaryGreen.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
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
                                  onPressed: (_isButtonEnabled && !_isLoading)
                                      ? _handleRegister
                                      : null,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "S'INSCRIRE",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Retour à la connexion",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildChicField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryGreen.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
