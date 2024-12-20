import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hedieaty/screens/update_gift_page.dart';
import '../services/db_helper.dart';
import 'add_gift_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'delete_gift_page.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _localGifts = [];
  List<Map<String, dynamic>> _firestoreGifts = [];
  String _sortCriteria = 'Name';


  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  // Load gifts for the logged-in user (both local and Firestore)
  Future<void> _loadGifts() async {
    try {
      // Load local gifts from SQLite
      final localGifts = await _dbHelper.getGiftsForUser(uid);

      // Load Firestore gifts
      final querySnapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('uid', isEqualTo: uid)
          .get();

      final firestoreGifts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Gift',
          'description': data['description'] ?? '',
          'price': (data['price'] ?? 0.0).toInt(),
          'event': data['event'] ?? 'No Event',
          'category': data['category'] ?? 'Uncategorized',
          'status': data['status'] ?? 'not_pledged',
        };
      }).toList();

      setState(() {
        _localGifts = localGifts;
        _firestoreGifts = firestoreGifts;

        // If a sort is already selected, apply sorting to both
        if (_sortCriteria.isNotEmpty) {
          _sortGifts();  // Apply sorting method for gifts
        }
      });
    } catch (e) {
      print('Error loading gifts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load gifts. Please try again.')),
      );
    }
  }

  void _sortGifts() {
    setState(() {
      if (_sortCriteria == 'Name') {
        // Sort by name
        _localGifts.sort((a, b) => a['name'].compareTo(b['name']));
        _firestoreGifts.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (_sortCriteria == 'Category') {
        // Sort by category (or another criterion)
        _localGifts.sort((a, b) => a['category'].compareTo(b['category']));
        _firestoreGifts.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (_sortCriteria == 'Price') {
      // Sort by price
      _localGifts.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
      _firestoreGifts.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    }
    });
  }


  String _getStatus(String itemDate) {
    final DateTime itemDateTime = DateTime.parse(itemDate);
    final DateTime currentDate = DateTime.now();
    return itemDateTime.isBefore(currentDate) ? 'Past' : 'Upcoming';
  }


  void _onDeletePressed(BuildContext context, Map<String, dynamic> gift, bool isFirestore, Future<void> Function() loadGifts) {
    if (isFirestore && gift['status'] != 'not_pledged') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete pledged or purchased gift.')),
      );
      return;
    }

    // Navigate to the DeleteGiftPage if the gift is not pledged
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteGiftPage(
          gift: gift,
          isFirestore: isFirestore,
          loadGifts: loadGifts,
        ),
      ),
    );
  }


  Future<void> _editGift(Map<String, dynamic> gift, bool isFirestore) async {
    if (isFirestore && gift['status'] != 'not_pledged') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot edit pledged or purchased gifts.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateGiftPage(
          uid: uid,
          gift: gift,
          isFirestore: isFirestore,
        ),
      ),
    );
    _loadGifts(); // Reload gifts after editing
  }

  Widget _buildGiftCard(Map<String, dynamic> gift, bool isFirestore) {
    Color _getGiftBackgroundColor(String? status) {
      if (!isFirestore) return Colors.grey.shade100; // Default for local gifts

      switch (status) {
        case 'pledged':
          return Colors.green.withOpacity(0.2);
        case 'purchased':
          return Colors.red.withOpacity(0.2);
        default:
          return Colors.grey.shade100; // Default for Firestore "not_pledged"
      }
    }

    return Card(
      color: _getGiftBackgroundColor(isFirestore ? gift['status'] : null),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text(gift['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${gift['event']}'),
            Text('Category: ${gift['category']}'),
            Text('Price: \$${gift['price']}'),
            Text('Description: ${gift['description']}'),
            if (isFirestore) Text('Status: ${gift['status']}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _editGift(gift, isFirestore),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _onDeletePressed(context, gift, isFirestore, _loadGifts),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sort'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () async {
              String? selectedSort = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Sort By'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: 'Name',
                          groupValue: _sortCriteria,
                          onChanged: (value) {
                            setState(() {
                              _sortCriteria = value!;
                            });
                            Navigator.pop(context, value);
                          },
                          title: Text('Name'),
                        ),
                        RadioListTile<String>(
                          value: 'Category',
                          groupValue: _sortCriteria,
                          onChanged: (value) {
                            setState(() {
                              _sortCriteria = value!;
                            });
                            Navigator.pop(context, value);
                          },
                          title: Text('Category'),
                        ),
                        RadioListTile<String>(
                          value: 'Price',
                          groupValue: _sortCriteria,
                          onChanged: (value) {
                            setState(() {
                              _sortCriteria = value!;
                            });
                            Navigator.pop(context, value);
                          },
                          title: Text('price'),
                        ),

                      ],
                    ),
                  );
                },
              );
              if (selectedSort != null) {
                setState(() {
                  _sortCriteria = selectedSort;
                });
                _sortGifts(); // Apply sorting
              }
            },
          )
        ],
      ),

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
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.black,
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
                  ..._localGifts.map((gift) => _buildGiftCard(gift, false)),
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
                  ..._firestoreGifts.map((gift) => _buildGiftCard(gift, true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
