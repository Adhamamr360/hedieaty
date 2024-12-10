import 'package:flutter/material.dart';
import '../services/db_helper.dart';

class AddGiftPage extends StatefulWidget {
  final String uid; // Logged-in user's UID
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

    await _dbHelper.insertGift({
      'uid': widget.uid,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'event': _eventController.text.trim(),
    });

    Navigator.pop(context);
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
