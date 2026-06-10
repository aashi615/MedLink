import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medlink/community/postCommunity.dart';

class CommunityPost {

  final String eventName;
  final String venue;
  final String date;
  final String description;
  final DateTime timestamp;

  CommunityPost({
    required this.eventName,
    required this.venue,
    required this.date,
    required this.description,
    required this.timestamp,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> data) {
    return CommunityPost(
      eventName: data['eventName'] ?? 'No event name', // Default to 'No event name' if not available
      venue: data['venue'] ?? 'No venue', // Default to 'No venue' if not available
      date: data['date'] ?? 'No date', // Default to 'No date' if not available
      description: data['description'] ?? 'No description available.', // Default description if missing
      timestamp: (data['timestamp'] != null && data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate() // Convert Firestore Timestamp to DateTime
          : DateTime.now(), // Default to current time if null
    );
  }
}


class CommunityScreen extends StatefulWidget {
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // Function to fetch community posts from Firestore
  Future<List<CommunityPost>> fetchCommunityPosts(String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')  // Start with the 'users' collection
        .doc(userId)           // Specify the userId
        .collection('posts')   // Access the 'posts' subcollection
        .where('isCommunityPost', isEqualTo: true)  // Filter by the 'isCommunityPost' flag
        .orderBy('timestamp', descending: true)  // Order by timestamp in descending order
        .get();  // Get the snapshot from Firestore

    // Map the snapshot data into a list of CommunityPost objects
    return snapshot.docs.map((doc) {
      return CommunityPost.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Please log in to access community posts.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Community Posts", style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF96B7AE),
      ),
      backgroundColor: Color(0xFF96B7AE),
      body: FutureBuilder<List<CommunityPost>>(
        future: fetchCommunityPosts(user!.uid), // Fetch the posts based on the current user
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          var posts = snapshot.data!;

          if (posts.isEmpty) {
            return Center(child: Text("No community posts available.", style: TextStyle(fontSize: 18, color: Colors.black54)));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event name
                        Text(
                          post.eventName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // RichText for venue and date
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Venue: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                              ),
                              TextSpan(
                                text: post.venue,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 16),
                              ),
                              const TextSpan(text: '\n'),
                              const TextSpan(
                                text: 'Date: ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                              ),
                              TextSpan(
                                text: post.date,
                                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Content preview
                        Text(
                          post.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),

                        // Timestamp
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(post.timestamp),
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
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
            MaterialPageRoute(builder: (_) => CommunityPostScreen()), // Navigate to Add Post Screen
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.white, // FAB color
      ),
    );
  }
}