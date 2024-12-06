import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_helper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      // Get the current user's UID from FirebaseAuth
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        print('No user is logged in.');
        setState(() {
          name = 'No user logged in';
          email = 'N/A';
          phone = 'N/A';
        });
        return;
      }

      print('Fetching profile for UID: $uid');

      // Retrieve the user data from SQLite
      final user = await _dbHelper.getUser(uid);

      if (user != null) {
        setState(() {
          name = user['name'] ?? 'No name provided';
          email = user['email'] ?? 'No email available';
          phone = user['phone'] ?? 'No phone number available';
        });
      } else {
        print('No user found in SQLite for UID: $uid');
        setState(() {
          name = 'User not found';
          email = 'N/A';
          phone = 'N/A';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        name = 'Error loading profile';
        email = 'N/A';
        phone = 'N/A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFFdf43a1),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // Logout logic: Sign out from Firebase and navigate to LoginPage
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100.0, color: Color(0xFFdf43a1)),
            SizedBox(height: 20),
            Text('Name: $name', style: TextStyle(fontSize: 24)),
            Text('Email: $email', style: TextStyle(fontSize: 24)),
            Text('Phone: $phone', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
