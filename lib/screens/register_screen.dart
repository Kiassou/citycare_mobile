import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  bool _isPasswordVisible = false; // Pour l'icône œil

  // Couleurs CityCare
  final Color primaryBlue = const Color(0xFF1A73B8);
  final Color secondaryGreen = const Color(0xFF4A7C32);

  @override
  void initState() {
    super.initState();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Inscription réussie ! Connectez-vous."),
            backgroundColor: secondaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
        Future.delayed(
          const Duration(seconds: 2),
          () => Navigator.pop(context),
        );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. IMAGE NETTE EN FOND
          // 1. IMAGE DE FOND AVEC OVERLAY SOMBRE
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/citycare.png"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3), // Assombrit l'image de 30%
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // 2. CARTE COMPLÈTE AVEC HEADER À L'INTÉRIEUR
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 100 : 35,
                vertical: 40,
              ),
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : 380),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 50 : 30,
                  isTablet ? 50 : 35,
                  isTablet ? 50 : 30,
                  isTablet ? 35 : 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// HEADER DANS LA CARTE
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                      ).createShader(bounds),
                      child: const Text(
                        "Rejoignez CityCare",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    Text(
                      "Créez votre profil citoyen",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 15),

                    _buildCompactGlassField(
                      controller: nomController,
                      hint: "Nom",
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 16),

                    _buildCompactGlassField(
                      controller: prenomController,
                      hint: "Prénom",
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 16),

                    _buildCompactGlassField(
                      controller: usernameController,
                      hint: "Nom d'utilisateur",
                      icon: Icons.alternate_email_rounded,
                    ),

                    const SizedBox(height: 16),

                    _buildCompactGlassField(
                      controller: telController,
                      hint: "+223 XX XX XX XX",
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 16),

                    _buildCompactGlassField(
                      controller: emailController,
                      hint: "Adresse e-mail",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    /// PASSWORD COMPACT
                    _buildCompactPasswordField(
                      controller: passwordController,
                      hint: "Mot de passe",
                    ),

                    const SizedBox(height: 20),

                    /// BOUTON INSCRIPTION
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: _isButtonEnabled && !_isLoading
                            ? const LinearGradient(
                                colors: [Color(0xFF4A7C32), Color(0xFF356324)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isButtonEnabled && !_isLoading
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4A7C32,
                                  ).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _isButtonEnabled && !_isLoading
                              ? _handleRegister
                              : null,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 10,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "S'INSCRIRE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// RETOUR LOGIN
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "← Retour à la connexion",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A73B8),
                        ),
                      ),
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

  /// CHAMP COMPACT (padding réduit)
  Widget _buildCompactGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 6,
          ),
          isDense: true,
        ),
      ),
    );
  }

  /// PASSWORD COMPACT AVEC ŒIL
  Widget _buildCompactPasswordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color: Colors.white.withOpacity(0.8),
            size: 18,
          ),
          suffixIcon: GestureDetector(
            onTap: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 6,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
