import 'package:flutter/material.dart';
import 'screens/login_page.dart'; // Import the LoginPage screen

void main() {
  runApp(HedieatyApp());
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty',
      theme: ThemeData(primaryColor: Color(0xFFdf43a1)),
      home: LoginPage(), // Start with the LoginPage
    );
  }
}
