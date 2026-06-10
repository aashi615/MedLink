import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class PostEmergencyScreen extends StatefulWidget {
  @override
  _PostEmergencyScreenState createState() => _PostEmergencyScreenState();
}

class _PostEmergencyScreenState extends State<PostEmergencyScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  bool _showContact = false;

  @override
  void initState() {
    super.initState();
    _fetchAndStoreUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF96B7AE),

      appBar: AppBar(
        leading:  IconButton(
          icon: Icon(Icons.keyboard_backspace, color: Colors.teal[800]),
          onPressed: () {
            Navigator.pop(context); // ✅ Previous screen pe jaayega
          },
        ),
        backgroundColor: Color(0xFF96B7AE),
        title: Text("Post Emergency Alerts",style: TextStyle(color: Colors.teal[800],fontWeight: FontWeight.bold,)),

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
                _buildField(_nameController, "Name"),
                _buildField(_locationController, "Location"),
                _buildField(_descController, "Description", maxLines: 3),
                Row(
                  children: [
                    Checkbox(
                      value: _showContact,
                      onChanged: (val) => setState(() => _showContact = val!),
                    ),
                    Text("Show Contact Number", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                if (_showContact)
                  _buildField(_contactController, "Contact Number", type: TextInputType.phone),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _postAlert,
                    icon: Icon(Icons.warning_amber_rounded,color: Colors.white),
                    label: Text("Post Alert",style: TextStyle(color: Colors.white),),
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

  Future<void> _postAlert() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final desc = _descController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty || location.isEmpty || desc.isEmpty) {
      _showSnack("Please fill all required fields.");
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack("You must be logged in.");
        return;
      }

      final pos = await _getLocation();

      final postData = {
        'name': name,
        'location': location,
        'description': desc,
        'contactNumber': _showContact ? contact : '',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userLat': pos.latitude,
        'userLng': pos.longitude,
        'expireAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
      };

      String alertId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .doc(alertId)
          .set(postData);

      _showSnack("Alert posted successfully!");
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Error: ${e.toString()}");
    }
  }

  Future<void> _fetchAndStoreUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final pos = await _getLocation();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      });
    } catch (e) {
      print("Could not fetch/store location: $e");
    }
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied.");
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}