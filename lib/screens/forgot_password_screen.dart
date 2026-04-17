import 'dart:ui';
import 'package:citycare_mobile/config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  final Color primaryBlue = const Color(0xFF1A73B8);

  @override
  void initState() {
    super.initState();
    emailController.addListener(() {
      setState(() {
        _isButtonEnabled =
            emailController.text.contains('@') &&
            emailController.text.contains('.');
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_isButtonEnabled || _isLoading) return;

    setState(() => _isLoading = true);

    var url = Uri.parse('${AppConfig.baseUrl}/api/auth/forgot-password');

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text}),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showSnackBar(
          "Lien de réinitialisation envoyé ! Vérifiez votre boîte mail.",
          Colors.green,
        );
        Future.delayed(
          const Duration(seconds: 2),
          () => Navigator.pop(context),
        );
      } else {
        _showSnackBar(
          data["message"] ?? "Email introuvable.",
          Colors.redAccent,
        );
      }
    } catch (e) {
      _showSnackBar("Erreur de connexion au serveur.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
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

          // 2. CARTE TRANSPARENTE CITYCARE
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 100 : 35,
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
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 50 : 35,
                  isTablet ? 50 : 40,
                  isTablet ? 50 : 35,
                  isTablet ? 40 : 35,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [


                    /// TITRE GRADIENT
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [primaryBlue, const Color(0xFF0F4C75)],
                      ).createShader(bounds),
                      child: const Text(
                        "Récupération Mot de Passe",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// DESCRIPTION
                    Text(
                      "Entrez votre adresse email pour recevoir\nun lien de réinitialisation sécurisé",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CHAMP EMAIL COMPACT
                    _buildCompactGlassField(
                      controller: emailController,
                      hint: "Votre adresse email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 35),

                    /// BOUTON ENVOYER
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: _isButtonEnabled && !_isLoading
                            ? LinearGradient(
                                colors: [primaryBlue, const Color(0xFF0F4C75)],
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
                                  color: primaryBlue.withOpacity(0.4),
                                  blurRadius: 22,
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
                              ? _handleResetPassword
                              : null,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.8,
                                    ),
                                  )
                                : const Text(
                                    "ENVOYER LE LIEN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// RETOUR LOGIN
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "← Retour à la connexion",
                        style: TextStyle(
                          fontSize: 14,
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

  /// CHAMP COMPACT EMAIL
  Widget _buildCompactGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.85),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
