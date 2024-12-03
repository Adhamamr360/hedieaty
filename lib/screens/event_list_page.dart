import 'package:flutter/material.dart';
import 'friends_page.dart';
import 'gift_list_page.dart';
import 'profile_page.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to Home Page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2) {
      // Navigate to Gift List Page
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
        title: Text('Event List'),
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
      body: Center(
        child: Text(
          'Event List Page',
          style: TextStyle(fontSize: 24, color: Color(0xFFdf43a1)),
        ),
      ),
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
