import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_list_page.dart';
import 'gift_list_page.dart';
import 'profile_page.dart';
import 'friend_events_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Default to Friends
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _friends = []; // List of friends

  final List<Widget> _staticPages = [
    Container(), // Placeholder for dynamic Friends Page
    EventListPage(),
    GiftListPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends(); // Load friends for the Friends Page
  }

  Future<void> _loadFriends() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid) // Get the logged-in user's document
          .collection('friends') // Friend collection
          .get();

      final List<Map<String, dynamic>> friends = [];
      for (var doc in querySnapshot.docs) {
        final friendData = await FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id) // Friend document ID
            .get();

        final friend = friendData.data();
        if (friend != null) {
          // Query to get events for this friend
          final eventsQuery = await FirebaseFirestore.instance
              .collection('events')
              .where('uid', isEqualTo: friend['uid'])
              .get();

          // Filter to get only upcoming events
          final upcomingEvents = eventsQuery.docs.where((eventDoc) {
            String eventDateString = eventDoc['date']; // Event date as string

            DateTime eventDate;

            try {
              // Attempt to parse the event date string in 'yyyy-MM-dd' format
              eventDate = DateTime.parse(eventDateString);
            } catch (e) {
              print('Error parsing event date: $e');
              return false; // Return false if date parsing fails
            }

            // Now compare the eventDate with the current date
            return eventDate.isAfter(DateTime.now()); // Check if the event is upcoming
          }).toList();

          // Add friend and upcoming event count to the list
          friends.add({
            'id': doc.id,
            'name': friend['name'],
            'email': friend['email'],
            'uid': friend['uid'],
            'eventCount': upcomingEvents.length, // Count of upcoming events
          });
        }
      }

      setState(() {
        _friends = friends;
      });
    } catch (e) {
      print('Error loading friends: $e');
    }
  }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addFriendByPhone() async {
    TextEditingController phoneController = TextEditingController();

    // Show dialog to enter phone number
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Friend\'s Phone Number'),
          content: TextField(
            controller: phoneController,
            decoration: InputDecoration(hintText: 'Phone Number'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final phoneNumber = phoneController.text.trim();

                if (phoneNumber.isNotEmpty) {
                  try {
                    // Retrieve the current user's phone number
                    final currentUserDoc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid) // Document for the logged-in user
                        .get();
                    final currentUserPhone = currentUserDoc['phone'];

                    // Check if the entered phone number is the user's own phone number
                    if (phoneNumber == currentUserPhone) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('You can\'t add yourself as a friend.'),
                        ),
                      );
                      return; // Exit the function
                    }

                    // Check if user with the entered phone number exists in Firestore
                    final querySnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('phone', isEqualTo: phoneNumber)
                        .get();

                    if (querySnapshot.docs.isEmpty) {
                      // No user with this phone number
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No user found with this number.')),
                      );
                    } else {
                      final friendId = querySnapshot.docs.first.id;

                      // Check if the friend is already in the user's friend list
                      final friendDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('friends')
                          .doc(friendId)
                          .get();

                      if (friendDoc.exists) {
                        // Friend already added
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Friend already added!')),
                        );
                      } else {
                        // Add friend to logged-in user's friend list
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('friends')
                            .doc(friendId)
                            .set({});

                        // Reload the friends list
                        _loadFriends();

                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Friend added successfully!')),
                        );
                      }
                    }
                  } catch (e) {
                    print('Error adding friend: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding friend. Please try again.')),
                    );
                  }
                }
              },
              child: Text('Add Friend'),
            ),
          ],
        );
      },
    );
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
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _addFriendByPhone, // Add friend by phone number
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildFriendsPage() // Display Friends Page dynamically
          : _staticPages[_selectedIndex], // Use static pages for others
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

  // Build the Friends Page
// Build the Friends Page
  Widget _buildFriendsPage() {
    return _friends.isEmpty
        ? Center(
      child: Text(
        'No friends found.',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    )
        : ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(friend['name']),
            subtitle: Text('${friend['eventCount']} upcoming events'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendEventsPage(
                    friendUid: friend['uid'],
                    friendName: friend['name'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

}
