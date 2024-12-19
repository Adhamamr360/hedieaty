import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hedieaty/services/db_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper().database;
  await DatabaseHelper().recreateDatabase();
  await Firebase.initializeApp();
  await _retrieveFCMToken();

  runApp(HedieatyApp());
}

Future<void> _retrieveFCMToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Get the FCM token
  String? token = await messaging.getToken();

  if (token != null) {
    print("FCM Token: $token");
  } else {
    print("Failed to retrieve FCM token");
  }
}

class HedieatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty',
      theme: ThemeData(primaryColor: Color(0xFFdf43a1)),
      home: LoginPage(),
    );
  }
}
