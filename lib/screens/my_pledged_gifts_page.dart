import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _pledgedGifts = [];

  @override
  void initState() {
    super.initState();
    _loadPledgedGifts();
  }

  Future<void> _loadPledgedGifts() async {
    try {
      // Retrieve gifts where the logged-in user is the pledger or purchaser
      final querySnapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('pledged_by', isEqualTo: uid)
          .get();

      final pledgedGifts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Gift',
          'description': data['description'] ?? '',
          'price': data['price'] ?? 0.0,
          'event': data['event'] ?? 'No Event',
          'category': data['category'] ?? 'Uncategorized',
          'status': data['status'] ?? 'not_pledged',
        };
      }).toList();

      setState(() {
        _pledgedGifts = pledgedGifts;
      });
    } catch (e) {
      print('Error loading pledged gifts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pledged gifts.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pledged Gifts'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: _pledgedGifts.isEmpty
          ? Center(
        child: Text(
          'No pledged or purchased gifts yet.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        itemCount: _pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = _pledgedGifts[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            color: gift['status'] == 'purchased'
                ? Colors.red.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            child: ListTile(
              title: Text(gift['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event: ${gift['event']}'),
                  Text('Category: ${gift['category']}'),
                  Text('Price: \$${gift['price']}'),
                  Text('Description: ${gift['description']}'),
                  Text('Status: ${gift['status']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
