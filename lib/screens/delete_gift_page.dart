import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_helper.dart';

class DeleteGiftPage extends StatelessWidget {
  final Map<String, dynamic> gift;
  final bool isFirestore;
  final Future<void> Function() loadGifts;

  DeleteGiftPage({required this.gift, required this.isFirestore, required this.loadGifts});

  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _deleteGift(BuildContext context) async {
    try {
      if (isFirestore) {
        // Step 1: Delete gift from Firestore
        await FirebaseFirestore.instance.collection('gifts').doc(gift['id']).delete();


        final eventRef = FirebaseFirestore.instance.collection('events').doc(gift['event_id']);
        final eventSnapshot = await eventRef.get();

        if (eventSnapshot.exists) {
          final eventData = eventSnapshot.data();
          int giftCount = eventData?['number_of_gifts'] ?? 0;

          if (giftCount > 0) {
            // Step 3: Decrement the gift count
            await eventRef.update({
              'number_of_gifts': FieldValue.increment(-1),
            });
            print('number_of_gifts decremented successfully.');
          } else {
            print('number_of_gifts is already zero or missing.');
          }
        } else {
          print('Event document does not exist for ID: ${gift['event_id']}');
        }
      } else {
        // For local gifts, use the gift's ID to delete from local database
        await _dbHelper.deleteGift(gift);
      }

      // Step 4: Show feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift deleted successfully!')),
      );

      // Reload gifts after deletion
      await loadGifts();

      // Navigate back after deletion
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors
      print('Error deleting gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete gift.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Gift'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Are you sure you want to delete the following gift?',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            Text('Name: ${gift['name']}'),
            Text('Category: ${gift['category']}'),
            Text('Price: \$${gift['price']}'),
            Text('Event: ${gift['event']}'),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _deleteGift(context),
              child: Text('Delete Gift'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // Cancel button
              child: Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
