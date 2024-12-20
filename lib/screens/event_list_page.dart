import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'updateLocalEvent_page.dart';
import 'updateFirestoreEvent_page.dart';
import 'add_event_page.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _localEvents = [];
  List<Map<String, dynamic>> _firestoreEvents = [];
  String _sortCriteria = 'Name'; // Default sorting criteria

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Load local events from SQLite
    final localEvents = await _dbHelper.getEventsForUser(uid);

    // Load Firestore events
    final firestoreEventsQuery = await FirebaseFirestore.instance
        .collection('events')
        .where('uid', isEqualTo: uid)
        .get();

    setState(() {
      _localEvents = localEvents;
      _firestoreEvents = firestoreEventsQuery.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      // If a sort is already selected, apply sorting to both
      if (_sortCriteria.isNotEmpty) {
        _sortEvents();
      }
    });
  }


  void _sortEvents() {
    setState(() {
      if (_sortCriteria == 'Name') {
        // Sort by name
        _localEvents.sort((a, b) => a['name'].compareTo(b['name']));
        _firestoreEvents.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (_sortCriteria == 'Status') {
        // Sort by date
        _localEvents.sort((a, b) => a['date'].compareTo(b['date']));
        _firestoreEvents.sort((a, b) => a['date'].compareTo(b['date']));
      }
    });
  }

  String _getEventStatus(String eventDate) {
    final DateTime eventDateTime = DateTime.parse(eventDate);
    final DateTime currentDate = DateTime.now();

    if (eventDateTime.isBefore(currentDate)) {
      return 'Past';
    } else {
      return 'Upcoming';
    }
  }

  Future<void> _publishLocalEvent(Map<String, dynamic> event) async {
    try {
      // Add the event to Firestore
      final eventRef = await FirebaseFirestore.instance.collection('events').add({
        'uid': uid,
        'name': event['name'],
        'description': event['description'],
        'date': event['date'],
        'location': event['location'],
        'number_of_gifts': event['number_of_gifts'],
        'created_at': Timestamp.now(),
      });

      // Retrieve associated gifts from SQLite
      final gifts = await _dbHelper.getGiftsByEventId(event['id']);

      // Add the gifts to Firestore
      for (final gift in gifts) {
        await FirebaseFirestore.instance.collection('gifts').add({
          'uid': uid,
          'name': gift['name'],
          'description': gift['description'],
          'price': gift['price'],
          'event': event['name'],
          'event_id': eventRef.id,
          'status': 'not_pledged',
          'created_at': Timestamp.now(),
        });
        // Delete the gift from SQLite
        await _dbHelper.deleteGift(gift);
      }

      // Delete the local event from SQLite
      await _dbHelper.deleteEvent(event['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local event published to Firestore!')),
      );

      // Reload events after publishing
      _loadEvents();
    } catch (e) {
      print('Error publishing local event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish local event.')),
      );
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    try {
      final isFirestore = event.containsKey('id') && event['id'] is String;
      final eventId = event['id'];  // This will either be an integer or a string

      if (isFirestore) {
        // Delete event from Firestore using document ID (String)
        await FirebaseFirestore.instance.collection('events').doc(eventId).delete();

        // Delete associated gifts from Firestore
        final giftsQuery = await FirebaseFirestore.instance
            .collection('gifts')
            .where('event_id', isEqualTo: eventId)
            .get();
        for (var gift in giftsQuery.docs) {
          await gift.reference.delete();
        }
      } else {
        // Delete event from SQLite using local event ID (int)
        await _dbHelper.deleteEvent(eventId);

        // Delete associated gifts from SQLite
        final gifts = await _dbHelper.getGiftsByEventId(eventId);
        for (var gift in gifts) {
          await _dbHelper.deleteGift(gift);  // Assuming gift['id'] is an integer
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event and its gifts deleted successfully!')));
      _loadEvents();
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event and its gifts.')));
    }
  }

  void _editEvent(Map<String, dynamic> event) async {
    final isFirestore = event.containsKey('id') && event['id'] is String;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isFirestore
            ? FirestoreEventPage(event: event)
            : LocalEventPage(event: event),
      ),
    );

    _loadEvents();
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
                          value: 'Status',
                          groupValue: _sortCriteria,
                          onChanged: (value) {
                            setState(() {
                              _sortCriteria = value!;
                            });
                            Navigator.pop(context, value);
                          },
                          title: Text('Status'),
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
                _sortEvents(); // Apply sorting
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
              key: const ValueKey('addEventButtonKey'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEventPage(uid: uid),
                  ),
                );
                await _loadEvents();
              },
              child: Text('Add Event'),
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
                if (_localEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Local Events',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ..._localEvents.map((event) {
                  return ListTile(
                    title: Text(event['name']),
                    subtitle: Text('${event['date']} - Status: ${_getEventStatus(event['date'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editEvent(event),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteEvent(event),
                        ),
                        IconButton(
                          icon: Icon(Icons.publish),
                          onPressed: () => _publishLocalEvent(event),
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
                  return ListTile(
                    title: Text(event['name']),
                    subtitle: Text('${event['date']} - Status: ${_getEventStatus(event['date'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),onPressed: () => _editEvent(event),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteEvent(event),
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
