import 'package:flutter/material.dart';

class AdminMobilePage extends StatefulWidget {
  const AdminMobilePage({super.key});

  @override
  State<AdminMobilePage> createState() => _AdminMobilePageState();
}

class _AdminMobilePageState extends State<AdminMobilePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Test",style: TextStyle(fontSize: 40),),
      ),
    );
  }
}
