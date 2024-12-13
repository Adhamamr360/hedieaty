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
  final TextEditingController _eventController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _saveGift() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _eventController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields!')),
      );
      return;
    }

    final giftData = {
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'event': _eventController.text.trim(),
    };

    try {
      // Save to SQLite
      await _dbHelper.insertGift(giftData);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('gifts').add({
        ...giftData,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift added successfully!')));
      Navigator.pop(context); // Go back to GiftListPage
    } catch (e) {
      print('Error saving gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add gift.')),
      );
    }
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
            TextField(
              controller: _eventController,
              decoration: InputDecoration(labelText: 'Event'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGift,
              child: Text('Save Gift'),
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
