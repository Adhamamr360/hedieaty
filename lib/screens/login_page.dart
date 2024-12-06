import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart'; // Import DatabaseHelper
import 'friends_page.dart';
import 'signup_page.dart';
import '../services/auth_services.dart'; // Import AuthService

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Initialize DatabaseHelper

  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your email address.');
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to log in with email and password
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Get the current user's UID
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user's data from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Save or update the user data in SQLite
        await _dbHelper.insertOrUpdateUser({
          'uid': uid,
          'name': userData['name'] ?? 'N/A',
          'email': userData['email'] ?? 'N/A',
          'phone': userData['phone'] ?? 'N/A',
        });

        print('User data saved or updated in SQLite.');
      } else {
        _showErrorDialog('User profile not found.');
        return;
      }

      // Navigate to HomePage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      print('Error during login: $e');
      _showErrorDialog('Something went wrong. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 180),
                Icon(
                  Icons.card_giftcard,
                  size: 100.0,
                  color: Color(0xFFdf43a1),
                ),
                SizedBox(height: 20),
                Text(
                  'Hedieaty',
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontSize: 40,
                    color: Color(0xFFdf43a1),
                  ),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  child: Text("Login"),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text("Don’t have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
