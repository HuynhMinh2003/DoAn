import 'package:flutter/material.dart';

class AdminWebPage extends StatefulWidget {
  const AdminWebPage({super.key});

  @override
  State<AdminWebPage> createState() => _AdminWebPageState();
}

class _AdminWebPageState extends State<AdminWebPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FEFF),
      body: Center(
        child: Text("Test",style: TextStyle(fontSize: 40),),
      ),
    );
  }
}
