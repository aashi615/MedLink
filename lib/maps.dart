import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';


class NearbyHospitalsScreen extends StatefulWidget {
  @override
  _NearbyHospitalsScreenState createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  final GeoapifyService geoapifyService = GeoapifyService();
  List<dynamic> hospitals = [];
  double? latitude;
  double? longitude;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _requestPermission() async {
    PermissionStatus status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> _getCurrentLocation() async {
    bool isPermissionGranted = await _requestPermission();
    if (!isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude = position.latitude;
      longitude = position.longitude;

      // Fetch nearby hospitals using the user's current location
      await _getNearbyHospitals(latitude!, longitude!);
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getNearbyHospitals(double lat, double lon) async {
    try {
      List<dynamic> fetchedHospitals =
      await geoapifyService.getNearbyHospitals(lat, lon);

      for (var hospital in fetchedHospitals) {
        double? hospLat = hospital['properties']['lat'];
        double? hospLon = hospital['properties']['lon'];

        if (hospLat != null && hospLon != null) {
          double distance =
          Geolocator.distanceBetween(lat, lon, hospLat, hospLon);
          hospital['calculated_distance'] = distance;
        } else {
          hospital['calculated_distance'] = double.infinity;
        }
      }

      fetchedHospitals.sort((a, b) => (a['calculated_distance'])
          .compareTo(b['calculated_distance']));

      setState(() {
        hospitals = fetchedHospitals;
      });
    } catch (e) {
      print('Error fetching hospitals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Hospitals'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: Text('Get My Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
                SizedBox(width: 12),
                if (latitude != null && longitude != null)
                  Text(
                    'Lat: ${latitude!.toStringAsFixed(4)}, Lon: ${longitude!.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 14),
                  ),
              ],
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator(color: Colors.teal)
                : hospitals.isEmpty
                ? Text('No hospitals found')
                : Expanded(
              child: ListView.builder(
                itemCount: hospitals.length,
                itemBuilder: (context, index) {
                  var hospital = hospitals[index];
                  double? distance =
                  hospital['calculated_distance'];
                  double distKm = (distance ?? 0) / 1000;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                Colors.teal.shade100,
                                child: Icon(Icons.local_hospital,
                                    color: Colors.teal, size: 28),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hospital['properties']['name'] ?? 'Unknown Hospital',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Text(
                                      '${distKm.toStringAsFixed(2)} km away',
                                      style: TextStyle(
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hospital['properties']
                                  ['address_line2'] ?? 'Address not available',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GeoapifyService {
  final String apiKey = '8cb555a8b090486fb0abeac564f5644f';
  final String baseUrl = 'https://api.geoapify.com/v2/places';

  Future<List<dynamic>> getNearbyHospitals(
      double latitude, double longitude) async {
    final String url =
        "$baseUrl?categories=healthcare.hospital&filter=circle:$longitude,$latitude,10000&bias=proximity:$longitude,$latitude&limit=20&apiKey=$apiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['features'] ?? [];
    } else {
      print('Failed to fetch hospitals: ${response.body}');
      return [];
    }
  }
}