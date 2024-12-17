import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_services.dart';
import '../services/db_helper.dart';
import 'login_page.dart';

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
        });
        return;
      }

      final user = await _dbHelper.getUser(uid);

      if (user != null) {
        setState(() {
          name = user['name'] ?? 'No name provided';
          email = user['email'] ?? 'No email available';
          phone = user['phone'] ?? 'No phone number available';
        });
      } else {
        setState(() {
          name = 'User not found';
          email = 'N/A';
          phone = 'N/A';
        });
      }
    } catch (e) {
      setState(() {
        name = 'Error loading profile';
        email = 'N/A';
        phone = 'N/A';
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

  Future<void> _logout() async {
    await _authService.signOut(); // Sign out user and clear SQLite data

    // Navigate to the login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
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
            onPressed: _logout, // Awaited Firebase sign-out
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
                  Icon(Icons.person, size: 100.0, color: Color(0xFFdf43a1)),
                  SizedBox(height: 20),
                  Text('Name: $name', style: TextStyle(fontSize: 24)),
                  Text('Email: $email', style: TextStyle(fontSize: 24)),
                  Text('Phone: $phone', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
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
                        title: Text(gift['name']),
                        subtitle: Text(
                            '${gift['description']} - \$${gift['price']}'),
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
                  subtitle: Text('Number of Gifts: ${event['number_of_gifts']}'),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('gifts')
                          .where('event_id', isEqualTo: event['id'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                              title: Text(gift['name']),
                              subtitle: Text(
                                  '${gift['description']} - \$${gift['price']}'),
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
