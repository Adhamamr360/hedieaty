import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';
import 'local_update_page.dart';  // New file for editing local events
import 'firestore_update_page.dart';  // New file for editing Firestore events
import 'add_event_page.dart';  // Add this import for the Add Event page

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> _localEvents = [];
  List<Map<String, dynamic>> _firestoreEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Load both local and Firestore events
  Future<void> _loadEvents() async {
    final localEvents = await _dbHelper.getEventsForUser(uid);
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
    });
  }

  // Delete event based on whether it's local or in Firestore
  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    try {
      // Check if the event has a Firestore ID (String) or if it's a local event (non-Firestore)
      final isFirestore = event.containsKey('id') && event['id'] is String;

      if (isFirestore) {
        // Firestore event deletion
        await FirebaseFirestore.instance.collection('events').doc(event['id']).delete();

        // Also delete associated gifts from Firestore
        final giftsQuery = await FirebaseFirestore.instance
            .collection('gifts')
            .where('event_id', isEqualTo: event['id'])
            .get();
        for (var gift in giftsQuery.docs) {
          await gift.reference.delete();
        }

        print('Firestore event and associated gifts deleted successfully.');
      } else {
        // Local event deletion
        await _dbHelper.deleteEvent(event['id']);
        print('Local event deleted successfully.');
      }

      // Notify the user and reload the event list
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event deleted successfully!')));
      _loadEvents();  // Reload events after deletion
    } catch (e) {
      print('Error deleting event: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete event.')));
    }
  }

  void _editEvent(Map<String, dynamic> event) async {
    // Check if the event has a Firestore ID and Firestore metadata
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




  // Check if the event is upcoming or past
  String _getEventStatus(DateTime eventDate) {
    final now = DateTime.now();
    return eventDate.isAfter(now) ? 'Upcoming' : 'Past';
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
                    builder: (context) => AddEventPage(uid: uid), // Navigate to Add Event page
                  ),
                );
                await _loadEvents();
              },
              child: Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                  final eventDate = DateTime.parse(event['date']);
                  return ListTile(
                    title: Text(event['name']),
                    subtitle: Text(_getEventStatus(eventDate)),
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
                  final eventDate = DateTime.parse(event['date']);
                  return ListTile(
                    title: Text(event['name']),
                    subtitle: Text(_getEventStatus(eventDate)),
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
