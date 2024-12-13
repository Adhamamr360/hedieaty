import 'package:flutter/material.dart';
import 'event_list_page.dart';
import 'gift_list_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Default to Friends

  final List<Widget> _pages = [
    Center(
      child: Text(
        'Welcome to Hedieaty!',
        style: TextStyle(fontSize: 24, color: Color(0xFFdf43a1)),
      ),
    ),
    EventListPage(),
    GiftListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Friends'
              : _selectedIndex == 1
              ? 'Event List'
              : 'Gift List',
        ),
        backgroundColor: Color(0xFFdf43a1),
        automaticallyImplyLeading: false,
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
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: _selectedIndex == 0 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.event,
              color: _selectedIndex == 1 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.card_giftcard,
              color: _selectedIndex == 2 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Gifts',
          ),
        ],
      ),
    );
  }
}
