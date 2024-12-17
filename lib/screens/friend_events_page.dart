import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        final eventDate = (doc['date'] as Timestamp).toDate();
        return eventDate.isAfter(DateTime.now()); // Filter upcoming events
      })
          .map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'description': doc['description'],
          'date': (doc['date'] as Timestamp).toDate(),
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
      await FirebaseFirestore.instance.collection('gifts').doc(giftId).update({
        'status': status,
        'pledged_by': status == 'not_pledged' ? null : FirebaseAuth.instance.currentUser!.uid,
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
                        final isPledgedByYou = gift['pledged_by'] == FirebaseAuth.instance.currentUser!.uid;

                        return ListTile(
                          title: Text(gift['name']),
                          subtitle: Text('${gift['description']} - \$${gift['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status == 'not_pledged')
                                ElevatedButton(
                                  onPressed: () => _updateGiftStatus(giftId, 'pledged'),
                                  child: Text('Pledge'),
                                ),
                              if (status == 'pledged' && isPledgedByYou)
                                ElevatedButton(
                                  onPressed: () => _updateGiftStatus(giftId, 'purchased'),
                                  child: Text('Purchase'),
                                ),
                              if (status == 'pledged' && isPledgedByYou)
                                ElevatedButton(
                                  onPressed: () => _updateGiftStatus(giftId, 'not_pledged'),
                                  child: Text('Unpledge'),
                                ),
                              if (status != 'not_pledged' && !isPledgedByYou)
                                Text(
                                  status == 'purchased' ? 'Purchased' : 'Pledged',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: status == 'purchased' ? Colors.green : Colors.orange,
                                  ),
                                ),
                            ],
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
