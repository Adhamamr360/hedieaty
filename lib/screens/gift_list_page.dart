import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_helper.dart';
import 'add_gift_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _localGifts = [];
  List<Map<String, dynamic>> _firestoreGifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  // Load gifts for the logged-in user (both local and Firestore)
  Future<void> _loadGifts() async {
    final localGifts = await _dbHelper.getGiftsForUser(uid);
    final querySnapshot = await FirebaseFirestore.instance
        .collection('gifts')
        .where('uid', isEqualTo: uid)
        .get();

    setState(() {
      _localGifts = localGifts;
      _firestoreGifts = querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'name': doc['name'],
        'description': doc['description'],
        'price': doc['price'],
        'event': doc['event'],
      })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddGiftPage(uid: uid),
                  ),
                );
                await _loadGifts(); // Reload gifts after returning
              },
              child: Text('Add Gift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (_localGifts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Local Gifts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._localGifts.map((gift) => Card(
                    child: ListTile(
                      title: Text(gift['name']),
                      subtitle: Text(
                          '${gift['description']} - \$${gift['price']}'),
                    ),
                  )),
                ],
                if (_firestoreGifts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Published Gifts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._firestoreGifts.map((gift) => Card(
                    child: ListTile(
                      title: Text(gift['name']),
                      subtitle: Text(
                          '${gift['description']} - \$${gift['price']}'),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
