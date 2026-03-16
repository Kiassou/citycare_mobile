import 'package:citycare_mobile/models/user_model.dart';
import 'package:citycare_mobile/screens/admin_home_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() {
  runApp(CityCareApp());
}

class CityCareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CityCare",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot': (context) => ForgotPasswordScreen(),
        // On ne met pas /admin_home ici car il a besoin d'un argument 'user'
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/admin_home') {
          // On récupère l.utilisateur passé lors du Navigator.push
          final user = settings.arguments as UserModel;
          return MaterialPageRoute(
            builder: (context) => AdminHomeScreen(user: user),
          );
        }
        return null;
      },
    );
  }
}