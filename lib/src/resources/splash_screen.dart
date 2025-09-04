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
          scale: 3,
          child: Lottie.asset('assets/animation/Animation_1749271510415.json'),
        ),
      ),
      nextScreen: AuthWrapper(),
      duration: 3500,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
