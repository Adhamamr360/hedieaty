import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_helper.dart';
import 'add_gift_page.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  // Load gifts for the logged-in user
  Future<void> _loadGifts() async {
    final gifts = await _dbHelper.getGiftsForUser(uid);
    setState(() {
      _gifts = gifts;
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
                // Navigate to Add Gift Page with the UID
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
                backgroundColor: Color(0xFFdf43a1),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: _gifts.isEmpty
                ? Center(
              child: Text(
                'No gifts added yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return Card(
                  child: ListTile(
                    title: Text(gift['name']),
                    subtitle: Text(
                        '${gift['description']} - \$${gift['price']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
