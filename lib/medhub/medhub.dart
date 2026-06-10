import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medlink/medhub/add_document.dart';

class MediHubHomePage extends StatelessWidget {
  const MediHubHomePage({super.key});

  // Fetch groups for the user
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('MediRecords')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1EF),
      appBar: AppBar(
        title: const Text(
          'MediHub Records',
          style: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFFE8F1EF),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No records found. Tap + to add a document."),
            );
          }

          final groups = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final groupName = groups[index]['id'];

              return ListTile(
                tileColor: Colors.white,
                leading: const Icon(Icons.folder, color: Colors.teal),
                title: Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentViewerPage(groupName: groupName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDocumentPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: "Add Document",
      ),
    );
  }
}

class DocumentViewerPage extends StatelessWidget {
  final String groupName;

  const DocumentViewerPage({super.key, required this.groupName});

  // Fetch documents for the group
  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) return [];

    try {
      final filesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('MediRecords')
          .doc(groupName)
          .collection('files')
          .orderBy('uploadedAt', descending: true)
          .get();

      if (filesSnapshot.docs.isEmpty) {
        print("No documents found for group: $groupName");
      }

      // Collect file details from Firestore directly
      List<Map<String, dynamic>> filesData = [];

      for (var doc in filesSnapshot.docs) {
        final fileName = doc['fileName'];
        final fileUrl = doc['fileUrl']; // Assuming the URL is stored here

        filesData.add({
          'fileName': fileName,
          'fileUrl': fileUrl,
        });
      }

      // Debug: Print file names and URLs
      print("Files Data: $filesData");

      return filesData;
    } catch (e) {
      print("Error fetching documents: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1EF),
      appBar: AppBar(
        title: Text(
          groupName,
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFE8F1EF),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No documents available."));
          }

          final files = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.teal),
                  title: Text(file['fileName']),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final fileUrl = file['fileUrl'];

                      if (fileUrl != null && fileUrl.isNotEmpty) {
                        // Open the file using the OpenFile plugin
                        final result = await OpenFile.open(fileUrl);

                        if (result.type != ResultType.done) {
                          // Handle error if file cannot be opened
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Unable to open file.")),
                          );
                        }
                      } else {
                        // Handle error if fileUrl is null or empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Invalid file URL.")),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



