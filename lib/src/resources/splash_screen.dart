import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:do_an/src/resources/auth_wrapper_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        child: Transform.scale(
          scale: 5, // Bạn có thể tăng/giảm để vừa ý (ví dụ: 2.0, 2.5...)
          child: Lottie.asset('assets/animation/Animation_1747910892464.json'),
        ),
      ),
      nextScreen: AuthWrapper(),
      duration: 3500,
      backgroundColor: Colors.white,
    );
  }
}
