import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import 'login_page.dart'; // Import DatabaseHelper

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
    // Retrieve the current logged-in user's data from SQLite
    final user = await _dbHelper.getUser('uid');  // Replace 'uid' with the actual UID

    if (user != null) {
      setState(() {
        name = user['name'] ?? 'No name';
        email = user['email'] ?? 'No email';
        phone = user['phone'] ?? 'No phone number';
      });
    } else {
      print('No user found in SQLite');
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
            onPressed: () {
              // Logout logic
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
