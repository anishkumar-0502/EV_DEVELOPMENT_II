import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import './trip.dart';

class LocationSearch extends StatefulWidget {
  final String username;
  final int? userId;
  final String email;

  const LocationSearch({Key? key, required this.username, this.userId, required this.email}) : super(key: key);

  @override
  _LocationSearchState createState() => _LocationSearchState();
}

class _LocationSearchState extends State<LocationSearch> {
  final List<String> recentLocations = [
    "Coimbatore, Tamil Nadu, India",
    "Vega City Mall Road, Bengaluru, Karnataka, India",
  ];
  final List<String> tripHistory = [
    "Coimbatore → Vega City Mall Road",
    "17th Cross Rd → Coimbatore",
    "7th Main Rd → Coimbatore",
  ];

  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> filteredLocations = [];

  Future<List<Map<String, dynamic>>> fetchLocations(String query) async {
    const String apiKey = 'AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco'; // Replace with your actual API key
    final String apiUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> predictions = data['predictions'] ?? [];

        List<Map<String, dynamic>> locations = [];

        for (var item in predictions) {
          String placeId = item['place_id'];
          String name = item['description'];

          final detailsResponse = await http.get(Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey'));

          if (detailsResponse.statusCode == 200) {
            Map<String, dynamic> detailsData = json.decode(detailsResponse.body);
            var locationData = detailsData['result']['geometry']['location'];

            double latitude = locationData['lat'];
            double longitude = locationData['lng'];

            String address = item['structured_formatting']['secondary_text'] ?? '';

            locations.add({
              'name': name,
              'address': address,
              'latitude': latitude,
              'longitude': longitude,
            });
          }
        }

        return locations.where((location) => location['address']!.contains('India')).toList();
      } else {
        throw Exception('Failed to load locations, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }

  void _filterLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredLocations = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> locations = await fetchLocations(query);

    setState(() {
      filteredLocations = locations;
      _isLoading = false;
    });
  }

  void _fetchCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String currentLocation = "${place.street}, ${place.locality}, ${place.administrativeArea}";
      setState(() {
        _startingPointController.text = currentLocation;
      });
    }
  }

  void _searchLocation(String query) {
    setState(() {
      if (!recentLocations.contains(query)) {
        recentLocations.insert(0, query);
      }
    });
  }

  Future<void> _navigateToTripPage() async {
    if (_startingPointController.text.isNotEmpty && _destinationController.text.isNotEmpty) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripPage(
            startingPoint: _startingPointController.text,
            destination: _destinationController.text, username: widget.username, email: widget.email, userId: widget.userId
          ),
        ),
      );

      if (result != null && result is Map<String, String>) {
        setState(() {
          _startingPointController.text = result['startingPoint'] ?? _startingPointController.text;
          _destinationController.text = result['destination'] ?? _destinationController.text;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both Starting Point and Destination")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Location Search', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Starting Point and Destination Input Fields
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _startingPointController,
                    decoration: InputDecoration(
                      hintText: "Starting Point",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.circle, color: Colors.blue[300]),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filterLocations,
                  ),
                  const Divider(color: Colors.grey),
                  // Fetching Locations below Starting Point Field
                  if (_isLoading)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // Makes the text scrollable
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Fetching location...",
                          style: TextStyle(color: Colors.orange, fontSize: 18),
                        ),
                      ),
                    )
                  else if (filteredLocations.isNotEmpty)
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var location in filteredLocations)
                            ListTile(
                              title: Text(
                                location['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                location['address'],
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              onTap: () {
                                setState(() {
                                  _startingPointController.text = location['name'];
                                  filteredLocations = [];
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  // Destination Input Field
                  TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      hintText: "Enter Destination",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.location_on, color: Colors.red[300]),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      _searchLocation(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Your Location Button
            GestureDetector(
              onTap: _fetchCurrentLocation,
              child: Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue[300]),
                  const SizedBox(width: 8),
                  const Text(
                    "Your Location",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent Locations
            const Text(
              "Recent",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: recentLocations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.place, color: Colors.grey[500]),
                    title: Text(
                      recentLocations[index],
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    onTap: () {
                      setState(() {
                        _startingPointController.text = recentLocations[index];
                      });
                    },
                  );
                },
              ),
            ),
            // Confirm button to navigate to TripPage
            GestureDetector(
              onTap: _navigateToTripPage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                color: Colors.blue,
                child: const Text(
                  "Confirm",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
