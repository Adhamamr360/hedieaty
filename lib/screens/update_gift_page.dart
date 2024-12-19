import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';

class UpdateGiftPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> gift; // Pass the gift details
  final bool isFirestore;

  UpdateGiftPage({required this.uid, required this.gift, required this.isFirestore});

  @override
  _UpdateGiftPageState createState() => _UpdateGiftPageState();
}

class _UpdateGiftPageState extends State<UpdateGiftPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _category;

  final List<String> _categories = ['Electronics', 'Books', 'Clothes', 'Other'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with gift data
    _nameController.text = widget.gift['name'] ?? '';
    _descriptionController.text = widget.gift['description'] ?? '';
    _priceController.text = widget.gift['price'].toString();
    _category = widget.gift['category'] ?? 'Uncategorized';
  }

  Future<void> _updateGift() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    double? price;
    try {
      price = double.parse(_priceController.text.trim());
      if (price < 0) throw FormatException();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid positive price.')),
      );
      return;
    }

    final updatedGift = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': price,
      'category': _category,
    };

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      if (widget.isFirestore) {
        // Update Firestore gift
        await FirebaseFirestore.instance
            .collection('gifts')
            .doc(widget.gift['id'])
            .update(updatedGift);
      } else {
        // Update local SQLite gift
        updatedGift['id'] = widget.gift['id'];
        await _dbHelper.updateGift(updatedGift);
      }

      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift updated successfully.')),
      );
      Navigator.pop(context); // Go back to the gift list
    } catch (e) {
      Navigator.pop(context); // Close the loading dialog
      print('Error updating gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update gift.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Gift'),
        backgroundColor: Colors.purpleAccent,
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
            DropdownButtonFormField<String>(
              value: _category,
              onChanged: (value) => setState(() => _category = value),
              items: _categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              )).toList(),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateGift,
              child: Text('Update Gift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
