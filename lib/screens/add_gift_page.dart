import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';

class AddGiftPage extends StatefulWidget {
  final String uid;
  AddGiftPage({required this.uid});

  @override
  _AddGiftPageState createState() => _AddGiftPageState();
}

class _AddGiftPageState extends State<AddGiftPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _localEvents = [];
  List<Map<String, dynamic>> _firestoreEvents = [];
  int? _selectedLocalEventId; // Store event ID for local events
  String? _selectedFirestoreEvent; // Store Firestore event ID

  @override
  void initState() {
    super.initState();
    _loadLocalEvents();
    _loadFirestoreEvents();
  }

  Future<void> _loadLocalEvents() async {
    final events = await _dbHelper.getEventsForUser(widget.uid);
    setState(() {
      _localEvents = events;
    });
  }

  Future<void> _loadFirestoreEvents() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('uid', isEqualTo: widget.uid)
        .get();

    setState(() {
      _firestoreEvents = querySnapshot.docs
          .map((doc) => {
        'id': doc.id,
        'name': doc['name'],
      })
          .toList();
    });
  }

  Future<void> _saveGiftLocally() async {
    if (!_validateInputs(isLocal: true)) return;

    final giftData = {
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'event': _selectedLocalEventId.toString(), // Convert event ID to string
    };

    try {
      // Save to SQLite
      await _dbHelper.insertGift(giftData);

      // Increment gift count for the selected event
      await _dbHelper.incrementEventGiftCount(_selectedLocalEventId!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift added locally!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error saving gift locally: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save gift locally.')),
      );
    }
  }

  Future<void> _publishGiftToFirestore() async {
    if (!_validateInputs(isLocal: false)) return;

    final giftData = {
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'event': _firestoreEvents.firstWhere((event) => event['id'] == _selectedFirestoreEvent)['name'], // Get event name
      'event_id': _selectedFirestoreEvent, // Store the event ID in a separate field
      'created_at': Timestamp.now(),
    };

    try {
      // Save the gift to Firestore
      await FirebaseFirestore.instance.collection('gifts').add(giftData);

      // Increment gift count for the associated Firestore event
      await FirebaseFirestore.instance.collection('events').doc(_selectedFirestoreEvent).update({
        'number_of_gifts': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift published to Firestore!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error publishing gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish gift.')),
      );
    }
  }


  bool _validateInputs({required bool isLocal}) {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        (isLocal ? _selectedLocalEventId == null : _selectedFirestoreEvent == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and select an event!')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Gift'),
        backgroundColor: Color(0xFFdf43a1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Gift Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<int>(
              value: _selectedLocalEventId,
              hint: Text('Select Local Event'),
              items: _localEvents.map((event) {
                return DropdownMenuItem<int>(
                  value: event['id'] as int, // Use event ID
                  child: Text(event['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocalEventId = value;
                  _selectedFirestoreEvent = null; // Clear Firestore selection
                });
              },
              decoration: InputDecoration(
                labelText: 'Local Event',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedFirestoreEvent,
              hint: Text('Select Firestore Event'),
              items: _firestoreEvents.map((event) {
                return DropdownMenuItem<String>(
                  value: event['id'] as String,
                  child: Text(event['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFirestoreEvent = value;
                  _selectedLocalEventId = null; // Clear Local selection
                });
              },
              decoration: InputDecoration(
                labelText: 'Firestore Event',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveGiftLocally,
                  child: Text('Save Locally'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton(
                  onPressed: _publishGiftToFirestore,
                  child: Text('Publish to Firestore'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFdf43a1),
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
