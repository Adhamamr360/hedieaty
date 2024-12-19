import 'package:flutter/material.dart';
import '../services/db_helper.dart';

class LocalEventPage extends StatefulWidget {
  final Map<String, dynamic> event;
  LocalEventPage({required this.event});

  @override
  _LocalEventPageState createState() => _LocalEventPageState();
}

class _LocalEventPageState extends State<LocalEventPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.event['name'];
    _dateController.text = widget.event['date'];
    _descriptionController.text = widget.event['description'];
    _locationController.text = widget.event['location'] ?? '';
  }

  Future<void> _saveEvent() async {
    final updatedEvent = {
      'id': widget.event['id'],
      'uid': widget.event['uid'],
      'name': _nameController.text,
      'date': _dateController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
    };

    await _dbHelper.updateEvent(updatedEvent);

    // Update associated gifts in SQLite
    final gifts = await _dbHelper.getGiftsByEventId(widget.event['id']);
    for (var gift in gifts) {
      final updatedGift = {
        'id': gift['id'],
        'name': gift['name'],
        'description': gift['description'],
        'price': gift['price'],
        'event': _nameController.text, // Update the event name in the gift
        'event_id': updatedEvent['id'],
        'status': gift['status'],
      };
      await _dbHelper.updateGift(updatedGift);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Local Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Event Name'),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }
}
