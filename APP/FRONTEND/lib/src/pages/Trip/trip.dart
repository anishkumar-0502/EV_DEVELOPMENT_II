import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../utilities/Loading_splash/loading.dart';
import './LocationSearchPage.dart';
class TripPage extends StatefulWidget {
  final String username;
  final int? userId;
  final String email;
  final String startingPoint;
  final String destination;

  const TripPage({
    super.key,
    required this.username,
    this.userId,
    required this.email,
    required this.startingPoint,
    required this.destination,
  });

  @override
  _TripPageState createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late GoogleMapController mapController;
  LatLng? _currentPosition;
  bool _isMapReady = false;
  final GlobalKey _mapKey = GlobalKey();
  final LatLng _center = const LatLng(20.593683, 78.962883);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    if (_currentPosition == null) {
      await _fetchCurrentLocation();
    } else {
      setState(() {
        _isMapReady = true;
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isMapReady = true;
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;

    // Load and set the map style
    String mapStyle = await rootBundle.loadString('assets/Map/map.json');
    mapController.setMapStyle(mapStyle);

    // Delay to ensure the map loads smoothly
    await Future.delayed(const Duration(milliseconds: 500));

    // Animate to the fetched current position or selected location
    if (_currentPosition != null) {
      _animateToFixedLocation();
    }
  }

  void _animateToFixedLocation() {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
          bearing: 0,
        ),
      ),
    );
  }

  void _navigateToLocationSearchPage() {
    // Navigate to location search page here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationSearch(username: widget.username, email: widget.email, userId: widget.userId)),
    );
  }

  void _navigateToDestinationSearchPage() {
    // Navigate to destination search page here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationSearch(username: widget.username, email: widget.email, userId: widget.userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Stack(
        children: [
          _isMapReady
              ? GoogleMap(
                  key: _mapKey,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? _center,
                    zoom: 10,
                  ),
                  markers: _markers,
                  zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                )
              : const TripLoadingAnimation(),

          if (_isMapReady)
            Positioned(
              bottom: 170,
              right: 10,
              child: FloatingActionButton(
                onPressed: () => mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
                ),
                backgroundColor: Colors.green,
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 44, 44, 44),
                    blurRadius: 10.0,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Plan your next trip",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Tackle your range anxiety with our hassle-free charging experience on your next trip.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _navigateToLocationSearchPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[850],
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Enter Starting point",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _navigateToDestinationSearchPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[850],
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Enter Destination",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Starting Point: ${widget.startingPoint}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'Destination: ${widget.destination}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
