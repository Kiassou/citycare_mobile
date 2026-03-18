import 'dart:ui';
import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:citycare_mobile/screens/citizen_home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isButtonEnabled = false;
  bool _isPasswordVisible = false;

  final Color primaryBlue = const Color(0xFF1A73B8);
  final Color secondaryGreen = const Color(0xFF4A7C32);

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_validateForm);
    passwordController.addListener(_validateForm);
    _isPasswordVisible = false;
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled =
          usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  Future<void> _handleLogin() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);

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
          Navigator.pushReplacementNamed(
            context,
            "/admin_home",
            arguments: user,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CitizenHomeScreen(user: user),
            ),
          );
        }
      } else {
        String errorMsg = data["message"] ?? "Erreur d'authentification";
        if (response.statusCode == 401)
          errorMsg = "Mot de passe incorrect";
        else if (response.statusCode == 404)
          errorMsg = "Utilisateur introuvable";

        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      print("ERREUR CONNEXION: $e");
      _showErrorSnackBar("Impossible de joindre le serveur.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
          // 1. IMAGE NETTE EN FOND (PAS DE FLou)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/citycare.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. CARTE TRANSPARENTE CITYCARE (Glassmorphism)
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 80 : 35,
                vertical: 60,
              ),
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: isTablet ? 450 : 380),
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
                padding: EdgeInsets.fromLTRB(35, isTablet ? 50 : 40, 35, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// TITRE GRADIENT BLEU
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                      ).createShader(bounds),
                      child: const Text(
                        "Bienvenue sur CityCare",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// DESCRIPTION
                    Text(
                      "Connectez-vous pour signaler les incidents\net contribuer à une ville plus sûre",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// USERNAME FIELD
                    _buildGlassTextField(
                      controller: usernameController,
                      hint: "Nom d'utilisateur",
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD FIELD
                    _buildGlassTextField(
                      controller: passwordController,
                      hint: "Mot de passe",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true, // Active l'icône œil
                    ),

                    /// OUBLI MOT DE PASSE
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, "/forgot"),
                        child: Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// BOUTON LOGIN ANIMÉ
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: _isButtonEnabled && !_isLoading
                            ? const LinearGradient(
                                colors: [Color(0xFF1A73B8), Color(0xFF0F4C75)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _isButtonEnabled && !_isLoading
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A73B8,
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
                              ? _handleLogin
                              : null,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 25,
                                    width: 25,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "SE CONNECTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// REGISTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Pas encore membre ? ",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            "Créer un compte",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A73B8),
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
        ],
      ),
    );
  }

 Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.85),
            size: 24,
          ),
          // ICÔNE ŒIL TOGGLE
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
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
                      size: 22,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
