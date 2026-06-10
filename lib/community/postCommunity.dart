import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPostScreen extends StatefulWidget {
  @override
  _CommunityPostScreenState createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _eventNameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF96B7AE),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_backspace, color: Colors.teal[800]),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Color(0xFF96B7AE),
        title: Text("Post Community Event", style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildField(_eventNameController, "Event Name"),
                _buildField(_venueController, "Venue"),
                _buildField(_dateController, "Date (e.g. 28 April 2025)"),
                _buildField(_descController, "Description", maxLines: 3),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _postCommunityEvent,
                    icon: Icon(Icons.event, color: Colors.white),
                    label: Text("Post Event", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.teal.shade800),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _postCommunityEvent() async {
    final eventName = _eventNameController.text.trim();
    final venue = _venueController.text.trim();
    final date = _dateController.text.trim();
    final desc = _descController.text.trim();

    if (eventName.isEmpty || venue.isEmpty || date.isEmpty || desc.isEmpty) {
      _showSnack("Please fill all fields.");
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack("You must be logged in.");
        return;
      }

      final postData = {
        'eventName': eventName,
        'venue': venue,
        'date': date,
        'description': desc,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'isCommunityPost': true, // Add the boolean flag to identify the post as a community post
      };

      // Add the event post to the posts subcollection under the user's posts
      final postRef = await FirebaseFirestore.instance
          .collection('users')  // Users collection
          .doc(user.uid)        // Current user document
          .collection('posts')  // Posts subcollection under the user
          .add(postData);       // Automatically generate a post ID

      // Fetch the Post ID
      String postId = postRef.id;
      print("New Post ID: $postId");

      _showSnack("Community event posted!");
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Example method to fetch posts for a specific user
  Future<void> fetchUserPosts(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')   // Start with the 'users' collection
          .doc(userId)            // Specify the userId
          .collection('posts')    // Access the 'posts' subcollection
          .where('isCommunityPost', isEqualTo: true)  // Filter by the 'isCommunityPost' flag
          .orderBy('timestamp', descending: true)  // Optional: order by timestamp
          .get();

      // Handle fetched data
      snapshot.docs.forEach((doc) {
        print("Post ID: ${doc.id}, Event Name: ${doc['eventName']}");
      });
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }
}