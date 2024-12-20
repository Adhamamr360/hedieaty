import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_services.dart';
import '../services/db_helper.dart';
import 'login_page.dart';
import 'my_pledged_gifts_page.dart';
import 'dart:math';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String name = 'Loading...';
  String email = 'Loading...';
  String phone = 'Loading...';
  String _userImage = '';

  List<Map<String, dynamic>> _localEvents = [];
  Map<int, List<Map<String, dynamic>>> _localGifts = {};
  List<Map<String, dynamic>> _firestoreEvents = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadEventsAndGifts();
  }

  Future<void> _loadUserProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        setState(() {
          name = 'No user logged in';
          email = 'N/A';
          phone = 'N/A';
          _userImage = '';
        });
        return;
      }

      final user = await _dbHelper.getUser(uid);

      if (user != null) {
        setState(() {
          name = user['name'] ?? 'No name provided';
          email = user['email'] ?? 'No email available';
          phone = user['phone'] ?? 'No phone number available';
          _userImage = user['image'] ?? '';
        });
      } else {
        setState(() {
          name = 'User not found';
          email = 'N/A';
          phone = 'N/A';
          _userImage = '';
        });
      }
    } catch (e) {
      setState(() {
        name = 'Error loading profile';
        email = 'N/A';
        phone = 'N/A';
        _userImage = '';
      });
    }
  }

  Future<void> _loadEventsAndGifts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    // Load local events and their gifts
    final localEvents = await _dbHelper.getEventsForUser(uid);
    Map<int, List<Map<String, dynamic>>> localGifts = {};

    for (final event in localEvents) {
      localGifts[event['id']] = await _dbHelper.getGiftsByEventId(event['id']);
    }

    // Load Firestore events
    final firestoreEventsQuery = await FirebaseFirestore.instance
        .collection('events')
        .where('uid', isEqualTo: uid)
        .get();

    setState(() {
      _localEvents = localEvents;
      _localGifts = localGifts;
      _firestoreEvents = firestoreEventsQuery.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();
    });
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newPhone = phoneController.text.trim();

                // Validation checks
                if (newName.isEmpty || newPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                if (newName.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Name must be at least 3 characters long.')),
                  );
                  return;
                }

                if (newPhone.length < 11 || !RegExp(r'^\d+$').hasMatch(newPhone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number must be at least 11 digits.')),
                  );
                  return;
                }

                try {
                  final uid = FirebaseAuth.instance.currentUser?.uid;

                  if (uid != null) {
                    // Update Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'name': newName, 'phone': newPhone});

                    // Update SQLite
                    await _dbHelper.updateUser({'uid': uid, 'name': newName, 'phone': newPhone});

                    setState(() {
                      name = newName;
                      phone = newPhone;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile updated successfully.')),
                    );
                  }
                } catch (e) {
                  print('Error updating profile: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile.')),
                  );
                }

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _authService.signOut(); // Sign out user and clear SQLite data

    // Navigate to the login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  String getRandomImage() {
    // Generate a random number between 0 and 4
    final random = Random();
    int randomIndex = random.nextInt(5); // Generates a number from 0 to 4

    // Construct the asset image path
    return 'assets/images/img_$randomIndex.png';
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
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage(getRandomImage()),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Name: $name', style: TextStyle(fontSize: 24)),
                  Text('Email: $email', style: TextStyle(fontSize: 24)),
                  Text('Phone: $phone', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _editProfile,
                    child: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyPledgedGiftsPage()),
                      );
                    },
                    child: Text('View My Pledged Gifts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 30, color: Colors.grey),
            if (_localEvents.isEmpty && _firestoreEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No events yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            if (_localEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Local Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ..._localEvents.map((event) {
              final gifts = _localGifts[event['id']] ?? [];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(event['name']),
                  subtitle: Text('${event['description']} - ${event['date']}'),
                  children: [
                    if (gifts.isNotEmpty)
                      ...gifts.map((gift) => ListTile(
                        leading: Icon(Icons.card_giftcard, color: Colors.purple),
                        title: Text(gift['name']),
                        subtitle: Text('${gift['description']} - \$${gift['price']}'),
                      )),
                    if (gifts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('No gifts assigned to this event.'),
                      ),
                  ],
                ),
              );
            }),
            if (_firestoreEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Published Events',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ..._firestoreEvents.map((event) {
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ExpansionTile(
                  title: Text(event['name']),
                  subtitle: Text('${event['description']} - ${event['date']}'),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('gifts')
                          .where('event_id', isEqualTo: event['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final gifts = snapshot.data?.docs ?? [];
                        if (gifts.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('No gifts assigned to this event.'),
                          );
                        }
                        return Column(
                          children: gifts.map((giftDoc) {
                            final gift = giftDoc.data() as Map<String, dynamic>;
                            return ListTile(
                              leading: Icon(Icons.card_giftcard, color: Colors.purple),
                              title: Text(gift['name']),
                              subtitle: Text('${gift['description']} - \$${gift['price']}'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
