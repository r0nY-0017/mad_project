import 'dart:async';
import 'package:flutter/material.dart';
import 'package:simple_chat_application/pages/login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 35, 035, 35), 
              Color.fromARGB(255, 35, 100, 40),
            ], // Dark gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  'assets/logo.png', // Replace with your actual logo path
                  width: 170,
                  height: 170,
                ).animate().fade(duration: 500.ms).slideY()
              ),
              //const SizedBox(height: 20),
              Text(
                "Esho Adda Dei",
                style: TextStyle(
                  fontSize: 12,
                  //fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fade(duration: 800.ms).slideY(),
            ],
          ),
        ),
      ),
    );
  }
}