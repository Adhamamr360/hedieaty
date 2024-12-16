import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'add_event_page.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _localEvents = [];
  Map<int, List<Map<String, dynamic>>> _localGifts = {};
  List<Map<String, dynamic>> _firestoreEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEventsAndGifts();
  }

  Future<void> _loadEventsAndGifts() async {
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

  Future<void> _publishEventToFirestore(Map<String, dynamic> event) async {
    try {
      // Add event to Firestore
      final eventRef = await FirebaseFirestore.instance.collection('events').add({
        'uid': uid,
        'name': event['name'],
        'description': event['description'],
        'date': event['date'],
        'location': event['location'],
        'number_of_gifts': event['number_of_gifts'],
        'created_at': Timestamp.now(),
      });

      // Publish gifts associated with the event
      final gifts = _localGifts[event['id']] ?? [];
      for (final gift in gifts) {
        await FirebaseFirestore.instance.collection('gifts').add({
          'uid': uid,
          'name': gift['name'],
          'description': gift['description'],
          'price': gift['price'],
          'event': event['name'],
          'event_id': eventRef.id, // Associate gift with the event in Firestore
          'created_at': Timestamp.now(),
        });
        await _dbHelper.deleteGift(gift['id']); // Remove the gift from local DB
      }

      // Remove the event from the local database
      await _dbHelper.deleteEvent(event['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event and its gifts published successfully!')),
      );

      _loadEventsAndGifts(); // Reload data after publishing
    } catch (e) {
      print('Error publishing event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish event.')),
      );
    }
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
                    builder: (context) => AddEventPage(uid: uid),
                  ),
                );
                _loadEventsAndGifts(); // Reload events after adding
              },
              child: Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFdf43a1),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
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
                            subtitle:
                            Text('${gift['description']} - \$${gift['price']}'),
                          )),
                        if (gifts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('No gifts assigned to this event.'),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () => _publishEventToFirestore(event),
                            child: Text('Publish Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFdf43a1),
                            ),
                          ),
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
                      subtitle: Text('${event['description']} - ${event['date']}'),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('gifts')
                              .where('event_id', isEqualTo: event['id'])
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
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
        ],
      ),
    );
  }
}
