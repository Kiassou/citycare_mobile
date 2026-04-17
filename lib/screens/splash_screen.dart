import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Animation de progression
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && _progressValue < 1.0) {
        setState(() {
          _progressValue += 0.015;
        });
      } else {
        timer.cancel();
      }
    });

    _animationController.forward();

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. IMAGE NETTE CityCare
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/citycare.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. OVERLAY DÉGRADÉ CityCare
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1A73B8).withOpacity(0.4),
                  const Color(0xFF4A7C32).withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // 3. ÉLÉMENTS DÉCORATIFS
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1A73B8).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. CARTE EN BAS (pas au centre)
          Positioned(
            bottom: isTablet ? 80 : 60, // Distance du bas
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 100 : 60,
                    ),
                    constraints: BoxConstraints(maxWidth: isTablet ? 500 : 380),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.white.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 50 : 35,
                        isTablet ? 40 : 30, // Padding haut réduit
                        isTablet ? 50 : 35,
                        isTablet ? 35 : 25, // Padding bas réduit
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // TITRE PRINCIPAL
                          

                          const SizedBox(height: 5),

                          // SLAGAN
                          Text(
                            "Prenons soin de notre ville ensemble",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // PROGRESS BAR ANIMÉE
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      // Fond de progression
                                      LinearProgressIndicator(
                                        value: _progressValue,
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1A73B8),
                                            ),
                                        minHeight: 6,
                                      ),
                                      // Overlay dégradé
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                              colors: [
                                                const Color(0xFF1A73B8),
                                                const Color(0xFF4A7C32),
                                              ],
                                            ).createShader(bounds),
                                        blendMode: BlendMode.srcATop,
                                        child: LinearProgressIndicator(
                                          value: _progressValue,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.white),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // TEXTES DYNAMIQUES
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Chargement",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${(_progressValue * 100).toInt()}%",
                                    style: TextStyle(
                                      color: const Color(0xFF1A73B8),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Initialisation de votre environnement CityCare...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.3,
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
          ),
        ],
      ),
    );
  }
}
