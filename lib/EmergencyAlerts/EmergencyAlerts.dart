import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medlink/EmergencyAlerts/PostEmergencyAlertScreen.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyAlert {
  final String id;
  final String name;
  final String location;
  final String description;
  final String contactNumber;
  final bool showContact;
  final double lat;
  final double lng;
  final DateTime timestamp;

  EmergencyAlert({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.contactNumber,
    required this.showContact,
    required this.lat,
    required this.lng,
    required this.timestamp
  });

  factory EmergencyAlert.fromMap(String id, Map<String, dynamic> data) {
    return EmergencyAlert(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      showContact: (data['contactNumber'] ?? '').toString().isNotEmpty,
      lat: (data['userLat'] ?? 0).toDouble(),
      lng: (data['userLng'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class EmergencyAlertsScreen extends StatefulWidget {
  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  Position? currentPosition;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }
  String formatTimestamp(dynamic timestamp) {
    if (timestamp is DateTime) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);
    } else {
      return '';
    }
  }

  Future<void> _getUserLocation() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {});
    } catch (e) {
      print("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) {
      return Scaffold(
        backgroundColor: Color(0xFF96B7AE),

        appBar: AppBar(
          leading:  IconButton(
            icon: Icon(Icons.keyboard_backspace, color: Colors.teal[800]),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("Emergency Alerts",style: TextStyle(color: Colors.teal[800],fontWeight: FontWeight.bold,)),
          backgroundColor: Color(0xFF96B7AE),
        ),
        body: Center(child: CircularProgressIndicator()),

      );
    }

    return Scaffold(
      appBar: AppBar(
        leading:  IconButton(
          icon: Icon(Icons.keyboard_backspace, color: Colors.teal[800]),
          onPressed: () {
            Navigator.pop(context); // ✅ Previous screen pe jaayega
          },
        ),
        title: Text("Emergency Alerts",style: TextStyle(color: Colors.teal[800],fontWeight: FontWeight.bold,)),
        backgroundColor: Color(0xFF96B7AE),
      ),
      backgroundColor: Color(0xFF96B7AE),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('posts')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var filtered = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            double lat = (data['userLat'] ?? 0).toDouble();
            double lng = (data['userLng'] ?? 0).toDouble();
            double distance = _calculateDistance(
                currentPosition!.latitude, currentPosition!.longitude, lat, lng);
            return distance <= 30;
          });

          var alerts = filtered.map((doc) {
            return EmergencyAlert.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          if (alerts.isEmpty) {
            return Center(child: Text("No nearby alerts within 30 km.", style: TextStyle(fontSize: 18, color: Colors.black54)));
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RepliesScreen(alertId: alert.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Name + Reply Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alert.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.reply, color: Colors.teal),
                              onPressed: () => _showReplyDialog(context, alert),
                            ),
                          ],
                        ),


                        // Location
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Location: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                              ),
                              TextSpan(
                                text: alert.location,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Type

                        const SizedBox(height: 4),

                        // Description
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Description: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                              ),
                              TextSpan(
                                text: alert.description,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Contact (only if showContact == true)
                        if (alert.showContact) ...[
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Contact: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                                ),
                                TextSpan(
                                  text: alert.contactNumber,
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 16),
                                ),
                              ],
                            ),
                          ),

                        ],

                        // Timestamp at Bottom Right
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatTimestamp(alert.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );


            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostEmergencyScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.white, // FAB color
      ),
    );
  }

  void _showReplyDialog(BuildContext context, EmergencyAlert alert) {
    showDialog(
      context: context,
      builder: (_) => ReplyDialog(alert: alert),
    );
  }

  /// Haversine formula to calculate distance between two points (in km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // in kilometers
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * pi / 180;
}

class ReplyDialog extends StatefulWidget {
  final EmergencyAlert alert;

  ReplyDialog({required this.alert});

  @override
  _ReplyDialogState createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _replyController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to send reply to Firestore
  Future<void> _sendReply() async {
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('replies').add({
        'alertId': widget.alert.id,
        'userId': user.uid,
        'reply': _replyController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear the reply field after sending the reply
      _replyController.clear();
      Navigator.pop(context); // Close the dialog
    } else {
      // Handle the case where the user is not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You need to be logged in to reply.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Reply to Alert"),
      content: TextField(
        controller: _replyController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "Enter your reply here",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close the dialog
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: _sendReply,
          child: Text("Send Reply"),
        ),
      ],
    );
  }
}


class RepliesScreen extends StatelessWidget {
  final String alertId;

  RepliesScreen({required this.alertId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Replies"),
        backgroundColor: Colors.teal[700], // Set background color
      ),
      backgroundColor: Colors.teal[50], // Lighter background color
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('replies')
            .where('alertId', isEqualTo: alertId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var replies = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();

          if (replies.isEmpty) {
            return Center(child: Text("No replies yet.", style: TextStyle(fontSize: 18, color: Colors.black54)));
          }

          return ListView.builder(
            itemCount: replies.length,
            itemBuilder: (context, index) {
              final reply = replies[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5, // Enhanced shadow effect
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(reply['reply'], style: TextStyle(fontSize: 18)),
                  subtitle: Text('From: ${reply['userId']}', style: TextStyle(fontSize: 16, color: Colors.black54)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}