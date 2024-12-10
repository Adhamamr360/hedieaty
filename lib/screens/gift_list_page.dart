import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'add_gift_page.dart';
import 'friends_page.dart';
import 'event_list_page.dart';
import 'profile_page.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _gifts = [];
  int _selectedIndex = 2;

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

  // Publish a gift to Firestore and delete it from SQLite
  Future<void> _publishGift(Map<String, dynamic> gift) async {
    try {
      await FirebaseFirestore.instance.collection('gifts').add({
        'uid': uid,
        'name': gift['name'],
        'description': gift['description'],
        'price': gift['price'],
        'event': gift['event'],
        'created_at': Timestamp.now(),
      });

      await _dbHelper.deleteGift(gift['id']);
      await _loadGifts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift published successfully!')),
      );
    } catch (e) {
      print('Error publishing gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish gift.')),
      );
    }
  }

  // Handle navigation between pages via the BottomNavigationBar
  void _onItemTapped(int index) {
    if (index == 0 && _selectedIndex != 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1 && _selectedIndex != 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventListPage()),
      );
    } else if (index == 2) {
      // Stay on the current page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gift List'),
        backgroundColor: Color(0xFFdf43a1),
        automaticallyImplyLeading: false, // Removes the back button
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _gifts.isEmpty
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
              subtitle: Text('${gift['description']} - \$${gift['price']}'),
              trailing: IconButton(
                icon: Icon(Icons.cloud_upload, color: Color(0xFFdf43a1)),
                onPressed: () => _publishGift(gift),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddGiftPage
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddGiftPage(uid: uid)),
          );
          await _loadGifts(); // Reload gifts after adding a new one
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFdf43a1),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _onItemTapped(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: _selectedIndex == 0 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Friends',
            backgroundColor: _selectedIndex == 0 ? Color(0xFFdf43a1) : Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.event,
              color: _selectedIndex == 1 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Events',
            backgroundColor: _selectedIndex == 1 ? Color(0xFFdf43a1) : Colors.grey,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.card_giftcard,
              color: _selectedIndex == 2 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Gifts',
            backgroundColor: _selectedIndex == 2 ? Color(0xFFdf43a1) : Colors.grey,
          ),
        ],
      ),
    );
  }
}
