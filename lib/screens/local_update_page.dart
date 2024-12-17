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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.event['name'];
    _dateController.text = widget.event['date'];
    _descriptionController.text = widget.event['description'];
  }

  Future<void> _saveEvent() async {
    final updatedEvent = {
      'id': widget.event['id'],
      'uid': widget.event['uid'],
      'name': _nameController.text,
      'date': _dateController.text,
      'description': _descriptionController.text,
    };

    await _dbHelper.updateEvent(updatedEvent);
    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit local Event')),
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
