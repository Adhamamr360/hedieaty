import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';

class AddEventPage extends StatefulWidget {
  final String uid; // Logged-in user's UID
  AddEventPage({required this.uid});

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _saveEvent() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields!')),
      );
      return;
    }

    final eventData = {
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'date': _selectedDate!.toIso8601String(),
    };

    try {
      // Save to SQLite
      await _dbHelper.insertEvent(eventData);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('events').add({
        ...eventData,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event added successfully!')));
      Navigator.pop(context); // Return to EventListPage
    } catch (e) {
      print('Error saving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event'),
        backgroundColor: Color(0xFFdf43a1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Event Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No date selected'
                      : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                ),
                Spacer(),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text('Save Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFdf43a1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
