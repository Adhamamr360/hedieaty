import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_helper.dart';
import 'add_event_page.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _dbHelper.getEventsForUser(uid);
    setState(() {
      _events = events;
    });
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
                await _loadEvents(); // Reload events after returning
              },
              child: Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFdf43a1),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? Center(
              child: Text(
                'No events added yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return Card(
                  child: ListTile(
                    title: Text(event['name']),
                    subtitle: Text('${event['description']} - ${event['date']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
