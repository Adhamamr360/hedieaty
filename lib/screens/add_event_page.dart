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
  DateTime? _selectedDate;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Format date as "YYYY-MM-DD" for storage
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Save event data locally in SQLite
  Future<void> _saveEventLocally() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
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
      'date': _formatDate(_selectedDate!), // Store as "YYYY-MM-DD"
      'number_of_gifts': 0, // Initialized to 0
    };

    try {
      // Save to SQLite
      await _dbHelper.insertEvent(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event added locally!')));
      Navigator.pop(context); // Return to EventListPage
    } catch (e) {
      print('Error saving event locally: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event locally.')),
      );
    }
  }

  // Publish event data to Firestore
  Future<void> _publishEventToFirestore() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
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
      'date': _formatDate(_selectedDate!), // Store as "YYYY-MM-DD"
      'number_of_gifts': 0, // Initialized to 0
    };

    try {
      // Save to Firestore
      await FirebaseFirestore.instance.collection('events').add({
        ...eventData,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event published to Firestore!')));
      Navigator.pop(context); // Return to EventListPage
    } catch (e) {
      print('Error publishing event to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish event.')),
      );
    }
  }

  // Pick date for the event
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
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No date selected'
                      : 'Date: ${_formatDate(_selectedDate!)}', // Show formatted date
                ),
                Spacer(),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('Select Date'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveEventLocally,
                  child: Text('Save Locally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton(
                  onPressed: _publishEventToFirestore,
                  child: Text('Publish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
