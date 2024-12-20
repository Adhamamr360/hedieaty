import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_services.dart';
import 'login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Validate all fields
  bool _validateAllFields() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showErrorDialog('Please fill in all the fields.');
      return false;
    }
    return true;
  }

  // Validate individual fields
  bool _validateIndividualFields() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    final emailRegex = RegExp(r"^[^@\s]+@(gmail\.com|yahoo\.com|eng\.asu\.edu\.eg)");
    final passwordRegex = RegExp(r"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\\$%^&*])[A-Za-z\d!@#\\$%^&*]{8,}");

    if (name.length < 3) {
      _showErrorDialog('Name must be at least 3 characters long.');
      return false;
    }

    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('Email must end with @gmail.com, @yahoo.com, or @eng.asu.edu.eg.');
      return false;
    }


    if (!passwordRegex.hasMatch(password)) {
      _showErrorDialog(
        'Password must be at least 8 characters long, include at least 1 uppercase letter, 1 number, and 1 special character.',
      );
      return false;
    }

    if (phone.length != 11 || !RegExp(r"^\d{11}").hasMatch(phone)) {
      _showErrorDialog('Phone number must be exactly 11 digits.');
      return false;
    }

    return true;
  }

  // Check redundancy for email and phone in Firestore
  Future<bool> _checkRedundancy(String email, String phone) async {
    try {
      // Check email redundancy
      final emailQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        _showErrorDialog('The email is already in use.');
        return false;
      }

      // Check phone redundancy
      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        _showErrorDialog('The phone number is already in use.');
        return false;
      }

      return true;
    } catch (e) {
      _showErrorDialog('An error occurred while checking redundancy. Please try again.');
      return false;
    }
  }

  // Sign-up logic
  Future<void> _signUp() async {
    if (!_validateAllFields()) return; // Check if all fields are filled
    if (!_validateIndividualFields()) return; // Validate individual fields

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Check for redundant email and phone number
      if (!await _checkRedundancy(email, phone)) return;

      // Sign up the user using Firebase Authentication
      UserCredential userCredential = await _authService.signUp(email, password);

      final user = userCredential.user;
      final uid = user!.uid;

      // Generate the FCM token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Save user details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'name': name,
        'fcmToken': fcmToken, // Save the FCM token
      });

      // Navigate back to LoginPage after successful sign-up
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('Something went wrong. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Up Failed'),
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
                  key: ValueKey('signupNameField'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  key: ValueKey('signupEmailField'),
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  key: ValueKey('signupPasswordField'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  key: ValueKey('signupPhoneField'),
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  key: ValueKey('signUpButton'),
                  onPressed: _signUp,
                  child: Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
