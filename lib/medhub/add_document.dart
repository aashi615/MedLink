import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddDocumentPage extends StatefulWidget {
  @override
  _AddDocumentPageState createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  PlatformFile? _selectedFile;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    final groupName = _groupController.text.trim();
    final description = _descriptionController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (_selectedFile != null && groupName.isNotEmpty && userId != null) {
      try {
        final groupDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('MediRecords')
            .doc(groupName);

        // Save group metadata in Firestore (this can be optional, depending on what metadata you want for each group)
        await groupDocRef.set({
          'groupName': groupName,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to prevent overwriting if group already exists

        // Generate a unique file ID
        final fileId = FirebaseFirestore.instance.collection('users')
            .doc(userId)
            .collection('MediRecords')
            .doc(groupName)
            .collection('files')
            .doc().id;  // Generate unique ID

        final fileUrl = await _getFileUrl(_selectedFile!);

        if (fileUrl.isNotEmpty) {
          // Store the file metadata in the Firestore 'files' sub-collection of the group
          await groupDocRef.collection('files').doc(fileId).set({
            'fileName': _selectedFile!.name,
            'fileUrl': fileUrl,
            'uploadedAt': FieldValue.serverTimestamp(),
            'description': description,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Document uploaded successfully.")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to get URL for the file.")),
          );
        }

        // Clear fields after successful upload
        setState(() {
          _selectedFile = null;
          _groupController.clear();
          _descriptionController.clear();
        });
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a document and enter group name")),
      );
    }
  }

  Future<String> _getFileUrl(PlatformFile file) async {
    // Replace this with actual code to generate or fetch the file URL
    // For example, upload the file to a third-party hosting service and get the URL

    // If you're fetching the URL from a hosting service:
    // final url = await YourFileHostingService.uploadFile(file);

    // For now, just simulating returning a URL:
    return "https://example.com/files/${file.name}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF96B7AE),
      appBar: AppBar(
        title: Text(
          "Add Medical Documents",
          style: TextStyle(
            color: Colors.teal[800],
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF96B7AE),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Upload Document",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal[800],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text("Select File"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _pickFile, // Directly pick file
                ),
                if (_selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "${_selectedFile!.name} selected",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                SizedBox(height: 25),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description / Key Points",
                    prefixIcon: Icon(Icons.description),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _groupController,
                  decoration: InputDecoration(
                    labelText: "Group Name (e.g., Myself, Mother)",
                    prefixIcon: Icon(Icons.group),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text("Upload Document", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}
