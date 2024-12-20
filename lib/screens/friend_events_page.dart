import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class FriendEventsPage extends StatefulWidget {
  final String friendUid;
  final String friendName;

  FriendEventsPage({required this.friendUid, required this.friendName});

  @override
  _FriendEventsPageState createState() => _FriendEventsPageState();
}

class _FriendEventsPageState extends State<FriendEventsPage> {
  List<Map<String, dynamic>> _friendEvents = []; // Non-nullable list

  @override
  void initState() {
    super.initState();
    _loadFriendEvents();
  }

  Future<void> _loadFriendEvents() async {
    try {
      final eventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('uid', isEqualTo: widget.friendUid)
          .get();

      final List<Map<String, dynamic>> friendEvents = eventsQuery.docs
          .where((doc) {
        final eventDateString = doc['date']; // Date as String (yyyy-MM-dd)
        DateTime eventDate;

        try {
          eventDate = DateTime.parse(eventDateString); // Parse the string into a DateTime
        } catch (e) {
          print('Error parsing event date: $e');
          return false; // Skip this event if date parsing fails
        }

        return eventDate.isAfter(DateTime.now()); // Filter upcoming events
      })
          .map((doc) {
        final eventDateString = doc['date']; // Date as String
        DateTime eventDate = DateTime.parse(eventDateString); // Parse the date string

        // Format the event date as yyyy-MM-dd
        final formattedDate = DateFormat('yyyy-MM-dd').format(eventDate);

        return {
          'id': doc.id,
          'name': doc['name'],
          'description': doc['description'],
          'date': formattedDate, // Use the formatted date
        };
      })
          .toList();

      setState(() {
        _friendEvents = friendEvents;
      });
    } catch (e) {
      print('Error loading friend events: $e');
    }
  }

  Future<void> _updateGiftStatus(String giftId, String status) async {
    try {
      String? pledgedByUser = status == 'not_pledged' ? null : FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('gifts').doc(giftId).update({
        'status': status,
        'pledged_by': pledgedByUser,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gift status updated.')));
      _loadFriendEvents(); // Reload gifts
    } catch (e) {
      print('Error updating gift status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.friendName}\'s Events'),
        backgroundColor: Color(0xFFdf43a1),
      ),
      body: _friendEvents.isEmpty
          ? Center(child: Text('${widget.friendName} has no upcoming events.'))
          : ListView.builder(
        itemCount: _friendEvents.length,
        itemBuilder: (context, index) {
          final event = _friendEvents[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text(event['name']),
              subtitle: Text('${event['description']} - ${event['date']}'),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('gifts')
                      .where('event_id', isEqualTo: event['id'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final gifts = snapshot.data?.docs ?? [];
                    if (gifts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('No gifts assigned to this event.'),
                      );
                    }

                    return Column(
                      children: gifts.map((giftDoc) {
                        final gift = giftDoc.data() as Map<String, dynamic>;
                        final giftId = giftDoc.id;
                        final status = gift['status'] ?? 'not_pledged';
                        final pledgedByUser = gift['pledged_by'];
                        final isPledgedByYou = pledgedByUser == FirebaseAuth.instance.currentUser!.uid;
                        final isPurchasedByYou = status == 'purchased' && pledgedByUser == FirebaseAuth.instance.currentUser!.uid;

                        return Container(
                          color: status == 'purchased'
                              ? Colors.red.withOpacity(0.2)
                              : status == 'pledged'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.transparent,
                          child: ListTile(
                            leading: Icon(Icons.card_giftcard, color: Colors.purple), // Gift icon next to the gift
                            title: Text(gift['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Event: ${event['name']}'),
                                Text('Category: ${gift['category']}'),
                                Text('Price: \$${gift['price']}'),
                                Text('Description: ${gift['description']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (status == 'not_pledged')
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Show the Lottie animation dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: Lottie.asset(
                                            'assets/animations/Tick.json', // Animation for "Pledge"
                                            repeat: false,
                                            onLoaded: (composition) {
                                              Future.delayed(composition.duration, () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              });
                                            },
                                          ),
                                        ),
                                      );

                                      // Update the gift status
                                      await _updateGiftStatus(giftId, 'pledged');
                                    },
                                    child: Text('Pledge'),
                                  ),
                                if (status == 'pledged' && isPledgedByYou)
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Show the Lottie animation dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: Lottie.asset(
                                            'assets/animations/Money.json', // Animation for "Purchase"
                                            repeat: false,
                                            onLoaded: (composition) {
                                              Future.delayed(composition.duration, () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              });
                                            },
                                          ),
                                        ),
                                      );

                                      // Update the gift status
                                      await _updateGiftStatus(giftId, 'purchased');
                                    },
                                    child: Text('Purchase'),
                                  ),
                                if (status == 'pledged' && isPledgedByYou)
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Show the Lottie animation dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: Lottie.asset(
                                            'assets/animations/Sad.json', // Animation for "Unpledge"
                                            repeat: false,
                                            onLoaded: (composition) {
                                              Future.delayed(composition.duration, () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              });
                                            },
                                          ),
                                        ),
                                      );

                                      // Update the gift status
                                      await _updateGiftStatus(giftId, 'not_pledged');
                                    },
                                    child: Text('Unpledge'),
                                  ),
                                if (status == 'purchased' && isPurchasedByYou)
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Show the Lottie animation dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: Lottie.asset(
                                            'assets/animations/Sad.json', // Animation for "Unpurchase"
                                            repeat: false,
                                            onLoaded: (composition) {
                                              Future.delayed(composition.duration, () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              });
                                            },
                                          ),
                                        ),
                                      );

                                      // Update the gift status
                                      await _updateGiftStatus(giftId, 'pledged');
                                    },
                                    child: Text('Unpurchase'),
                                  ),
                                if (status != 'not_pledged' && !isPledgedByYou)
                                  Text(
                                    status == 'purchased' ? 'Purchased' : 'Pledged',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: status == 'purchased' ? Colors.red : Colors.green,
                                    ),
                                  ),
                              ],
                            ),

                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
