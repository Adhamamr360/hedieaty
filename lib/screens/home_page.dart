import 'package:flutter/material.dart';
import 'event_list_page.dart';
import 'gift_list_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventListPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GiftListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Color(0xFFdf43a1),
        automaticallyImplyLeading: false, // Remove back button
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
      body: Center(
        child: Text(
          'Welcome to Hedieaty!',
          style: TextStyle(fontSize: 24, color: Color(0xFFdf43a1)),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: _selectedIndex == 0 ? Color(0xFFdf43a1) : Colors.grey,
            ),
            label: 'Home',
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
