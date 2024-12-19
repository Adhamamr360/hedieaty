import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreEventPage extends StatefulWidget {
  final Map<String, dynamic> event;
  FirestoreEventPage({required this.event});

  @override
  _FirestoreEventPageState createState() => _FirestoreEventPageState();
}

class _FirestoreEventPageState extends State<FirestoreEventPage> {
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
    if (widget.event['id'] == null || widget.event['id'].isEmpty) {
      print('Error: Document ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document ID is missing.')));
      return;
    }

    try {
      // Update the event in Firestore
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event['id'])
          .update({
        'name': _nameController.text,
        'date': _dateController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
      });

      // Update the associated gifts in Firestore
      final giftsQuery = await FirebaseFirestore.instance
          .collection('gifts')
          .where('event_id', isEqualTo: widget.event['id'])
          .get();

      for (var gift in giftsQuery.docs) {
        await gift.reference.update({
          'event': _nameController.text,  // Update the event name
          // Add any other necessary fields to update in the gifts
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event and associated gifts updated successfully.')));
      Navigator.pop(context);
    } catch (e) {
      print('Firestore Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event and associated gifts.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Firestore Event')),
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
