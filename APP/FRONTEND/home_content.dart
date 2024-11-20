// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:convert';
// import 'package:shimmer/shimmer.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import '../Charging/charging.dart';
// import '../../utilities/QR/qrscanner.dart';
// import '../../utilities/Alert/alert_banner.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:ui' as ui;
// import 'dart:async';
// import 'package:cool_alert/cool_alert.dart';
// import '../../service/location.dart';
// import 'package:share_plus/share_plus.dart';
// class HomeContent extends StatefulWidget {
//   final String username;
//   final int? userId;
//     final String email;


//   const HomeContent({super.key, required this.username, required this.userId, required this.email});

//   @override
//   _HomeContentState createState() => _HomeContentState();
// }

// class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
//   final GlobalKey _mapKey = GlobalKey(); // Global key for map widget
//   final TextEditingController _searchController = TextEditingController();
//   String searchChargerID = '';
//   List availableChargers = [];
//   List recentSessions = [];
//   String activeFilter = 'All Chargers';
//   bool isLoading = true;
//   GoogleMapController? mapController;
//   LatLng? _currentPosition;
//   LatLng? _selectedPosition; // To store the selected marker's position
//   final LatLng _center = const LatLng(12.909746, 77.606360);
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {}; // To store the route polylines
//   bool isSearching = false;
//   bool areMapButtonsEnabled = false;
//   MarkerId? _previousMarkerId; // To track the previously selected marker
//   StreamSubscription<Position>? _positionStreamSubscription;
//   bool _isFetchingLocation = false; // Ensure initialization
//   LatLng? _previousPosition;
//   double? _previousBearing;
//   bool _isCheckingPermission = false; // Flag to prevent repeated permission checks
//   static const String apiKey = 'AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco';

//  @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _checkLocationPermission(); // Check permissions on initialization
//     _updateMarkers();
//     activeFilter = 'All Chargers';
//     fetchAllChargers();
//     _startLiveTracking(); // Start live tracking
// }


//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _positionStreamSubscription?.cancel(); // Cancel the subscription
//     super.dispose();
//   }


//   Future<void> _checkLocationPermission() async {
//     if (_isCheckingPermission) return; // Prevent multiple permission checks

//     _isCheckingPermission = true;

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Prompt user to enable location services
//       await _showLocationServicesDialog();
//       _isCheckingPermission = false;
//       return;
//     }

//     PermissionStatus permission = await Permission.location.request();
//     if (permission.isGranted) {
//       await _getCurrentLocation();
//     } else if (permission.isDenied) {
//       // Show a dialog explaining why permissions are needed
//       await _showPermissionDeniedDialog();
//     } else if (permission.isPermanentlyDenied) {
//       // Guide the user to app settings
//       await _showPermanentlyDeniedDialog();
//     }

//     _isCheckingPermission = false;
//   }

// // This method is already present, but you should keep this logic to handle camera animation
//   Future<void> _getCurrentLocation() async {
//     // Check if the location permission is granted before attempting to fetch the location
//     PermissionStatus permission = await Permission.location.status;
//     if (permission.isDenied) {
//       // If permission is denied, show the permission denied dialog
//       await _showPermissionDeniedDialog();
//       return;
//     } else if (permission.isPermanentlyDenied) {
//       // If permission is permanently denied, show the permanently denied dialog
//       await _showPermanentlyDeniedDialog();
//       return;
//     }

//     // If the permission is granted, proceed to fetch the location
//     if (_isFetchingLocation) return;

//     setState(() {
//       _isFetchingLocation = true;
//     });

//     try {
//       LatLng? currentLocation = await LocationService.instance.getCurrentLocation();

//       if (currentLocation != null) {
//         // Update the current position
//         setState(() {
//           _currentPosition = currentLocation;
//         });

//         if (mapController != null) {
//           // Smoothly animate the camera to the new position
//           await mapController!.animateCamera(
//             CameraUpdate.newCameraPosition(
//               CameraPosition(
//                 target: _currentPosition!,
//                 zoom: 18.0,
//                 tilt: 45.0,
//                 bearing: _previousBearing ?? 0,
//               ),
//             ),
//           );
//         }

//         // Update the map markers with the new position
//         await _updateCurrentLocationMarker(_previousBearing ?? 0);
//       } else {
//         print('Current location could not be determined.');
//       }
//     } catch (e) {
//       print('Error occurred while fetching the current location: $e');
//     } finally {
//       setState(() {
//         _isFetchingLocation = false;
//       });
//     }
//   }


//   @override void didChangeAppLifecycleState(AppLifecycleState state) async {
//     if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
//       // Check if location services are enabled when returning to the app
//       bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//       if (isLocationEnabled) {
//         _reloadPage(); // Reload your content or update the UI
//       } else {
//         _showLocationServicesDialog();
//       }
//     }
//   }

//   Future<void> _showLocationServicesDialog() async {
//     return CoolAlert.show(
//       context: context,
//       type: CoolAlertType.custom,
//       widget: Column(
//         children: [
//           const SizedBox(height: 16.0),
//           const Text(
//             'Enable Location',
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(height: 8.0),
//           const Text(
//             'Location services are required to use this feature. Please enable location services in your phone settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.black),
//           ),
//         ],
//       ),
//       confirmBtnText: 'Settings',
//       showCancelBtn: true,
//       confirmBtnColor: Colors.blue,
//       barrierDismissible: false, // Prevent closing by tapping outside
//       onConfirmBtnTap: () async {
//         await Geolocator.openLocationSettings(); // Open the location settings
//       },
//     );
//   }
  
//   Future<void> _showPermissionDeniedDialog() async {
//   return CoolAlert.show(
//     context: context,
//     type: CoolAlertType.custom, // Changed to custom
//     widget: Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Column(
//         children: [
//           const Text(
//             'Location Permission Required',
//             style: TextStyle(
//                 fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(height: 8.0),
//           const Text(
//             'This app requires location permissions to function correctly. Please grant location permissions in settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.black),
//           ),
//         ],
//       ),
//     ),
//     confirmBtnText: 'Settings',
//     cancelBtnText: 'Cancel',
//     showCancelBtn: true,
//     confirmBtnColor: Colors.blue,
//     barrierDismissible: false,
//     onConfirmBtnTap: () {
//       openAppSettings();
//     },
//   );
// }

//   Future<void> _showPermanentlyDeniedDialog() async {
//   return CoolAlert.show(
//     context: context,
//     type: CoolAlertType.custom, // Changed to custom
//     widget: Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Column(
//         children: [
//           const Text(
//             'Location Permission Required',
//             style: TextStyle(
//                 fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(height: 8.0),
//           const Text(
//             'Location permissions are permanently denied. Please enable them in the app settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.black),
//           ),
//         ],
//       ),
//     ),
//     confirmBtnText: 'Settings',
//     cancelBtnText: 'Cancel',
//     showCancelBtn: true,
//     confirmBtnColor: Colors.blue,
//     barrierDismissible: false,
//     onConfirmBtnTap: () {
//       openAppSettings();
//     },
//   );
// }


// void _reloadPage() {
//   setState(() {
//     // Update the state to trigger a reload of the HomeContent
//     initState(); // Fetch chargers again if necessary
//   });
// }



//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//     rootBundle.loadString('assets/Map/map.json').then((String mapStyle) {
//       mapController?.setMapStyle(mapStyle);
//     });

//     if (_currentPosition != null) {
//       mapController?.animateCamera(
//         CameraUpdate.newLatLng(_currentPosition!),
//       );
//       _updateMarkers();
//     }
//   }

// Future<String> _getPlaceName(LatLng position) async {
//   final String url =
//       'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

//   final response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> data = json.decode(response.body);
//     if (data['results'].isNotEmpty) {
//       return data['results'][0]['formatted_address'];
//     } else {
//       return "Unknown Location";
//     }
//   } else {
//     throw Exception('Failed to fetch place name');
//   }
// }

// Future<String> _getAddress(LatLng position) async {
//   final String url =
//       'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

//   final response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> data = json.decode(response.body);
//     if (data['results'].isNotEmpty) {
//       return data['results'][0]['formatted_address'];
//     } else {
//       return "Unknown Address";
//     }
//   } else {
//     throw Exception('Failed to fetch address');
//   }
// }

// Future<String> _calculateDistance(LatLng start, LatLng end) async {
//   double distanceInMeters = Geolocator.distanceBetween(
//     start.latitude,
//     start.longitude,
//     end.latitude,
//     end.longitude,
//   );
//   double distanceInKm = distanceInMeters / 1000.0;
//   return "${distanceInKm.toStringAsFixed(1)} Km";
// }


// Future<Map<String, String>> _calculateDurationAndDistance(LatLng start, LatLng end) async {
//   final String url =
//       'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey';

//   final response = await http.get(Uri.parse(url));

//   if (response.statusCode == 200) {
//     final Map<String, dynamic> data = json.decode(response.body);
//     if (data['routes'].isNotEmpty) {
//       final String duration = data['routes'][0]['legs'][0]['duration']['text'];
//       final String distance = data['routes'][0]['legs'][0]['distance']['text'];
//       return {'duration': duration, 'distance': distance};
//     } else {
//       return {'duration': "Duration not available", 'distance': "Distance not available"};
//     }
//   } else {
//     throw Exception('Failed to fetch duration and distance');
//   }
// }

// Future<void> _onMarkerTapped(MarkerId markerId, LatLng position) async {
//   setState(() {
//     _selectedPosition = position;
//     areMapButtonsEnabled = true;
//   });

//   // Extract the chargerId from the MarkerId
//   String chargerId = markerId.value;

//   // Change the marker icon to the selected icon
//   BitmapDescriptor newIcon =
//       await _getIconFromAsset('assets/icons/EV_location_green.png');
//   BitmapDescriptor defaultIcon =
//       await _getIconFromAssetred('assets/icons/EV_location_red.png');

//   setState(() {
//     // Clear existing polylines when a new marker is selected
//     _polylines.clear();

//     // Revert the previous marker icon to default if it exists
//     if (_previousMarkerId != null) {
//       _markers = _markers.map((marker) {
//         if (marker.markerId == _previousMarkerId) {
//           return marker.copyWith(iconParam: defaultIcon);
//         }
//         return marker;
//       }).toSet();
//     }

//     // Update the icon for the newly selected marker
//     _markers = _markers.map((marker) {
//       if (marker.markerId == markerId) {
//         _previousMarkerId = marker.markerId;
//         return marker.copyWith(iconParam: newIcon);
//       }
//       return marker;
//     }).toSet();
//   });

//   // Fetch place name, address, and duration and distance if both current and selected positions are available
//   if (_currentPosition != null && _selectedPosition != null) {
//     final placeName = await _getPlaceName(position);
//     final address = await _getAddress(position);
//     final durationAndDistance = await _calculateDurationAndDistance(_currentPosition!, _selectedPosition!);

//     // Pass the chargerId to _showCustomRouteDialog
//     _showCustomRouteDialog(
//       placeName,
//       address,
//       durationAndDistance['duration']!,
//       durationAndDistance['distance']!,
//       chargerId, // Pass the extracted chargerId
//     );
//   }
// }

// Future<void> _onNavigateButtonPressed() async {
//   if (_currentPosition != null && _selectedPosition != null) {
//     // Animate the camera to show the route
//     LatLngBounds bounds = LatLngBounds(
//       southwest: LatLng(
//         min(_currentPosition!.latitude, _selectedPosition!.latitude),
//         min(_currentPosition!.longitude, _selectedPosition!.longitude),
//       ),
//       northeast: LatLng(
//         max(_currentPosition!.latitude, _selectedPosition!.latitude),
//         max(_currentPosition!.longitude, _selectedPosition!.longitude),
//       ),
//     );

//     CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
//     await mapController?.animateCamera(cameraUpdate);

//     // Optionally, you can add a further zoom effect to the destination
//     await Future.delayed(const Duration(seconds: 1)); // Wait for the first animation to finish
//     await mapController?.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: _selectedPosition!,
//           zoom: 18.0,
//           bearing: _previousBearing ?? 0,
//           tilt: 45.0,
//         ),
//       ),
//     );
//   }
// }

// void _showCustomRouteDialog(String placeName, String address, String duration, String distance, String chargerId) { // Add chargerId
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: false,
//     builder: (BuildContext context) {
//       return Container(
//         height: MediaQuery.of(context).size.height * 0.38,
//         child: CustomRouteDialog(        
//           placeName: placeName,
//           duration: duration,
//           distance: distance,
//           chargerId: chargerId, // Pass the chargerId here
//         ),
//       );
//     },
//   );
// }


// void _onMapTapped(LatLng position) async {
//   setState(() {
//     areMapButtonsEnabled = false;
//     _polylines.clear(); // Clear the route when the map is tapped elsewhere
//   });

//   if (_previousMarkerId != null) {
//     // Load the custom red icon
//     BitmapDescriptor defaultIcon = await _getIconFromAssetred('assets/icons/EV_location_red.png');

//     setState(() {
//       // Update the marker with the red icon
//       _markers = _markers.map((marker) {
//         if (marker.markerId == _previousMarkerId) {
//           return marker.copyWith(
//             iconParam: defaultIcon,
//           );
//         }
//         return marker;
//       }).toSet();

//       // Reset the previous marker ID
//       _previousMarkerId = null;
//     });
//   }
// }


//   Future<BitmapDescriptor> _getIconWithOutline(
//       IconData iconData,
//       Color iconColor,
//       double size,
//       Color outlineColor,
//       double outlineWidth) async {
//     final pictureRecorder = ui.PictureRecorder();
//     final canvas = Canvas(pictureRecorder);

//     final paint = Paint()
//       ..color = outlineColor
//       ..style = PaintingStyle.fill;

//     final outlineRadius = size / 2 + outlineWidth;

//     // Draw the outline (a circle with the specified outline color)
//     canvas.drawCircle(
//       Offset(outlineRadius, outlineRadius),
//       outlineRadius,
//       paint,
//     );

//     // Draw the icon
//     final textPainter = TextPainter(textDirection: TextDirection.ltr)
//       ..text = TextSpan(
//         text: String.fromCharCode(iconData.codePoint),
//         style: TextStyle(
//           fontSize: size,
//           fontFamily: iconData.fontFamily,
//           color: iconColor,
//         ),
//       )
//       ..layout();

//     textPainter.paint(
//       canvas,
//       Offset(outlineWidth, outlineWidth),
//     );

//     final picture = pictureRecorder.endRecording();
//     final img = await picture.toImage(
//         (outlineRadius * 2).toInt(), (outlineRadius * 2).toInt());
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(buffer);
//   }

//   Future<BitmapDescriptor> _getIconFromAsset(String assetPath,
//       {int width = 300, int height = 300}) async {
//     final byteData = await rootBundle.load(assetPath);
//     final Uint8List bytes = byteData.buffer.asUint8List();

//     // Decode the image from bytes
//     final ui.Codec codec = await ui.instantiateImageCodec(
//       bytes,
//       targetWidth: width,
//       targetHeight: height,
//     );
//     final ui.FrameInfo frameInfo = await codec.getNextFrame();

//     // Convert the image to bytes
//     final ByteData? resizedByteData =
//         await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(resizedBytes);
//   }

//   Future<BitmapDescriptor> _getIconFromAssetred(String assetPath,
//       {int width = 230, int height = 230}) async {
//     final byteData = await rootBundle.load(assetPath);
//     final Uint8List bytes = byteData.buffer.asUint8List();

//     // Decode the image from bytes
//     final ui.Codec codec = await ui.instantiateImageCodec(
//       bytes,
//       targetWidth: width,
//       targetHeight: height,
//     );
//     final ui.FrameInfo frameInfo = await codec.getNextFrame();

//     // Convert the image to bytes
//     final ByteData? resizedByteData =
//         await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(resizedBytes);
//   }

//   Future<BitmapDescriptor> _getCustomMarkerWithDirection(double bearing) async {
//     final pictureRecorder = ui.PictureRecorder();
//     final canvas = Canvas(pictureRecorder);

//     const double radius = 50.0;
//     final Paint fillPaint = Paint()..color = Colors.blue;
//     final Paint strokePaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0;

//     // Draw the circle for location
//     canvas.drawCircle(Offset(radius, radius), radius, fillPaint);
//     canvas.drawCircle(Offset(radius, radius), radius, strokePaint);

//     // Draw the directional pointer
//     final Path arrowPath = Path()
//       ..moveTo(radius, radius * 0.5) // Top of the arrow
//       ..lineTo(radius * 0.7, radius * 1.5) // Left side
//       ..lineTo(radius * 1.3, radius * 1.5) // Right side
//       ..close();

//     final Paint arrowPaint = Paint()..color = Colors.white;
//     canvas.save();
//     canvas.translate(radius, radius); // Move origin to the center
//     canvas.rotate(bearing * 3.1415927 / 180); // Rotate according to bearing
//     canvas.translate(-radius, -radius); // Move back origin
//     canvas.drawPath(arrowPath, arrowPaint);
//     canvas.restore();

//     final picture = pictureRecorder.endRecording();
//     final img =
//         await picture.toImage((radius * 2).toInt(), (radius * 2).toInt());
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(buffer);
//   }
  
//   Future<BitmapDescriptor> _createCurrentLocationMarkerIcon(double bearing) async {
//   final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//   final Canvas canvas = Canvas(pictureRecorder);
//   const double size = 150.0; // Adjust size as needed
//   print("_createCurrentLocationMarkerIcon: $bearing");
//   // Create the custom marker using CurrentLocationMarkerPainter
//   final CurrentLocationMarkerPainter painter = CurrentLocationMarkerPainter(
//     bearing: bearing,
//     animatedRadius: 80.0 , // Provide a fixed value for animatedRadius
//   );
  
//   painter.paint(canvas, Size(size, size));

//   final ui.Image image = await pictureRecorder
//       .endRecording()
//       .toImage(size.toInt(), size.toInt());
//   final ByteData? byteData =
//       await image.toByteData(format: ui.ImageByteFormat.png);
//   final Uint8List imageData = byteData!.buffer.asUint8List();

//   return BitmapDescriptor.fromBytes(imageData);
// }

//   // Update the markers function
//   void _updateMarkers() async {
//     if (_currentPosition != null) {
//       // Fetch the dynamic bearing
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.bestForNavigation,
//       );
//       final double bearing = position.heading; // Get the current bearing

//       // Update the current location marker with the custom marker icon and bearing
//       final currentLocationIcon = await _createCurrentLocationMarkerIcon(bearing);

//       setState(() {
//         _markers.add(
//           Marker(
//             markerId: const MarkerId('current_location'),
//             position: _currentPosition!,
//             icon: currentLocationIcon,
//             infoWindow: const InfoWindow(title: 'Your Location'),
//             onTap: () {
//               _showCustomInfoWindow(
//                 'Your Location',
//                 '',
//                 _currentPosition!,
//               );
//             },
//           ),
//         );
//       });
//     }

//     // Add markers for all available chargers (existing logic)
//     for (var charger in availableChargers) {
//       final chargerId = charger['charger_id'] ?? 'Unknown Charger ID';
//       final lat = charger['lat'] != null ? double.tryParse(charger['lat']) : null;
//       final lng = charger['long'] != null ? double.tryParse(charger['long']) : null;

//       if (lat != null && lng != null) {
//         if (_currentPosition != null &&
//             lat == _currentPosition!.latitude &&
//             lng == _currentPosition!.longitude) {
//           continue;
//         }

//         BitmapDescriptor Charger_icon =
//             await _getIconFromAssetred('assets/icons/EV_location_red.png');

//         setState(() {
//           _markers.add(
//             Marker(
//               markerId: MarkerId(chargerId),
//               position: LatLng(lat, lng),
//               icon: Charger_icon, // Use the custom icon for chargers
//               infoWindow: InfoWindow(
//                 title: charger['model'] ?? 'Unknown Model',
//                 snippet: chargerId,
//               ),
//               onTap: () {
//                 _onMarkerTapped(MarkerId(chargerId), LatLng(lat, lng));
//               },
//             ),
//           );
//         });
//       }
//     }
//   }



// Future<void> _getPolyline(LatLng start, LatLng end) async {
//   print('Fetching polyline from $start to $end');
//   final response = await http.get(Uri.parse(
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco'));

//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     print('Response received: $data');

//     if (data['routes'].isNotEmpty) {
//       final route = data['routes'][0];
//       final polyline = route['overview_polyline']['points'];
//       final polylineCoordinates = _decodePolyline(polyline);

//       print('Decoded polyline points: $polylineCoordinates');

//       setState(() {
//         _polylines.clear(); // Clear existing polylines
//         _polylines.add(
//           Polyline(
//             polylineId: PolylineId('route'),
//             points: polylineCoordinates,
//             color: Colors.blue, // Ensure this is visible on the map
//             width: 6, // Adjust for better visibility
//           ),
//         );
//       });
//     } else {
//       print('No routes found.');
//     }
//   } else {
//     print('Failed to fetch polyline: ${response.statusCode}');
//   }
// }

//   List<LatLng> _decodePolyline(String encoded) {
//     List<LatLng> polylineCoordinates = [];
//     int index = 0;
//     int len = encoded.length;
//     int lat = 0;
//     int lng = 0;

//     while (index < len) {
//       int b;
//       int shift = 0;
//       int result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lat += dlat;

//       shift = 0;
//       result = 0;
//       do {
//         b = encoded.codeUnitAt(index++) - 63;
//         result |= (b & 0x1F) << shift;
//         shift += 5;
//       } while (b >= 0x20);
//       int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
//       lng += dlng;

//       LatLng p = LatLng(lat / 1E5, lng / 1E5);
//       polylineCoordinates.add(p);
//     }

//     return polylineCoordinates;
//   }

//   void _showCustomInfoWindow(String title, String snippet, LatLng position) {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           padding: const EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.grey.shade800, Colors.black],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(20),
//               topRight:
//                   Radius.circular(20), // Adjust the radius value as needed
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.4),
//                 blurRadius: 8,
//                 spreadRadius: 4,
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.ev_station, color: Colors.white, size: 28),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 snippet,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.white70,
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context); // Close the modal
//                       // Add your action here, like navigating to the location
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white.withOpacity(0.1),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Navigate',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<BitmapDescriptor> _getIconFromFlutterIcon(
//       IconData iconData, Color color, double size) async {
//     final pictureRecorder = ui.PictureRecorder();
//     final canvas = Canvas(pictureRecorder);

//     final textPainter = TextPainter(textDirection: TextDirection.ltr)
//       ..text = TextSpan(
//         text: String.fromCharCode(iconData.codePoint),
//         style: TextStyle(
//           fontSize: size,
//           fontFamily: iconData.fontFamily,
//           color: color,
//         ),
//       )
//       ..layout();

//     textPainter.paint(canvas, Offset(0, 0));
//     final picture = pictureRecorder.endRecording();
//     final img = await picture.toImage(size.toInt(), size.toInt());
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(buffer);
//   }

// Future<Map<String, dynamic>?> handleSearchRequest(String searchChargerID) async {
//   if (isSearching) return null;
//   if (searchChargerID.isEmpty) {
//     showErrorDialog(context, 'Please enter a charger ID.');
//     return {'error': true, 'message': 'Charger ID is empty'};
//   }

//   setState(() {
//     isSearching = true;
//   });

//   try {
//     final response = await http.post(
//       Uri.parse('http://122.166.210.142:9098/searchCharger'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({
//         'searchChargerID': searchChargerID,
//         'Username': widget.username,
//         'user_id': widget.userId,
//       }),
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       setState(() {
//         this.searchChargerID = searchChargerID;
//       });

//       await showModalBottomSheet(
//         context: context,
//         isScrollControlled: true,
//         isDismissible: false,
//         enableDrag: false,
//         backgroundColor: Colors.black,
//         builder: (BuildContext context) {
//           return Padding(
//             padding: MediaQuery.of(context).viewInsets,
//             child: ConnectorSelectionDialog(
//               chargerData: data['socketGunConfig'] ?? {},
//               onConnectorSelected: (connectorId, connectorType) {
//                 updateConnectorUser(
//                     searchChargerID, connectorId, connectorType);
//               },
//             ),
//           );
//         },
//       );
//       return data; // Return the successful response data
//     } else {
//       final errorData = json.decode(response.body);
//       showErrorDialog(context, errorData['message']);
//       print(errorData['message'] );
//       return {'error': true, 'message': errorData['message']};
//     }
//   } catch (error) {
//     showErrorDialog(context, 'Internal server error ');
//     return {'error': true, 'message': 'Internal server error'};
//   } finally {
//     setState(() {
//       isSearching = false;
//     });
//   }
// }

//   Future<void> updateConnectorUser(
//       String searchChargerID, int connectorId, int connectorType) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://122.166.210.142:9098/updateConnectorUser'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'searchChargerID': searchChargerID,
//           'Username': widget.username,
//           'user_id': widget.userId,
//           'connector_id': connectorId,
//         }),
//       );

//       if (response.statusCode == 200) {
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Charging(
//               searchChargerID: searchChargerID,
//               username: widget.username,
//               userId: widget.userId,
//               connector_id: connectorId,
//               connector_type: connectorType, 
//               email: widget.email,
//             ),
//           ),
//         );
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//       }
//     } catch (error) {
//       showErrorDialog(context, 'Internal server error ');
//     }
//   }

//   void navigateToQRViewExample() async {
//     // Check camera permission
//     bool hasPermission = await Permission.camera.isGranted;

//     if (hasPermission) {
//       // Navigate to the QR scanner screen if permission is granted
//       final scannedCode = await Navigator.push<String>(
//         context,
//         MaterialPageRoute(
//           builder: (context) => QRViewExample(
//             handleSearchRequestCallback: handleSearchRequest,
//             username: widget.username,
//             userId: widget.userId,
//           ),
//         ),
//       );

//       if (scannedCode != null) {
//         setState(() {
//           searchChargerID = scannedCode;
//         });
//       }
//     } else {
//       // Show CoolAlert if permission is not granted
//       CoolAlert.show(
//         context: context,
//         type: CoolAlertType.custom,
//         widget: Column(
//           children: [
//             const SizedBox(height: 16.0),
//             const Text(
//               'Permission Denied',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             const SizedBox(height: 8.0),
//             const Text(
//               'To Scan QR codes, allow this app access to your camera. Tap Settings > Permissions, and turn Camera on.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.black),
//             ),
//           ],
//         ),
//         confirmBtnText: 'Settings',
//         cancelBtnText: 'Cancel',
//         showCancelBtn: true,
//         confirmBtnColor: Colors.blue,
//         barrierDismissible: false,
//         onConfirmBtnTap: () {
//           openAppSettings();
//         },
//       );
//     }
//   }

//   void showErrorDialog(BuildContext context, String message) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       isDismissible: false,
//       enableDrag: false,
//       backgroundColor: Colors.black,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: ErrorDetails(errorData: message),
//         );
//       },
//     ).then((_) {
//       Navigator.of(context).popUntil((route) => route.isFirst);
//     });
//   }

//   Future<void> fetchRecentSessionDetails() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://122.166.210.142:9098/getRecentSessionDetails'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'user_id': widget.userId,
//         }),
//       );
//         final data = json.decode(response.body);
//         print("Prev: $data");

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           recentSessions = data['data'] ?? [];

//           activeFilter = 'Previously Used';
//           isLoading = false;
//         });
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//         setState(() {
//           isLoading = false;
//         });
//         setState(() {
//           activeFilter = 'All Chargers';
//           isLoading = false;
//         });
//       }
//     } catch (error) {
//       showErrorDialog(context, 'Internal server error ');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchAllChargers() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse(
//             'http://122.166.210.142:9098/getAllChargersWithStatusAndPrice'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'user_id': widget.userId,
//         }),
//       );
//         final data = json.decode(response.body);
//         print("datas: $data");
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           availableChargers = data['data'] ?? [];
//           activeFilter = 'All Chargers';
//           isLoading = false;
//         });
//         _updateMarkers();
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (error) {
//       print('Internal server error $error ');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<BitmapDescriptor> _getRotatedIcon({
//     required IconData iconData,
//     required Color color,
//     required double size,
//     required double rotation,
//   }) async {
//     final pictureRecorder = ui.PictureRecorder();
//     final canvas = Canvas(pictureRecorder);

//     final textPainter = TextPainter(textDirection: TextDirection.ltr)
//       ..text = TextSpan(
//         text: String.fromCharCode(iconData.codePoint),
//         style: TextStyle(
//           fontSize: size,
//           fontFamily: iconData.fontFamily,
//           color: color,
//         ),
//       )
//       ..layout();

//     canvas.save();
//     canvas.translate(
//         size / 2, size / 2); // Move the canvas origin to the center
//     canvas.rotate(
//         rotation * 3.1415927 / 180); // Rotate the canvas to the given bearing
//     canvas.translate(-size / 2, -size / 2); // Move back the origin

//     textPainter.paint(canvas, Offset(0, 0));
//     canvas.restore();

//     final picture = pictureRecorder.endRecording();
//     final img = await picture.toImage(size.toInt(), size.toInt());
//     final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//     final buffer = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(buffer);
//   }
//   Future<BitmapDescriptor> _getDirectionMarker(double bearing) async {
//   const double size = 100.0; // Size of the icon
//   final pictureRecorder = ui.PictureRecorder();
//   final canvas = Canvas(pictureRecorder);

//   // Load the image from assets
//   final ByteData imageData = await rootBundle.load('assets/arrow.png');
//   final ui.Image image = await loadImageFromBytes(imageData.buffer.asUint8List());

//   // Adjust the center point based on the arrow's orientation
//   final double offsetX = size * 0.25; // 25% from the left
//   final double offsetY = size * 0.75; // 75% from the top

//   // Draw the image on the canvas
//   canvas.save();
//   canvas.translate(offsetX, offsetY); // Move origin to the adjusted center
//   canvas.rotate(bearing * 3.1415927 / 180); // Rotate according to bearing
//   canvas.translate(-offsetX, -offsetY); // Move back origin

//   // Draw the image with the same size as the canvas
//   canvas.drawImageRect(
//     image,
//     Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
//     Rect.fromLTWH(0, 0, size, size),
//     Paint(),
//   );

//   canvas.restore();

//   final picture = pictureRecorder.endRecording();
//   final img = await picture.toImage(size.toInt(), size.toInt());
//   final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
//   final buffer = byteData!.buffer.asUint8List();

//   return BitmapDescriptor.fromBytes(buffer);
// }


// // Helper function to load an image from bytes
// Future<ui.Image> loadImageFromBytes(Uint8List imgBytes) async {
//   final Completer<ui.Image> completer = Completer();
//   ui.decodeImageFromList(imgBytes, (ui.Image img) {
//     return completer.complete(img);
//   });
//   return completer.future;
// }

// void _startLiveTracking() {
//   // Cancel any existing subscription to prevent memory leaks
//   _positionStreamSubscription?.cancel();

//   // Set up the position stream subscription
//   _positionStreamSubscription = Geolocator.getPositionStream(
//     locationSettings: const LocationSettings(
//       accuracy: LocationAccuracy.bestForNavigation,
//       distanceFilter: 0, // Receive updates for any movement
//     ),
//   ).listen((Position position) async {
//     final LatLng newPosition = LatLng(position.latitude, position.longitude);
//     final double newBearing = position.heading;

//     // Update the current position and marker if there's a significant change
//     if (_hasSignificantChange(newPosition, newBearing)) {
//       _currentPosition = newPosition;
//       _previousPosition = newPosition;
//       _previousBearing = newBearing;

//       await _updateCurrentLocationMarker(newBearing);

//       // **Remove the automatic camera update** here
//       // if (mapController != null) {
//       //   mapController!.animateCamera(
//       //     CameraUpdate.newCameraPosition(
//       //       CameraPosition(
//       //         target: _currentPosition!,
//       //         zoom: 18.0,
//       //         bearing: newBearing,
//       //         tilt: 45.0,
//       //       ),
//       //     ),
//       //   );
//       // }
//     }
//   }, onError: (error) {
//     print('Error in live tracking: $error');
//   });
// }


// // Function to check if there's a significant change
// bool _hasSignificantChange(LatLng newPosition, double newBearing) {
//   const double bearingThreshold = 5.0; // Minimum change in degrees to update
//   const double distanceThreshold = 0.0001; // Minimum change in distance (in degrees) to update

//   final double bearingChange = (_previousBearing != null)
//       ? (newBearing - _previousBearing!).abs()
//       : double.infinity;
//   final double distanceChange = (_previousPosition != null)
//       ? Geolocator.distanceBetween(
//               _previousPosition!.latitude,
//               _previousPosition!.longitude,
//               newPosition.latitude,
//               newPosition.longitude) /
//           1000
//       : double.infinity;

//   return bearingChange > bearingThreshold || distanceChange > distanceThreshold;
// }

// Future<void> _updateCurrentLocationMarker(double bearing) async {
//   // Create a custom icon that reflects the current bearing
//   final currentLocationIcon = await _createCurrentLocationMarkerIcon(bearing);
//   print("_updateCurrentLocationMarker: $currentLocationIcon ");
//   setState(() {
//     // Remove any previous marker for the current location
//     _markers.removeWhere((marker) => marker.markerId.value == 'current_location');

//     // Add a new marker with the updated location and rotation
//     _markers.add(
//       Marker(
//         markerId: const MarkerId('current_location'),
//         position: _currentPosition!,
//         icon: currentLocationIcon,
//         rotation: bearing,
//         anchor: const Offset(0.5, 0.5), // Center the icon
//       ),
//     );
//   });
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: GoogleMap(
//               key: _mapKey, // Assign GlobalKey to GoogleMap
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: _currentPosition ?? _center,
//                 zoom: 16.0,
//               ),
//               markers: _markers,
//               polylines: _polylines, // Add polylines to the map
//               zoomControlsEnabled: false,
//               myLocationEnabled: false,
//               myLocationButtonEnabled: false,
//               mapToolbarEnabled: false,
//               compassEnabled: false,
//               onTap: _onMapTapped,
//             ),
//           ),
//           Positioned(
//             bottom: 250,
//             right: 10,
//             child: FloatingActionButton(
//               backgroundColor: const Color.fromARGB(227, 76, 175, 79),
//               onPressed: _getCurrentLocation,
//               child: const Icon(Icons.my_location, color: Colors.white),
//             ),
//           ),
//           Positioned(
//             top: 305,
//             right: 10,
//             child: Column(
//               children: [
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     FloatingActionButton(
//                       heroTag: 'Navigation in google map',
//                       backgroundColor: Colors.black,
//                       onPressed: areMapButtonsEnabled
//                           ? () async {
//                               if (_selectedPosition != null) {
//                                 final googleMapsUrl =
//                                     "https://www.google.com/maps/dir/?api=1&destination=${_selectedPosition!.latitude},${_selectedPosition!.longitude}&travelmode=driving";
//                                 if (await canLaunch(googleMapsUrl)) {
//                                   await launch(googleMapsUrl);
//                                 } else {
//                                   showErrorDialog(context,
//                                       'Could not open the map. Please check your internet connection or try again later.');
//                                 }
//                               }
//                             }
//                           : null,
//                       child: SizedBox(
//                         width: 30, // Adjust width as needed
//                         height: 30, // Adjust height as needed
//                         child: Image.asset(
//                           'assets/icons/Google_map.png', // Replace with your image path
//                           fit: BoxFit
//                               .contain, // Ensure the image fits within the button
//                         ),
//                       ),
//                     ),
//                     if (!areMapButtonsEnabled)
//                       Container(
//                         width: 56, // Match the size of the FloatingActionButton
//                         height: 56,
//                         child: CustomPaint(
//                           painter: CrossPainter(),
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             children: [
//               Padding(
//                 padding:
//                     const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _searchController,
//                         onSubmitted: (value) {
//                           handleSearchRequest(value);
//                         },
//                         style: const TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: const Color(0xFF0E0E0E),
//                           hintText: 'Search ChargerId...',
//                           hintStyle: const TextStyle(color: Colors.white70),
//                           prefixIcon: const Icon(Icons.search, color: Colors.white),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(30.0),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         inputFormatters: [
//                         FilteringTextInputFormatter.allow(
//                           RegExp(r'[a-zA-Z0-9]'), // Allow only alphabets and numbers
//                         ),
//                         FilteringTextInputFormatter.deny(
//                           RegExp(r'\s'), // Disallow spaces
//                         ),
//                       ],
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF0E0E0E),
//                         borderRadius: BorderRadius.circular(10),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             spreadRadius: 2,
//                             blurRadius: 5,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: IconButton(
//                         icon: const Icon(Icons.qr_code,
//                             color: Colors.white, size: 30),
//                         onPressed: () {
//                           navigateToQRViewExample();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0, vertical: 10.0),
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       ElevatedButton.icon(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: activeFilter == 'All Chargers'
//                               ? Colors.blue
//                               : const Color(0xFF0E0E0E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             activeFilter = 'All Chargers';
//                           });
//                           fetchAllChargers();
//                         },
//                         icon: const Icon(Icons.ev_station, color: Colors.white),
//                         label: const Text('All Chargers',
//                             style: TextStyle(color: Colors.white)),
//                       ),
//                       const SizedBox(width: 10),
//                       ElevatedButton.icon(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: activeFilter == 'Previously Used'
//                               ? Colors.blue
//                               : const Color(0xFF0E0E0E),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             activeFilter = 'Previously Used';
//                           });
//                           fetchRecentSessionDetails();
//                         },
//                         icon: const Icon(Icons.history, color: Colors.white),
//                         label: const Text('Previously Used',
//                             style: TextStyle(color: Colors.white)),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: <Widget>[
//                     const SizedBox(width: 15),
//                     if (isLoading)
//                       for (var i = 0; i < 3; i++) _buildShimmerCard(),
//                     if (!isLoading && activeFilter == 'Previously Used')
//                       for (var session in recentSessions)
//                         _buildChargerCard(
//                           context,
//                           session['details']['charger_id'] ?? 'Unknown ID',
//                           session['details']['model'] ?? 'Unknown Model',
//                           session['status']['charger_status'] ??
//                               'Unknown Status',
//                           "1.3 Km",
//                           session['unit_price']?.toString() ?? 'Unknown Price',
//                           session['status']['connector_id'] ?? 0,
//                           session['details']['charger_accessibility']
//                                   ?.toString() ??
//                               'Unknown',
//                         ),
//                     if (!isLoading && activeFilter == 'All Chargers')
//                     for (var charger in availableChargers)
//                       for (var status in charger['status'] ?? [null])  // If status is null, use [null]
//                         _buildChargerCard(
//                           context,
//                           charger['charger_id'] ?? 'Unknown ID',
//                           charger['model'] ?? 'Unknown Model',
//                           status == null
//                               ? "Not yet received"  // When status is null
//                               : status['charger_status'] ?? 'Unknown Status',
//                           "1.3 Km",
//                           charger['unit_price']?.toString() ?? 'Unknown Price',
//                           status == null
//                               ? 0  // Default connector ID when status is null
//                               : status['connector_id'] ?? 'Unknown Last Updated',
//                           charger['charger_accessibility']?.toString() ?? 'Unknown',
//                         )

//                       // for (var charger in availableChargers)
//                       //   if (charger['status'] == null)
//                       //     _buildChargerCard(
//                       //       context,
//                       //       charger['charger_id'] ?? 'Unknown ID',
//                       //       charger['model'] ?? 'Unknown Model',
//                       //       "Not yet received",
//                       //       "1.3 Km",
//                       //       charger['unit_price']?.toString() ??
//                       //           'Unknown Price',
//                       //       0,
//                       //       charger['charger_accessibility']?.toString() ??
//                       //           'Unknown',
//                       //     ),
//                     // for (var charger in availableChargers)
//                     //   if (charger['status'] != null)
//                     //     for (var status in charger['status'] ?? [])
//                     //       _buildChargerCard(
//                     //         context,
//                     //         charger['charger_id'] ?? 'Unknown ID',
//                     //         charger['model'] ?? 'Unknown Model',
//                     //         status['charger_status'] ?? 'Unknown Status',
//                     //         "1.3 Km",
//                     //         charger['unit_price']?.toString() ??
//                     //             'Unknown Price',
//                     //         status['connector_id'] ?? 'Unknown Last Updated',
//                     //         charger['charger_accessibility']?.toString() ??
//                     //             'Unknown',
//                     //      ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 28),
//             ],
//           ),
//           Positioned(
//             bottom: 250,
//             right: 10,
//             child: FloatingActionButton(
//               backgroundColor: const Color.fromARGB(227, 76, 175, 79),
//               onPressed: _getCurrentLocation,
//               child: const Icon(Icons.my_location, color: Colors.white),
//             ),
//           ),
//           Positioned(
//             top: 170,
//             right: 10,
//             child: Column(
//               children: [
//                 FloatingActionButton(
//                   heroTag: 'zoom_in',
//                   backgroundColor: Colors.black,
//                   onPressed: () {
//                     mapController?.animateCamera(CameraUpdate.zoomIn());
//                   },
//                   child: const Icon(Icons.zoom_in_map_rounded,
//                       color: Colors.white),
//                 ),
//                 const SizedBox(height: 10),
//                 FloatingActionButton(
//                   heroTag: 'zoom_out',
//                   backgroundColor: Colors.black,
//                   onPressed: () {
//                     mapController?.animateCamera(CameraUpdate.zoomOut());
//                   },
//                   child:
//                       const Icon(Icons.zoom_out_map_rounded, color: Colors.red),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChargerCard(
//     BuildContext context,
//     String chargerId,
//     String model,
//     String status,
//     String meter,
//     String price,
//     int connectorId,
//     String accessType,
//   ) {
//     Color statusColor;
//     IconData statusIcon;

//     switch (status) {
//       case "Available":
//         statusColor = Colors.green;
//         statusIcon = Icons.check_circle;
//         break;
//       case "Unavailable":
//         statusColor = Colors.red;
//         statusIcon = Icons.cancel;
//         break;
//       case "Preparing":
//         statusColor = Colors.yellow;
//         statusIcon = Icons.hourglass_empty;
//         break;
//       default:
//         statusColor = Colors.grey;
//         statusIcon = Icons.help;
//     }

//     final charger = availableChargers.firstWhere(
//       (c) => c['charger_id'] == chargerId,
//       orElse: () => null,
//     );

//     return GestureDetector(
//       onTap: () async {
//         if (charger != null) {
//           final lat = double.tryParse(charger['lat']);
//           final lng = double.tryParse(charger['long']);
//           if (lat != null && lng != null) {
//             final position = LatLng(lat, lng);
//             mapController?.animateCamera(
//               CameraUpdate.newLatLng(position),
//             );

//             // Set the new selected position and enable map buttons
//             setState(() {
//               _selectedPosition = position;
//               areMapButtonsEnabled = true;
//             });

//             // Change the marker icon to the selected icon
//             BitmapDescriptor newIcon =
//                 await _getIconFromAsset('assets/icons/EV_location_green.png');
//             BitmapDescriptor defaultIcon =
//                 await _getIconFromAssetred('assets/icons/EV_location_red.png');

//             setState(() {
//               // Revert the previous marker icon to default if it exists
//               if (_previousMarkerId != null) {
//                 _markers = _markers.map((marker) {
//                   if (marker.markerId == _previousMarkerId) {
//                     return marker.copyWith(iconParam: defaultIcon);
//                   }
//                   return marker;
//                 }).toSet();
//               }

//               // Update the icon for the newly selected marker
//               _markers = _markers.map((marker) {
//                 if (marker.markerId.value == chargerId) {
//                   _previousMarkerId = marker.markerId;
//                   return marker.copyWith(iconParam: newIcon);
//                 }
//                 return marker;
//               }).toSet();
//             });
            
//           }
//         }
//       },
//       child: Stack(
//         children: [
//           Container(
//             width: 315,
//             margin: const EdgeInsets.only(right: 28, top: 20),
//             decoration: BoxDecoration(
//               color: const Color(0xFF0E0E0E),
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   spreadRadius: 2,
//                   blurRadius: 5,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text.rich(
//                               TextSpan(
//                                 children: [
//                                   TextSpan(
//                                     text: "$chargerId - ",
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   TextSpan(
//                                     text: "[$connectorId]",
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.blue,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//                             Text(
//                               model,
//                               style: const TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//                             Row(
//                               children: [
//                                 Text(
//                                   status,
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: statusColor,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 5),
//                                 Icon(
//                                   statusIcon,
//                                   color: statusColor,
//                                   size: 14,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 5),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   meter,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                   ),
//                                 ),
//                                 Row(
//                                   children: [
//                                     const Icon(
//                                       Icons.currency_rupee,
//                                       color: Colors.orange,
//                                       size: 14,
//                                     ),
//                                     Text(
//                                       "$price per unit",
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         color: Colors.white70,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: areMapButtonsEnabled
//                                 ? () async {
//                                 if (_selectedPosition != null) {
//                                   if (_currentPosition != null) {
//                                     await _getPolyline(_currentPosition!, _selectedPosition!);
                                    
//                                     // Fetch place name and duration dynamically
//                                     final placeName = await _getPlaceName(_selectedPosition!);
//                                     final durationAndDistance = await _calculateDurationAndDistance(_currentPosition!, _selectedPosition!);

//                                     await _onNavigateButtonPressed(); // Trigger zoom animation
//                                     // Show the modal bottom sheet with the dynamic data
//                                     showModalBottomSheet(
//                                       context: context,
//                                       isScrollControlled: false,
//                                       builder: (BuildContext context) {
//                                         return Container(
//                                           height: MediaQuery.of(context).size.height * 0.38,
//                                           child: CustomRouteDialog(
//                                             chargerId: chargerId, // Pass the chargerId here
//                                             placeName: placeName, // Use the fetched place name
//                                             duration: durationAndDistance['duration']!, // Use the fetched duration
//                                             distance: durationAndDistance['distance']!, // Use the fetched distance
//                                           ),
//                                         );
//                                       },
//                                     );
//                                   } else {
//                                     print('Current position is not available.');
//                                   }
//                                 }
//                               }
//                             : null,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1E1E1E),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Row(
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(Icons.directions, color: Colors.red),
//                                   onPressed: areMapButtonsEnabled ? _onNavigateButtonPressed : null,
//                                 ),
//                                 const Padding(
//                                   padding: EdgeInsets.all(8.0),
//                                   child: Text(
//                                     'Navigate',
//                                     style: TextStyle(color: Colors.white70),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () {
//                             handleSearchRequest(chargerId);
//                           },
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF1E1E1E),
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Row(
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(Icons.bolt, color: Colors.yellow),
//                                   onPressed: null, // Remove the redundant onPressed
//                                 ),
//                                 const Text(
//                                   ' Use Charger',
//                                   style: TextStyle(color: Colors.white70),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SlantedLabel(accessType: accessType),
//         ],
//       ),
//     );
//   }

//   Widget _buildShimmerCard() {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[800]!,
//       highlightColor: Colors.grey[700]!,
//       child: Container(
//         width: 280,
//         margin: const EdgeInsets.only(right: 15.0),
//         decoration: BoxDecoration(
//           color: const Color(0xFF0E0E0E),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(10.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 100,
//                 height: 20,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 5),
//               Container(
//                 width: 80,
//                 height: 20,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 5),
//               Row(
//                 children: [
//                   Container(
//                     width: 50,
//                     height: 20,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(width: 5),
//                   Container(
//                     width: 20,
//                     height: 20,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Container(
//                 width: double.infinity,
//                 height: 20,
//                 color: Colors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }


// }

// class ConnectorSelectionDialog extends StatefulWidget {
//   final Map<String, dynamic> chargerData;
//   final Function(int, int) onConnectorSelected;

//   const ConnectorSelectionDialog({
//     Key? key,
//     required this.chargerData,
//     required this.onConnectorSelected,
//   }) : super(key: key);

//   @override
//   _ConnectorSelectionDialogState createState() =>
//       _ConnectorSelectionDialogState();
// }

// class _ConnectorSelectionDialogState extends State<ConnectorSelectionDialog> {
//   int? selectedConnector;
//   int? selectedConnectorType;

//   bool _isFormValid() {
//     return selectedConnector != null && selectedConnectorType != null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: const BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Select Connector',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).popUntil((route) => route.isFirst); // Close the QR code scanner page and return to the Home Page
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           CustomGradientDivider(),
//           const SizedBox(height: 20),
//           GridView.builder(
//             shrinkWrap: true,
//             itemCount: widget.chargerData.keys
//                 .where((key) => key.startsWith('connector_'))
//                 .length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//               childAspectRatio: 3,
//             ),
//             itemBuilder: (BuildContext context, int index) {
//               int connectorId = index + 1;
//               String connectorKey = 'connector_${connectorId}_type';

//               if (!widget.chargerData.containsKey(connectorKey) ||
//                   widget.chargerData[connectorKey] == null) {
//                 return const SizedBox.shrink();
//               }

//               int connectorType = widget.chargerData[connectorKey];

//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedConnector = connectorId;
//                     selectedConnectorType = connectorType;
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: selectedConnector == connectorId
//                         ? Colors.green
//                         : Colors.grey[800],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Center(
//                     child: Text(
//                       'Connector $connectorId',
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _isFormValid()
//                 ? () {
//                     if (selectedConnector != null &&
//                         selectedConnectorType != null) {
//                       widget.onConnectorSelected(
//                           selectedConnector!, selectedConnectorType!);
//                       Navigator.of(context).pop();
//                     }
//                   }
//                 : null,
//             style: ButtonStyle(
//               backgroundColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) {
//                   if (states.contains(MaterialState.disabled)) {
//                     return Colors.green.withOpacity(0.2);
//                   }
//                   return const Color(0xFF1C8B40);
//                 },
//               ),
//               minimumSize:
//                   MaterialStateProperty.all(const Size(double.infinity, 50)),
//               shape: MaterialStateProperty.all(
//                 RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               elevation: MaterialStateProperty.all(0),
//               side: MaterialStateProperty.resolveWith<BorderSide>(
//                 (Set<MaterialState> states) {
//                   if (states.contains(MaterialState.disabled)) {
//                     return const BorderSide(color: Colors.transparent);
//                   }
//                   return const BorderSide(color: Colors.transparent);
//                 },
//               ),
//             ),
//             child:
//                 const Text('Continue', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SlantedLabel extends StatelessWidget {
//   final String accessType;

//   const SlantedLabel({required this.accessType, Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: 0,
//       right: 28,
//       child: Stack(
//         children: [
//           ClipPath(
//             clipper: SlantClipper(),
//             child: Container(
//               color: accessType == '1'
//                   ? const Color(0xFF0E0E0E)
//                   : const Color(0xFF0E0E0E),
//               height: 40,
//               width: 100,
//             ),
//           ),
//           Positioned(
//             right: 18,
//             top: 5,
//             child: Text(
//               accessType == '1' ? 'Public' : 'Private',
//               style: TextStyle(
//                 color: accessType == '1' ? Colors.green : Colors.yellow,
//                 fontWeight: FontWeight.normal,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SlantClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     Path path = Path();
//     path.lineTo(20, 0);
//     path.lineTo(0, size.height / 2);
//     path.lineTo(20, size.height);
//     path.lineTo(size.width, size.height);
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) {
//     return false;
//   }
// }

// class CrossPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF8E8E8E)
//       ..strokeWidth = 2.0
//       ..strokeCap = StrokeCap.round;

//     // Calculate offsets for top and bottom reduction
//     final offset =
//         size.height * 0.1; // Adjust this factor to change the reduction

//     // Draw the diagonal line from top-right to bottom-left with equal reduction
//     canvas.drawLine(
//       Offset(size.width - offset,
//           offset), // Starting point (inward from top-right)
//       Offset(offset,
//           size.height - offset), // Ending point (inward from bottom-left)
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }

// class CurrentLocationMarkerPainter extends CustomPainter {
//   final double bearing; // Direction bearing
//   final double animatedRadius; // Dynamic radius for animation

//   CurrentLocationMarkerPainter({
//     required this.bearing,
//     required this.animatedRadius,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final double outerCircleRadius = animatedRadius; // Use the animated radius
//     final double dotRadius = size.width / 5; // Adjusted size for the inner dot
//     final double borderThickness = size.width / 20;

//     // Draw the translucent outer circle
//     final Paint circlePaint = Paint()
//       ..color = Colors.blue.withOpacity(0.2)
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(Offset(size.width / 2, size.height / 2), outerCircleRadius, circlePaint);

//     // Draw the solid blue dot without rotation
//     final Paint dotPaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(Offset(size.width / 2, size.height / 2), dotRadius, dotPaint);

//     // Save the current state of the canvas before rotation
//     canvas.save();

//     // Translate the canvas to the center of the marker
//     canvas.translate(size.width / 2, size.height / 2);

//     // Rotate the canvas based on the bearing
//     canvas.rotate(bearing * 3.1415927 / 180);

//     // Draw the white border with rotation
//     final Paint borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = borderThickness;

//     canvas.drawCircle(Offset(0, 0), dotRadius, borderPaint);

//     // Draw the arrow pointing in the bearing direction
//     final Path arrowPath = Path()
//       ..moveTo(0, -outerCircleRadius) // Start at the top point
//       ..lineTo(-outerCircleRadius / 3, -outerCircleRadius / 2) // Left side of arrow
//       ..lineTo(outerCircleRadius / 3, -outerCircleRadius / 2) // Right side of arrow
//       ..close(); // Connect to the starting point

//     final Paint arrowPaint = Paint()
//       ..color = Colors.blueAccent.withOpacity(0.8)
//       ..style = PaintingStyle.fill;

//     canvas.drawPath(arrowPath, arrowPaint);

//     // Restore the canvas state after drawing the rotated elements
//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }

// class CurrentLocationMarker extends StatefulWidget {
//   final double bearing;

//   CurrentLocationMarker({required this.bearing});

//   @override
//   _CurrentLocationMarkerState createState() => _CurrentLocationMarkerState();
// }
// class _CurrentLocationMarkerState extends State<CurrentLocationMarker> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize the animation controller with a slightly longer duration
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2), // Longer duration for smoother animation
//       vsync: this,
//     )..repeat(reverse: true); // Loop the animation

//     // Define the animation for the circle's radius with smoother transitions
//     _animation = Tween<double>(begin: 50.0, end: 100.0).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _controller.dispose(); // Dispose of the controller when not needed
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: CurrentLocationMarkerPainter(
//             bearing: widget.bearing,
//             animatedRadius: _animation.value, // Pass the animated radius
//           ),
//           child: Container(), // Empty container just to hold the CustomPainter
//         );
//       },
//     );
//   }
// }


// class CustomRouteDialog extends StatefulWidget {
//   final String placeName;
//   final String duration;
//   final String distance;
//   final String chargerId; // Add this line

//   const CustomRouteDialog({
//     Key? key,
//     required this.placeName,
//     required this.duration,
//     required this.distance,
//     required this.chargerId, // Add this line
//   }) : super(key: key);

//   @override
//   _CustomRouteDialogState createState() => _CustomRouteDialogState();
// }

// class _CustomRouteDialogState extends State<CustomRouteDialog> {
//   bool _showFullText = false;

//   @override
//   Widget build(BuildContext context) {
//     String displayText = _showFullText
//         ? widget.placeName
//         : _truncateText(widget.placeName, 13); // Show first 13 words

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Grey background for the scroll indicator area
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 7), // Add some spacing above and below the scroll indicator
//           decoration: const BoxDecoration(
//             color: Color.fromARGB(255, 48, 48, 48), // Black background for the container wrapping the scroll view
//             borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
//           ),
//           child: Center(
//             child: Container(
//               width: 60,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade600,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: Color.fromARGB(255, 48, 48, 48), // Black background for the container wrapping the scroll view
//             ),
//             child: SingleChildScrollView(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
//                 decoration: BoxDecoration(
//                   color: Colors.black, // Black background for the main content container
//                   border: Border.all(
//                     color: Colors.transparent, // Border color
//                     width: 1, // Border width
//                   ),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Charger ID
//                     Text(
//                       widget.chargerId,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     // Place Name and Address with Location Icon at the start
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Icon(Icons.location_on, color: Colors.red, size: 25),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             displayText,
//                             style: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 17,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     Container(
//                       margin: const EdgeInsets.only(left: 35),
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _showFullText = !_showFullText;
//                           });
//                         },
//                         child: Text(
//                           _showFullText ? 'Show Less' : 'Show More',
//                           style: const TextStyle(color: Colors.blue, fontSize: 14),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     // Duration and Distance
//                     Row(
//                       children: [
//                         const Icon(Icons.directions_bike, color: Colors.green, size: 20),
//                         const SizedBox(width: 13),
//                         Text(
//                           "${widget.duration} - ",
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           widget.distance,
//                           style: const TextStyle(
//                             color: Colors.yellowAccent,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     // Horizontal Scrolling Button Row
//                     SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: const Icon(Icons.directions, color: Colors.white),
//                             label: const Text('Directions', style: TextStyle(color: Colors.white)),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.white,
//                               backgroundColor: Colors.blue,
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               elevation: 3,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             icon: const Icon(Icons.navigation, color: Colors.grey),
//                             label: const Text('Start', style: TextStyle(color: Colors.grey)),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.grey,
//                               backgroundColor: const Color(0xFF1E1E1E),
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               elevation: 3,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               final String textToShare =
//                                   'Here is the Charger ID: ${widget.chargerId}. Check out this charger location: ${widget.placeName}. It\'s just ${widget.distance} away and will take ${widget.duration} to reach from my current location.';

//                               Share.share(textToShare, subject: 'EV Charger Location');
//                             },
//                             icon: const Icon(Icons.share, color: Colors.grey),
//                             label: const Text('Share', style: TextStyle(color: Colors.grey)),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.grey,
//                               backgroundColor: const Color(0xFF1E1E1E),
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               elevation: 3,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           ElevatedButton.icon(
//                             onPressed: () async {
//                               final googleMapsUrl =
//                                   "https://www.google.com/maps/dir/?api=1&destination=${widget.placeName}&travelmode=driving";
//                               if (await canLaunch(googleMapsUrl)) {
//                                 await launch(googleMapsUrl);
//                               } else {
//                                 // Handle error when URL can't be launched
//                                 print('Could not launch Google Maps.');
//                               }
//                             },
//                             icon: SizedBox(
//                               width: 30,
//                               height: 30,
//                               child: Image.asset(
//                                 'assets/icons/Google_map.png', // Replace with your image path
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                             label: const Text('Open in Google map', style: TextStyle(color: Colors.grey)),
//                             style: ElevatedButton.styleFrom(
//                               foregroundColor: Colors.grey,
//                               backgroundColor: const Color(0xFF1E1E1E),
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                               elevation: 3,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _truncateText(String text, int wordLimit) {
//     List<String> words = text.split(' ');
//     if (words.length > wordLimit) {
//       return words.sublist(0, wordLimit).join(' ') + '...';
//     }
//     return text;
//   }
// }





// import 'dart:math';
// import 'package:async/async.dart';
// import 'package:ev_app/src/pages/home.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import '../ChargerDetails/ChargerConnectorPage.dart';
// import '../Charging/charging.dart';
// import '../../utilities/QR/qrscanner.dart';
// import 'dart:ui' as ui;
// import 'dart:async';
// import 'package:shimmer/shimmer.dart';
// import '../../service/location.dart';
// import 'package:intl/intl.dart' as intl;
// import 'dart:math' as math;
// import './search.dart';

// class HomeContent extends StatefulWidget {
//   final String username;
//   final int? userId;
//   final String email;
//   final Map<String, dynamic>? selectedLocation; // Accept the selected location

//   const HomeContent(
//       {super.key,
//       required this.username,
//       required this.userId,
//       required this.email,
//       this.selectedLocation});

//   @override
//   _HomeContentState createState() => _HomeContentState();
// }

// class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
//   final GlobalKey _mapKey = GlobalKey(); // Global key for map widget
//   Map<String, dynamic>? _currentSelectedLocation; // Now using dynamic type
//   String searchChargerID = '';
//   List availableChargers = [];
//   List recentSessions = [];
//   String activeFilter = 'All Chargers';
//   bool isLoading = true;
//   GoogleMapController? mapController;
//   LatLng? _currentPosition;
//   LatLng? _selectedPosition; // To store the selected marker's position
//   final LatLng _center = const LatLng(20.593683, 78.962883);
//   Set<Marker> _markers = {};
//   bool isSearching = false;
//   bool areMapButtonsEnabled = false;
//   MarkerId? _previousMarkerId; // To track the previously selected marker
//   StreamSubscription<Position>? _positionStreamSubscription;
//   bool _isFetchingLocation = false; // Ensure initialization
//   bool isChargerAvailable = false; // Flag to track if any charger is available
//   bool _isCheckingPermission =
//       false; // Flag to prevent repeated permission checks
//   bool LocationEnabled = false;
//   final PageController _pageController = PageController(
//       viewportFraction: 0.85); // Page controller for scrolling cards
//   static const String apiKey = 'AIzaSyDdBinCjuyocru7Lgi6YT3FZ1P6_xi0tco';
//   Map<String, String> _addressCache = {};
//   GoogleMapController? _mapController;
//   List<String> chargerIdsList = [];
//   bool _isAnimationInProgress = false;
//   CancelableOperation? _currentAnimationOperation;
//   Timer? _debounceTimer;

//   @override
//   void initState() {
//     super.initState();
//     _currentSelectedLocation = widget.selectedLocation;
//     _checkLocationPermission(); // Check permissions on initialization
//     // Prioritize moving to the selected location
//     _updateMarkers();
//     activeFilter = 'All Chargers';
//     fetchAllChargers();
//     _startLiveTracking(); // Start live tracking
//   }

//   @override
//   void dispose() {
//     // Cancel any active stream subscriptions

//     _positionStreamSubscription
//         ?.cancel(); // Cancel the position stream subscription
//     super.dispose(); // Call the super class dispose method
//   }

// // Define the method to check and request location permissions
//   Future<void> _checkLocationPermission() async {
//     if (_isCheckingPermission) return; // Prevent multiple permission checks

//     _isCheckingPermission = true;

//     // Load the saved flag from SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool locationPromptClosed = prefs.getBool('LocationPromptClosed') ?? false;

//     // If the user has closed the dialog before, don't show it again
//     if (locationPromptClosed) {
//       _isCheckingPermission = false;
//       return;
//     }

//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Show the location services dialog
//       await _showLocationServicesDialog();
//       _isCheckingPermission = false;
//       return;
//     }

//     // Request location permission
//     PermissionStatus permission = await Permission.location.request();
//     if (permission.isGranted) {
//       await _getCurrentLocation();
//       // Reset the flag, because location is now enabled
//       await prefs.setBool('LocationPromptClosed', false);
//     }

//     // Do nothing if permission is denied; no alert is shown
//     _isCheckingPermission = false;
//   }

//   Future<void> _getCurrentLocation() async {
//     // If a location fetch is already in progress, don't start a new one
//     if (_isFetchingLocation) return;

//     setState(() {
//       _isFetchingLocation = true;
//     });

//     // if (_currentSelectedLocation != null ){
//     //   setState(() {
//     //     _currentSelectedLocation = null;
//     //   });
//     // }

//     try {
//       // Ensure location services are enabled and permission is granted before fetching location
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         await _showLocationServicesDialog();
//         return;
//       }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//         await _showPermissionDeniedDialog();
//         return;
//       }

//       // Fetch the current location if permission is granted
//       LatLng? currentLocation =
//           await LocationService.instance.getCurrentLocation();
//       print("_onMapCreated currentLocation $currentLocation");

//       if (currentLocation != null) {
//         // Update the current position
//         setState(() {
//           _currentPosition = currentLocation;
//         });

//         // Smoothly animate the camera to the new position if the mapController is available
//         if (mapController != null) {
//           await mapController!.animateCamera(
//             CameraUpdate.newCameraPosition(
//               CameraPosition(
//                 target: _currentPosition!,
//                 zoom: 18.0, // Adjust zoom level as needed
//                 tilt: 45.0, // Add a tilt for a 3D effect
//                 // bearing:
//                 //     _previousBearing ?? 0, // Use previous bearing if available
//               ),
//             ),
//           );
//         }

//         // Update the current location marker on the map
//         _updateMarkers();
//         fetchAllChargers();
//         // await _updateCurrentLocationMarker(_previousBearing ?? 0);
//       } else {
//         print('Current location could not be determined.');
//       }
//     } catch (e) {
//       print('Error occurred while fetching the current location: $e');
//     } finally {
//       setState(() {
//         _isFetchingLocation = false;
//       });
//     }
//   }


//   void _resetSelectedLocationAndFetchCurrent() {
//     setState(() {
//       _currentSelectedLocation = null;
//       _markers.removeWhere(
//           (marker) => marker.markerId.value == 'selected_location');
//     });

//     _getCurrentLocation();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) async {
//     if (state == AppLifecycleState.resumed && !_isCheckingPermission) {
//       bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
//       if (isLocationEnabled) {
//         _checkLocationPermission(); // Ensure permission is checked again
//       } else {
//         _showLocationServicesDialog();
//       }
//     }
//   }

//   Future<void> _showLocationServicesDialog() async {
//     return showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissing by tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color(0xFF1E1E1E), // Background color
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.location_on, color: Colors.red, size: 35),
//                   SizedBox(width: 10),
//                   Expanded(
//                     // Add this to prevent the overflow issue
//                     child: Text(
//                       "Enable Location", // The heading text
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow
//                           .ellipsis, // Optional: add ellipsis if text overflows
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               CustomGradientDivider(), // Custom gradient divider
//             ],
//           ),
//           content: const Text(
//             'Location services are required to use this feature. Please enable location services in your phone settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//                 color: Colors.white70), // Adjusted text color for contrast
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () async {
//                 // Save the flag to not show the dialog again
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.setBool('LocationPromptClosed', true);
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Close",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await Geolocator
//                     .openLocationSettings(); // Open the location settings
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Settings",
//                 style: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _showPermissionDeniedDialog() async {
//     return showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissing by tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color(0xFF1E1E1E), // Background color
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.location_on, color: Colors.red, size: 35),
//                   SizedBox(width: 10),
//                   Expanded(
//                     // Prevent text overflow
//                     child: Text(
//                       "Permission Denied",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow
//                           .ellipsis, // Optional: add ellipsis if text overflows
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               CustomGradientDivider(), // Custom gradient divider
//             ],
//           ),
//           content: const Text(
//             'This app requires location permissions to function correctly. Please grant location permissions in settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//                 color: Colors.white70), // Adjusted text color for contrast
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Cancel",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             TextButton(
//               onPressed: () async {
//                 openAppSettings(); // Open app settings
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Settings",
//                 style: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _showPermanentlyDeniedDialog() async {
//     return showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissing by tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color(0xFF1E1E1E), // Background color
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Row(
//                 children: [
//                   Icon(Icons.warning, color: Colors.red, size: 35),
//                   SizedBox(width: 10),
//                   Expanded(
//                     // Prevent text overflow
//                     child: Text(
//                       "Permission Denied permanently",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       overflow: TextOverflow
//                           .ellipsis, // Optional: add ellipsis if text overflows
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               CustomGradientDivider(), // Custom gradient divider
//             ],
//           ),
//           content: const Text(
//             'Location permissions are permanently denied. Please enable them in the app settings.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//                 color: Colors.white70), // Adjusted text color for contrast
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Cancel",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//             TextButton(
//               onPressed: () async {
//                 openAppSettings(); // Open app settings
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//               child: const Text(
//                 "Settings",
//                 style: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Updated _onMapCreated function
//   Future<void> _onMapCreated(GoogleMapController controller) async {
//     mapController = controller;

//     // Load and set the map style
//     String mapStyle = await rootBundle.loadString('assets/Map/map.json');
//     mapController?.setMapStyle(mapStyle);

//     await Future.delayed(const Duration(seconds: 1));
//     print("_onMapCreated _onMapCreated _currentPosition 1 $_currentPosition");

//     print(
//         "_onMapCreated _onMapCreated _currentSelectedLocation:1  $_currentSelectedLocation");

//     // Check if the current position is available
//     if (_currentPosition != null || _currentSelectedLocation != null) {
//       print("_onMapCreated _onMapCreated _currentPosition 2 $_currentPosition");
//       print(
//           "_onMapCreated _onMapCreated _currentSelectedLocation: 2 $_currentSelectedLocation");

//       // Zoom to 100km radius around the current location
//       _animateTo100kmRadius();
//     } else {
//       print("_onMapCreated: _onMapCreated Current position is null");
//       // Optionally handle the case where the current position is not available
//       // _animateTo100kmRadius();
//     }
//   }

//   Future<void> _onMarkerTapped(MarkerId markerId, LatLng position) async {
//     setState(() {
//       _selectedPosition = position;
//       areMapButtonsEnabled = true;
//     });

//     // Change the marker icon to the selected icon
//     BitmapDescriptor newIcon =
//         await _getIconFromAsset('assets/icons/EV_location_green.png');
//     BitmapDescriptor defaultIcon =
//         await _getIconFromAssetred('assets/icons/EV_location_red.png');

//     setState(() {
//       // Revert the previous marker icon to default if it exists
//       if (_previousMarkerId != null) {
//         _markers = _markers.map((marker) {
//           if (marker.markerId == _previousMarkerId) {
//             return marker.copyWith(iconParam: defaultIcon);
//           }
//           return marker;
//         }).toSet();
//       }

//       // Update the icon for the newly selected marker
//       _markers = _markers.map((marker) {
//         if (marker.markerId == markerId) {
//           _previousMarkerId = marker.markerId;
//           return marker.copyWith(iconParam: newIcon);
//         }
//         return marker;
//       }).toSet();
//     });

//     // Find the index of the charger card based on the marker ID
//     int cardIndex = chargerIdsList.indexWhere((id) => id == markerId.value);

//     // Scroll to the corresponding charger card if it exists
//     if (cardIndex != -1) {
//       _pageController.animateToPage(
//         cardIndex,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }


//   Future<void> _smoothlyMoveCameraForChargerMarker(
//       LatLng startPosition, LatLng endPosition) async {
//     if (mapController != null) {
//       const int totalSteps =
//           25; // Number of animation steps for smooth movement
//       const int stepDuration = 120; // Duration between steps in milliseconds

//       for (int i = 1; i <= totalSteps; i++) {
//         double latitude = startPosition.latitude +
//             (endPosition.latitude - startPosition.latitude) * (i / totalSteps);
//         double longitude = startPosition.longitude +
//             (endPosition.longitude - startPosition.longitude) *
//                 (i / totalSteps);
//         LatLng intermediatePosition = LatLng(latitude, longitude);

//         // Smoothly animate to intermediate positions
//         await mapController!.animateCamera(
//           CameraUpdate.newLatLng(intermediatePosition),
//         );

//         await Future.delayed(const Duration(milliseconds: stepDuration));
//       }

//       // Rotate the camera and set an initial zoom and bearing
//       await mapController!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: endPosition,
//             zoom: 16.0, // Set an initial zoom level
//             bearing: 90.0, // Rotate the camera 90 degrees
//             tilt: 0, // Set tilt to 0 initially
//           ),
//         ),
//       );

//       // Delay to simulate rotation effect
//       await Future.delayed(const Duration(milliseconds: 300));

//       // // Final zoom and tilt for 3D effect
//       // await mapController!.animateCamera(
//       //   CameraUpdate.newCameraPosition(
//       //     CameraPosition(
//       //       target: endPosition,
//       //       zoom: 18.0, // Final zoom level for close-up view
//       //       tilt: 45.0, // Tilt the camera for a 3D effect
//       //       bearing: 90.0, // Keep the same bearing
//       //     ),
//       //   ),
//       // );
//     } else {
//       // Log or handle cases when the map controller is not initialized
//       print("Map controller is not initialized.");
//     }
//   }

//   void _onMapTapped(LatLng position) async {
//     setState(() {
//       areMapButtonsEnabled = false;
//     });

//     if (_previousMarkerId != null) {
//       // Load the custom red icon
//       BitmapDescriptor defaultIcon =
//           await _getIconFromAssetred('assets/icons/EV_location_red.png');

//       setState(() {
//         // Update the marker with the red icon
//         _markers = _markers.map((marker) {
//           if (marker.markerId == _previousMarkerId) {
//             return marker.copyWith(
//               iconParam: defaultIcon,
//             );
//           }
//           return marker;
//         }).toSet();

//         // Reset the previous marker ID
//         _previousMarkerId = null;
//       });
//     }
//   }

//   Future<BitmapDescriptor> _getIconFromAsset(String assetPath,
//       {int width = 300, int height = 300}) async {
//     final byteData = await rootBundle.load(assetPath);
//     final Uint8List bytes = byteData.buffer.asUint8List();

//     // Decode the image from bytes
//     final ui.Codec codec = await ui.instantiateImageCodec(
//       bytes,
//       targetWidth: width,
//       targetHeight: height,
//     );
//     final ui.FrameInfo frameInfo = await codec.getNextFrame();

//     // Convert the image to bytes
//     final ByteData? resizedByteData =
//         await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(resizedBytes);
//   }

//   Future<BitmapDescriptor> _getIconFromAssetred(String assetPath,
//       {int width = 230, int height = 230}) async {
//     final byteData = await rootBundle.load(assetPath);
//     final Uint8List bytes = byteData.buffer.asUint8List();

//     // Decode the image from bytes
//     final ui.Codec codec = await ui.instantiateImageCodec(
//       bytes,
//       targetWidth: width,
//       targetHeight: height,
//     );
//     final ui.FrameInfo frameInfo = await codec.getNextFrame();

//     // Convert the image to bytes
//     final ByteData? resizedByteData =
//         await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List resizedBytes = resizedByteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(resizedBytes);
//   }

//   Future<String> _getAddressFromLatLng(double lat, double lng) async {
//     try {
//       // Use a geocoding API, like Google Geocoding API
//       // Replace YOUR_API_KEY with your actual Google Maps API key
//       final response = await http.get(
//         Uri.parse(
//             'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey'),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['results'].isNotEmpty) {
//           return data['results'][0]['formatted_address'];
//         } else {
//           return 'Unknown Address';
//         }
//       } else {
//         throw Exception('Failed to fetch address');
//       }
//     } catch (e) {
//       print(e);
//       return 'Unknown Address';
//     }
//   }

//   Future<BitmapDescriptor> _createCurrentLocationMarkerIcon(
//       double bearing) async {
//     final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(pictureRecorder);
//     const double size = 150.0; // Adjust size as needed
//     print("_createCurrentLocationMarkerIcon: $bearing");
//     // Create the custom marker using CurrentLocationMarkerPainter
//     final CurrentLocationMarkerPainter painter = CurrentLocationMarkerPainter(
//       // bearing: bearing,
//       animatedRadius: 80.0, // Provide a fixed value for animatedRadius
//     );

//     painter.paint(canvas, const Size(size, size));

//     final ui.Image image = await pictureRecorder
//         .endRecording()
//         .toImage(size.toInt(), size.toInt());
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List imageData = byteData!.buffer.asUint8List();

//     return BitmapDescriptor.fromBytes(imageData);
//   }

//   void _updateMarkers() async {

//     // Use a set to track unique positions to avoid duplicate markers
//     Set<String> uniquePositions = {};

//     // Iterate through available chargers
//     for (var charger in availableChargers) {
//       final chargerId = charger['charger_id'] ?? 'Unknown Charger ID';
//       final lat =
//           charger['lat'] != null ? double.tryParse(charger['lat']) : null;
//       final lng =
//           charger['long'] != null ? double.tryParse(charger['long']) : null;

//       if (lat != null && lng != null) {
//         // Create a unique key based on latitude and longitude
//         String positionKey = '$lat,$lng';

//         // Check if this position already exists
//         if (uniquePositions.contains(positionKey)) {

//           continue; // Skip adding a marker if this position is already tracked
//         }

//         // Add the position to the set of unique positions
//         uniquePositions.add(positionKey);

//         // Fetch the address
//         String fullAddress = await _getAddressFromLatLng(lat, lng);

//         // Trim the address if it's longer than 20 characters
//         String trimmedAddress = fullAddress.length > 20
//             ? '${fullAddress.substring(0, 20)}...'
//             : fullAddress;

//         BitmapDescriptor chargerIcon =
//             await _getIconFromAssetred('assets/icons/EV_location_red.png');
//         setState(() {
//           _markers.add(
//             Marker(
//               markerId: MarkerId(chargerId),
//               position: LatLng(lat, lng),
//               icon: chargerIcon,
//               infoWindow: InfoWindow(
//                 title: trimmedAddress,
//               ),
//               onTap: () {
//                 _onMarkerTapped(MarkerId(chargerId), LatLng(lat, lng));
//               },
//             ),
//           );
//         });
//       }
//     }

//   }

//   Future<Map<String, dynamic>?> handleSearchRequest(
//       String searchChargerID) async {
//     if (isSearching) return null;

//     print("response: handleSearchRequest");

//     if (searchChargerID.isEmpty) {
//       showErrorDialog(context, 'Please enter a charger ID.');
//       return {'error': true, 'message': 'Charger ID is empty'};
//     }

//     setState(() {
//       isSearching = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://122.166.210.142:9098/searchCharger'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'searchChargerID': searchChargerID,
//           'Username': widget.username,
//           'user_id': widget.userId,
//         }),
//       );

//       // Delay to keep the loading indicator visible
//       await Future.delayed(const Duration(seconds: 2));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           this.searchChargerID = searchChargerID;
//           isSearching = false;
//         });

//         await showModalBottomSheet(
//           context: context,
//           isScrollControlled: true,
//           isDismissible: false,
//           enableDrag: false,
//           backgroundColor: Colors.black,
//           builder: (BuildContext context) {
//             return Padding(
//               padding: MediaQuery.of(context).viewInsets,
//               child: ConnectorSelectionDialog(
//                 chargerData: data['socketGunConfig'] ?? {},
//                 onConnectorSelected: (connectorId, connectorType) {
//                   updateConnectorUser(
//                       searchChargerID, connectorId, connectorType);
//                 },
//                 username: widget.username,
//                 email: widget.email,
//                 userId: widget.userId,
//               ),
//             );
//           },
//         );
//         return data; // Return the successful response data
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//         setState(() {
//           isSearching = false;
//         });
//         return {'error': true, 'message': errorData['message']};
//       }
//     } catch (error) {
//       showErrorDialog(context, 'Internal server error');
//       return {'error': true, 'message': 'Internal server error'};
//     } finally {
//       setState(() {
//         isSearching = false;
//       });
//     }
//   }

//   Future<void> updateConnectorUser(
//       String searchChargerID, int connectorId, int connectorType) async {
//     setState(() {
//       isSearching = false;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://122.166.210.142:9098/updateConnectorUser'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'searchChargerID': searchChargerID,
//           'Username': widget.username,
//           'user_id': widget.userId,
//           'connector_id': connectorId,
//         }),
//       );

//       if (response.statusCode == 200) {
//         Navigator.pop(context);
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => Charging(
//               searchChargerID: searchChargerID,
//               username: widget.username,
//               userId: widget.userId,
//               connector_id: connectorId,
//               connector_type: connectorType,
//               email: widget.email,
//             ),
//           ),
//         );
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//       }
//     } catch (error) {
//       showErrorDialog(context, 'Internal server error ');
//     }
//   }

//   void navigateToQRViewExample() async {
//     // Check camera permission
//     bool hasPermission = await Permission.camera.isGranted;

//     if (hasPermission) {
//       // Navigate to the QR scanner screen if permission is granted
//       final scannedCode = await Navigator.push<String>(
//         context,
//         MaterialPageRoute(
//           builder: (context) => QRViewExample(
//             handleSearchRequestCallback: handleSearchRequest,
//             username: widget.username,
//             userId: widget.userId,
//           ),
//         ),
//       );

//       if (scannedCode != null) {
//         setState(() {
//           searchChargerID = scannedCode;
//           isSearching = false;
//         });
//       }
//     } else {
//       // Show a custom dialog if permission is not granted
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             backgroundColor: const Color(0xFF1E1E1E),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Row(
//                   children: [
//                     Icon(Icons.camera_alt, color: Colors.blue, size: 35),
//                     SizedBox(width: 10),
//                     Text(
//                       "Permission Denied",
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 CustomGradientDivider(),
//               ],
//             ),
//             content: const Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'To Scan QR codes, allow this app access to your camera. Tap Settings > Permissions, and turn Camera on.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.white70),
//                 ),
//               ],
//             ),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child:
//                     const Text("Cancel", style: TextStyle(color: Colors.white)),
//               ),
//               TextButton(
//                 onPressed: () {
//                   openAppSettings();
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text("Settings",
//                     style: TextStyle(color: Colors.blue)),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }

//   void showErrorDialog(BuildContext context, String message) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       isDismissible: false,
//       enableDrag: false,
//       backgroundColor: Colors.black,
//       builder: (BuildContext context) {
//         return Padding(
//           padding: MediaQuery.of(context).viewInsets,
//           child: ErrorDetails(
//               errorData: message,
//               username: widget.username,
//               email: widget.email,
//               userId: widget.userId),
//         );
//       },
//     ).then((_) {});
//   }

//   Future<void> fetchRecentSessionDetails() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await http.post(
//         Uri.parse('http://122.166.210.142:9098/getRecentSessionDetails'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'user_id': widget.userId,
//         }),
//       );
//       final data = json.decode(response.body);
//       print("Prev: $data");

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           recentSessions = data['data'] ?? [];

//           activeFilter = 'Previously Used';
//           isLoading = false;
//         });
//       } else {
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//         setState(() {
//           isLoading = false;
//         });
//         setState(() {
//           activeFilter = 'All Chargers';
//           isLoading = false;
//         });
//       }
//     } catch (error) {
//       showErrorDialog(context, 'Internal server error ');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> fetchAllChargers() async {
//     // Set loading state to true
//     setState(() {
//       isLoading = true;
//       availableChargers.clear(); // Clear previous chargers if needed
//     });

//     try {
//       final response = await http.post(
//         Uri.parse(
//             'http://122.166.210.142:9098/getAllChargersWithStatusAndPrice'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'user_id': widget.userId}),
//       );

//       final data = json.decode(response.body);

//       // Check if the response is successful
//       if (response.statusCode == 200) {
//         final List<dynamic> chargerData = data['data'] ?? [];

//         // Fetch addresses for each charger and store in a new field
//         for (var charger in chargerData) {
//           final lat = double.parse(charger['lat'] ?? '0');
//           final long = double.parse(charger['long'] ?? '0');
//           final chargerId = charger['charger_id'] ?? 'Unknown ID';

//           // Fetch address only if it's not already fetched
//           if (charger['address'] == null) {
//             String address = await _getPlaceName(LatLng(lat, long), chargerId);
//             charger['address'] = address; // Store the fetched address
//           }
//         }

//         // Update available chargers and filter
//         setState(() {
//           availableChargers = chargerData;
//           activeFilter = 'All Chargers';
//           isLoading = false; // Set loading to false after data is set
//         });
//         _buildChargerList();

//         _updateMarkers(); // Update markers after setting the chargers
//       } else {
//         // Handle error response
//         final errorData = json.decode(response.body);
//         showErrorDialog(context, errorData['message']);
//         setState(() {
//           isLoading = false; // Set loading to false on error
//         });
//       }
//     } catch (error) {
//       print('Internal server error: $error');
//       // Handle general errors
//       setState(() {
//         isLoading = false; // Set loading to false on error
//       });
//     }
//   }

// // Helper function to load an image from bytes
//   Future<ui.Image> loadImageFromBytes(Uint8List imgBytes) async {
//     final Completer<ui.Image> completer = Completer();
//     ui.decodeImageFromList(imgBytes, (ui.Image img) {
//       return completer.complete(img);
//     });
//     return completer.future;
//   }

//   void _startLiveTracking() {
//     // Cancel any existing subscription to prevent memory leaks
//     _positionStreamSubscription?.cancel();

//     // Set up the position stream subscription
//     _positionStreamSubscription = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.bestForNavigation,
//         distanceFilter: 0, // Receive updates for any movement
//       ),
//     ).listen((Position position) async {}, onError: (error) {
//       print('Error in live tracking: $error');
//     });
//   }

//   void _animateTo100kmRadius() {
//     print(
//         "_onMapCreated _animateTo100kmRadius _currentSelectedLocation: 3  $_currentSelectedLocation");
//     print(
//         "_onMapCreated targetLocation _currentPosition: 4  $_currentPosition");

//     // Check if the current selected location is not null
//     if (_currentSelectedLocation != null) {
//       double selectedLatitude =
//           double.parse(_currentSelectedLocation!['latitude'].toString());
//       double selectedLongitude =
//           double.parse(_currentSelectedLocation!['longitude'].toString());

//       // Create a LatLng object for the target location
//       final targetLocation = LatLng(selectedLatitude, selectedLongitude);
//       print(
//           "_onMapCreated targetLocation _currentSelectedLocation: 4  $_currentSelectedLocation");

//       // If _currentPosition is null, set it to (0.0, 0.0)
//       _currentPosition ??= const LatLng(0.0, 0.0);

//       // Now check if the selected location and current position are different
//       if (selectedLatitude != _currentPosition!.latitude ||
//           selectedLongitude != _currentPosition!.longitude) {
//         print(
//             "_onMapCreated targetLocation _currentSelectedLocation: 5  $_currentSelectedLocation");

//         // Create a new marker for the selected location
//         Marker newMarker = Marker(
//           markerId: const MarkerId("selected_location"),
//           position: targetLocation,
//           infoWindow: InfoWindow(
//             title: _currentSelectedLocation!['name'],
//             snippet: _currentSelectedLocation!['address'],
//           ),
//         );

//         // Clear existing markers and add the new marker
//         setState(() {
//           _markers.clear(); // Clear previous markers
//           _markers.add(newMarker); // Add the new marker
//         });
//         // Animate the camera to fit the 100km radius around the selected location
//         _animateToBounds(targetLocation);
//         return; // Return early to skip animating to the current position
//       }
//     }

//     // If there is no selected location or the current position is available
//     if (_currentPosition != null) {
//       print(
//           "_onMapCreated _animateTo100kmRadius _currentPosition: 6  $_currentPosition");

//       // Animate the camera to fit the 100km radius around the current position
//       _animateToBounds(_currentPosition!);
//     } else {
//       print("Current position is null, cannot animate to bounds.");
//     }
//   }

//   void _animateToBounds(LatLng centerLocation) {
//     if (mapController == null) {
//       print("mapController is null, cannot animate camera.");
//       return;
//     }

//     // Calculate bounds for a 100km radius
//     double radiusInKm = 10.0;
//     double kmInLat = 0.009; // Approximate value for 1 km in latitude
//     double kmInLng = 0.009 /
//         cos(centerLocation.latitude * pi / 180.0); // Adjust based on latitude

//     final LatLng southWest = LatLng(
//       centerLocation.latitude - (radiusInKm * kmInLat),
//       centerLocation.longitude - (radiusInKm * kmInLng),
//     );

//     final LatLng northEast = LatLng(
//       centerLocation.latitude + (radiusInKm * kmInLat),
//       centerLocation.longitude + (radiusInKm * kmInLng),
//     );

//     // Create the LatLngBounds
//     LatLngBounds bounds =
//         LatLngBounds(southwest: southWest, northeast: northEast);

//     // Animate the camera to fit the bounds
//     try {
//       mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
//     } catch (e) {
//       print("Error occurred while animating camera: $e");
//     }
//   }

//   void _moveToLocationOnMap(Map<String, dynamic> location) async {
//     double selectedLatitude = double.parse(location['latitude'].toString());
//     double selectedLongitude = double.parse(location['longitude'].toString());

//     // Create a LatLng object for the target location
//     final targetLocation = LatLng(selectedLatitude, selectedLongitude);

//     // Create a new marker for the selected location
//     Marker newMarker = Marker(
//       markerId: const MarkerId("selected_location"),
//       position: targetLocation,
//       infoWindow: InfoWindow(
//         title: location['name'],
//         snippet: location['address'],
//       ),
//     );

//     // Clear existing markers and add the new marker
//     setState(() {
//       _markers.clear(); // Clear previous markers
//       _markers.add(newMarker); // Add the new marker
//     });

//     // Get the current position of the map (if needed)
//     LatLng currentPosition =
//         _currentPosition ?? const LatLng(0, 0); // Default to (0,0) if unknown

//     // Smoothly animate the camera to the target location from the current position
//     // if (currentPosition != targetLocation) {
//     print(
//         "_onMapCreated currentPosition: $currentPosition, targetLocation: $targetLocation");
//     _animateCamera(currentPosition, targetLocation);
//     // } else {
//     //   _mapController?.animateCamera(
//     //     CameraUpdate.newLatLngZoom(targetLocation, 15.0), // Adjust zoom level if needed
//     //   );
//     // }
//   }

//   void _animateCamera(LatLng from, LatLng to) {
//     const int steps = 30; // Number of steps in the animation
//     const Duration duration =
//         Duration(seconds: 2); // Total duration of the animation
//     Timer.periodic(duration ~/ steps, (timer) {
//       // Calculate the interpolation factor
//       double t = timer.tick / steps;
//       if (t > 1) {
//         timer.cancel();
//         t = 1; // Clamp t to 1 to avoid overflow
//       }

//       // Interpolate the latitude and longitude
//       double interpolatedLat =
//           from.latitude + (to.latitude - from.latitude) * t;
//       double interpolatedLng =
//           from.longitude + (to.longitude - from.longitude) * t;

//       // Move the camera to the interpolated position
//       _mapController?.animateCamera(
//         CameraUpdate.newLatLng(LatLng(interpolatedLat, interpolatedLng)),
//       );

//       // If we reach the end of the animation, zoom into the final location
//       if (t == 1) {
//         _mapController?.animateCamera(
//           CameraUpdate.newLatLngZoom(
//               to, 15.0), // Final zoom to the selected location
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;

//     return LoadingOverlay(
//       showAlertLoading: isSearching,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: Stack(
//           children: [
//             Positioned.fill(
//               child: GoogleMap(
//                 key: _mapKey,
//                 onMapCreated: _onMapCreated,
//                 initialCameraPosition: CameraPosition(
//                   target: _currentPosition ?? _center,
//                   zoom: 4.3,
//                 ),
//                 markers: _markers,
//                 zoomControlsEnabled: false,
//                 myLocationEnabled: true,
//                 myLocationButtonEnabled: false,
//                 mapToolbarEnabled: false,
//                 compassEnabled: false,
//                 onTap: _onMapTapped,
//               ),
//             ),
//             Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.only(
//                     top: screenHeight *
//                         0.05, // Adjust padding based on screen height
//                     left: screenWidth *
//                         0.04, // Adjust padding based on screen width
//                     right: screenWidth * 0.04,
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () async {
//                             // Navigate to the search page and wait for the result
//                             final result = await Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => SearchResultsPage(
//                                   handleSearchRequest: handleSearchRequest,
//                                   onLocationSelected: (locationData) {
//                                     setState(() {
//                                       searchChargerID = locationData[
//                                           'name']; // Update with the selected location's name or chargerId
//                                     });
//                                     // Directly update the map with the selected location
//                                     _moveToLocationOnMap(
//                                         locationData); // Pass locationData directly
//                                   },
//                                   username: widget.username,
//                                   email: widget.email,
//                                   userId: widget.userId,
//                                 ),
//                               ),
//                             );
//                             if (result != null) {
//                               // If result is returned, update the search field with the charger ID
//                               setState(() {
//                                 searchChargerID = result['chargerId'];
//                               });
//                             }
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 15, vertical: 12),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF0E0E0E),
//                               borderRadius: BorderRadius.circular(30.0),
//                             ),
//                             child: const Row(
//                               children: [
//                                 Icon(Icons.search, color: Colors.white),
//                                 SizedBox(width: 10),
//                                 Text(
//                                   'Search',
//                                   style: TextStyle(color: Colors.white70),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(
//                           width: screenWidth *
//                               0.03), // Adjust spacing based on screen width
//                       Container(
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF0E0E0E),
//                           borderRadius: BorderRadius.circular(10),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               spreadRadius: 2,
//                               blurRadius: 5,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: IconButton(
//                           icon: const Icon(Icons.qr_code,
//                               color: Colors.white, size: 30),
//                           onPressed: () {
//                             navigateToQRViewExample();
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: screenWidth * 0.04, // Adjust horizontal padding
//                     vertical: screenHeight * 0.01, // Adjust vertical padding
//                   ),
//                   child: Align(
//                     alignment: Alignment.centerLeft,
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // "All Chargers" Button
//                           ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: activeFilter == 'All Chargers'
//                                   ? Colors.blue
//                                   : const Color(0xFF0E0E0E),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                             ),
//                             onPressed: () {
//                               setState(() {
//                                 activeFilter = 'All Chargers';
//                               });
//                               fetchAllChargers();
//                             },
//                             icon: const Icon(Icons.ev_station,
//                                 color: Colors.white),
//                             label: const Text(
//                               'All Chargers',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                           SizedBox(
//                               width: screenWidth *
//                                   0.03), // Spacing between buttons

//                           // Additional buttons can be added here if needed
//                           // Example: Previously Used Button (uncomment if required)
//                           /*
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: activeFilter == 'Previously Used'
//                   ? Colors.blue
//                   : const Color(0xFF0E0E0E),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             onPressed: () {
//               setState(() {
//                 activeFilter = 'Previously Used';
//               });
//               fetchRecentSessionDetails();
//             },
//             icon: const Icon(Icons.history, color: Colors.white),
//             label: const Text(
//               'Previously Used',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.03), // Spacing between buttons
//           */
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(
//                     height: screenHeight *
//                         0.50), // Adjust height based on screen size
//                 _buildChargerListContainer()
//               ],
//             ),
//             Positioned(
//               top: screenHeight *
//                   0.2, // Adjust positioning based on screen height
//               right: screenWidth *
//                   0.03, // Adjust positioning based on screen width
//               child: Column(
//                 children: [
//                   FloatingActionButton(
//                     heroTag: 'zoom_in',
//                     backgroundColor: Colors.black,
//                     onPressed: () {
//                       mapController?.animateCamera(CameraUpdate.zoomIn());
//                     },
//                     child: const Icon(Icons.zoom_in_map_rounded,
//                         color: Colors.white),
//                   ),
//                   SizedBox(
//                       height: screenHeight *
//                           0.01), // Adjust spacing between buttons
//                   FloatingActionButton(
//                     heroTag: 'zoom_out',
//                     backgroundColor: Colors.black,
//                     onPressed: () {
//                       mapController?.animateCamera(CameraUpdate.zoomOut());
//                     },
//                     child: const Icon(Icons.zoom_out_map_rounded,
//                         color: Colors.red),
//                   ),
//                   SizedBox(height: screenHeight * 0.01),
//                   FloatingActionButton(
//                     backgroundColor: const Color.fromARGB(227, 76, 175, 79),
//                     onPressed: _resetSelectedLocationAndFetchCurrent,
//                     child: const Icon(Icons.my_location, color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String formatTimestamp(String? timestamp) {
//     if (timestamp == null) return 'N/A'; // Handle null case

//     // Define date format patterns
//     final rawFormat = DateTime.tryParse(timestamp);
//     final formatter = intl.DateFormat('MM/dd/yyyy, hh:mm:ss a');

//     if (rawFormat != null) {
//       // If the timestamp is in ISO format, parse and format
//       final parsedDate = rawFormat.toLocal();
//       return formatter.format(parsedDate);
//     } else {
//       // Otherwise, assume it's already in the desired format and return it
//       return timestamp; // Or 'Invalid date' if you want to handle improperly formatted strings
//     }
//   }

// // Function to calculate the distance between two points (in km)
//   double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     const double R = 6371; // Earth's radius in km
//     final double dLat = (lat2 - lat1) * math.pi / 180.0;
//     final double dLon = (lon2 - lon1) * math.pi / 180.0;
//     final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(lat1 * math.pi / 180.0) *
//             math.cos(lat2 * math.pi / 180.0) *
//             math.sin(dLon / 2) *
//             math.sin(dLon / 2);
//     final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return R * c; // Distance in km
//   }

//   Future<void> _updateMarkerIcons(String chargerId) async {
//     BitmapDescriptor newIcon =
//         await _getIconFromAsset('assets/icons/EV_location_green.png');
//     BitmapDescriptor defaultIcon =
//         await _getIconFromAsset('assets/icons/EV_location_red.png');

//     setState(() {
//       // Change the icon of the previously selected marker back to default
//       if (_previousMarkerId != null) {
//         _markers = _markers.map((marker) {
//           if (marker.markerId == _previousMarkerId) {
//             return marker.copyWith(iconParam: defaultIcon);
//           }
//           return marker;
//         }).toSet();
//       }

//       // Update the icon for the currently selected charger marker and show its InfoWindow
//       _markers = _markers.map((marker) {
//         if (marker.markerId.value == chargerId) {
//           _previousMarkerId = marker.markerId;
//           mapController!.showMarkerInfoWindow(
//               marker.markerId); // Show InfoWindow automatically
//           return marker.copyWith(iconParam: newIcon);
//         }
//         return marker;
//       }).toSet();
//     });
//   }

//   Future<String> _getPlaceName(LatLng position, String chargerId) async {
//     // Check if the address is already cached
//     if (_addressCache.containsKey(chargerId)) {
//       return _addressCache[chargerId]!;
//     }

//     final String url =
//         'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);
//       if (data['results'].isNotEmpty) {
//         String fetchedAddress = data['results'][0]['formatted_address'];
//         // Store the fetched address in the cache
//         _addressCache[chargerId] = fetchedAddress;
//         return fetchedAddress;
//       } else {
//         return "Unknown Location";
//       }
//     } else {
//       throw Exception('Failed to fetch place name');
//     }
//   }

//   Widget _buildShimmerCard() {
//     // Get screen size
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Shimmer.fromColors(
//       baseColor: Colors.grey[800]!,
//       highlightColor: Colors.grey[700]!,
//       child: Container(
//         width: screenWidth * 0.8, // Match charger card width
//         height: screenHeight * 0.2, // Match charger card height
//         margin: EdgeInsets.only(
//           right: screenWidth * 0.013,
//           top: screenHeight * 0.03,
//           bottom: screenHeight * 0.05,
//           left: screenHeight * 0.03, // Add extra left margin for the first card
//         ),
//         decoration: BoxDecoration(
//           color: const Color(0xFF0E0E0E),
//           borderRadius: BorderRadius.circular(
//               screenWidth * 0.01), // Same border radius as charger card
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               spreadRadius: 2,
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: EdgeInsets.only(
//             left: screenWidth * 0.01,
//             top: screenHeight * 0.02,
//             bottom: screenHeight * 0.02,
//             right: screenWidth * 0.01, // Add right padding for all cards
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: screenWidth * 0.25,
//                 height: screenHeight * 0.02,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 5),
//               Container(
//                 width: screenWidth * 0.2,
//                 height: screenHeight * 0.02,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 5),
//               Row(
//                 children: [
//                   Container(
//                     width: screenWidth * 0.15,
//                     height: screenHeight * 0.02,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(width: 5),
//                   Container(
//                     width: screenWidth * 0.05,
//                     height: screenHeight * 0.02,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Container(
//                 width: screenWidth * 0.6,
//                 height: screenHeight * 0.02,
//                 color: Colors.white,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChargerCard(
//     BuildContext context,
//     String landmark,
//     String chargerId,
//     LatLng position,
//     String distance,
//   ) {
//     // Get screen size

//     // Get the charger from the list based on chargerId
//     final charger = availableChargers.firstWhere(
//       (c) => c['charger_id'] == chargerId,
//       orElse: () => null,
//     );

//     // Get the address directly from the charger object (fetched once)
//     String placeName = charger?['address'] ?? 'Unknown Address';
//     String address = charger?['address'] ?? 'Unknown Address';
//     placeName = truncateText(placeName, 79);
//     landmark = truncateText(landmark, 20);

//     return GestureDetector(
//       onTap: () {
//         if (charger != null) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ChargerConnectorPage(
//                 userId: widget.userId,
//                 address: address,
//                 position: position,
//                 username: widget.username,
//                 email: widget.email,
//               ),
//             ),
//           );
//         }
//       },
//       child: Stack(
//         children: [
//           Container(
//             width: MediaQuery.of(context).size.width *
//                 0.9, // Use MediaQuery for width
//             margin: EdgeInsets.only(
//               right: MediaQuery.of(context).size.width * 0.05,
//               // bottom: MediaQuery.of(context).size.height * 0.02,
//               top: MediaQuery.of(context).size.height * 0.04,
//             ),
//             decoration: BoxDecoration(
//               color: const Color(0xFF0E0E0E),
//               borderRadius: BorderRadius.circular(
//                   MediaQuery.of(context).size.width * 0.03),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   spreadRadius: 2,
//                   blurRadius: 5,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Padding(
//               padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize
//                     .min, // Allow the column to grow based on content
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Landmark and Place Name
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '📍 $landmark',
//                               style: TextStyle(
//                                 fontSize:
//                                     MediaQuery.of(context).size.width * 0.037,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//                             Text(
//                               placeName,
//                               style: TextStyle(
//                                 fontSize:
//                                     MediaQuery.of(context).size.width * 0.033,
//                                 color: Colors.white70,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(
//                       height: 5), // Space before the distance container
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         vertical: MediaQuery.of(context).size.height * 0.008,
//                         horizontal: MediaQuery.of(context).size.width * 0.03,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(
//                             0xFF1C1C1C), // Dark background to match the card
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize
//                             .min, // Only take up as much space as needed
//                         children: [
//                           Icon(
//                             Icons.directions,
//                             color: const Color(
//                                 0xFF4CAF50), // Lime green color for the icon
//                             size: MediaQuery.of(context).size.width * 0.04,
//                           ),
//                           const SizedBox(
//                               width: 4), // Space between icon and text
//                           Flexible(
//                             // Use Flexible to avoid overflow
//                             child: Text(
//                               distance,
//                               style: TextStyle(
//                                 fontSize:
//                                     MediaQuery.of(context).size.width * 0.032,
//                                 fontWeight: FontWeight.bold,
//                                 color: const Color(
//                                     0xFFB2FF59), // Light green color for distance text
//                               ),
//                               overflow:
//                                   TextOverflow.ellipsis, // Prevent overflow
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChargerListContainer() {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 5),
//         child: Column(
//           children: [
//             if (isLoading)
//               // Show shimmer effect when data is loading
//               Expanded(
//                 child: SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: List.generate(
//                         3,
//                         (index) =>
//                             _buildShimmerCard()), // Display 3 shimmer cards
//                   ),
//                 ),
//               )
//             else if (isChargerAvailable)
//               // Render the actual charger list if data is loaded and chargers are available
//               Expanded(
//                 child: _buildChargerList(),
//               )
//           ],
//         ),
//       ),
//     );
//   }Widget _buildChargerList() {
//   List<Widget> chargerCards = [];
//   Set<String> chargerIds = {}; // Track charger IDs to avoid duplicates
//   Set<String> uniqueLocations = {}; // Track unique lat/long combinations
//   chargerIdsList.clear(); // Clear previous IDs to avoid duplicates
//   isChargerAvailable = false; // Reset the flag initially

//   List<Map<String, dynamic>> chargersWithDistance = []; // To store charger data with distance

//   // Check if data is loading and show shimmer if true
//   if (isLoading) {
//     // Data is still loading, show shimmer cards
//     for (var i = 0; i < 3; i++) {
//       chargerCards.add(_buildShimmerCard());
//     }
//   } else {
//     LatLng referencePosition = _currentSelectedLocation != null
//         ? LatLng(
//             double.parse(_currentSelectedLocation!['latitude']),
//             double.parse(_currentSelectedLocation!['longitude']),
//           )
//         : (_currentPosition ?? _center); // Get reference position for distance calculation

//     // Process based on the active filter
//     List<dynamic> chargersToProcess = activeFilter == 'Previously Used'
//         ? recentSessions
//         : availableChargers;

//     for (var charger in chargersToProcess) {
//       String chargerId = activeFilter == 'Previously Used'
//           ? charger['details']['charger_id']?.trim() ?? 'Unknown ID'
//           : charger['charger_id']?.trim() ?? 'Unknown ID';

//       double chargerLatitude = activeFilter == 'Previously Used'
//           ? double.parse(charger['details']['lat'] ?? '0')
//           : double.parse(charger['lat'] ?? '0');
//       double chargerLongitude = activeFilter == 'Previously Used'
//           ? double.parse(charger['details']['long'] ?? '0')
//           : double.parse(charger['long'] ?? '0');

//       String locationKey = '$chargerLatitude,$chargerLongitude';

//       // Avoid duplicates based on charger ID and unique lat/long
//       if (!chargerIds.contains(chargerId) &&
//           !uniqueLocations.contains(locationKey)) {
//         double distanceInKm = _calculateDistance(
//           referencePosition.latitude,
//           referencePosition.longitude,
//           chargerLatitude,
//           chargerLongitude,
//         );

//         if (distanceInKm <= 100.0) { // Limit results within 100km
//           chargerIds.add(chargerId);
//           uniqueLocations.add(locationKey);
//           chargerIdsList.add(chargerId); // Add charger ID to the separate list

//           // Store charger data along with distance for sorting
//           chargersWithDistance.add({
//             'chargerId': chargerId,
//             'latitude': chargerLatitude,
//             'longitude': chargerLongitude,
//             'distance': distanceInKm,
//             'chargerData': charger, // Store entire charger data to pass to _buildChargerCard
//           });
//         }
//       }
//     }

//     // Sort the chargers by distance
//     chargersWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

//     // Build the charger cards based on sorted data
//     for (var chargerInfo in chargersWithDistance) {
//       String distanceText = "${chargerInfo['distance'].toStringAsFixed(2)} km";
//       var charger = chargerInfo['chargerData'];

//       chargerCards.add(
//         _buildChargerCard(
//           context,
//           activeFilter == 'Previously Used'
//               ? charger['details']['landmark'] ?? 'Unknown location'
//               : charger['landmark'] ?? 'Unknown location',
//           chargerInfo['chargerId'],
//           LatLng(chargerInfo['latitude'], chargerInfo['longitude']),
//           distanceText, // Pass distance as a string
//         ),
//       );
//       isChargerAvailable = true; // Set flag to true if at least one charger is available
//     }
//   }

//   return Expanded(
//     child: PageView.builder(
//       controller: _pageController,
//       scrollDirection: Axis.horizontal,
//       itemCount: chargerCards.length,
//       onPageChanged: (index) {
//         // Fetch corresponding charger info from sorted list
//         var chargerInfo = chargersWithDistance[index];
//         String chargerId = chargerInfo['chargerId'];
//         double latitude = chargerInfo['latitude'];
//         double longitude = chargerInfo['longitude'];
        
//         // Call _onChargerCardChanged with relevant data
//         _onChargerCardChanged(chargerId, LatLng(latitude, longitude), chargerInfo['distance']);
//       },
//       itemBuilder: (context, index) {
//         return chargerCards[index];
//       },
//     ),
//   );
// }

// void _onChargerCardChanged(String chargerId, LatLng chargerPosition, double distance) {
//   print("_onChargerCardChanged: $chargerId, Distance: $distance km");

//   // Cancel any existing debounce timers
//   _debounceTimer?.cancel();

//   // Add a short debounce duration (e.g., 150ms)
//   _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
//     // Find the charger in the availableChargers list using the chargerId
//     var charger = availableChargers.firstWhere(
//       (charger) => charger['charger_id'] == chargerId,
//       orElse: () => null,
//     );

//     if (charger != null) {
//       // The latitude and longitude are now passed directly as `chargerPosition`
//       if (mapController != null) {
//         LatLng startPosition = _selectedPosition ?? _currentPosition ?? _center;

//         // If an animation is in progress, cancel it before starting a new one
//         if (_isAnimationInProgress) {
//           _currentAnimationOperation?.cancel();
//         }

//         _isAnimationInProgress = true;

//         // Wrap the animation in a CancelableOperation
//         _currentAnimationOperation = CancelableOperation.fromFuture(
//           _smoothlyMoveCameraForChargerMarker(startPosition, chargerPosition),
//         );

//         try {
//           await _currentAnimationOperation!.value;

//           // Animation completed, update state
//           if (mounted) {
//             setState(() {
//               _selectedPosition = chargerPosition;
//               areMapButtonsEnabled = true; // Enable map buttons

//               // Update marker icons, using chargerId
//               _updateMarkerIcons(chargerId);
//             });
//           }
//         } catch (e) {
//           print("Animation was cancelled or failed: $e");
//         } finally {
//           _isAnimationInProgress = false;
//         }
//       }
//     }
//   });
// }


// // Truncate text if it's longer than the max length
//   String truncateText(String text, int maxLength) {
//     if (text.length > maxLength) {
//       return '${text.substring(0, maxLength)}...';
//     }
//     return text;
//   }
// }

// class ConnectorSelectionDialog extends StatefulWidget {
//   final Map<String, dynamic> chargerData;
//   final Function(int, int) onConnectorSelected;
//   final String username;
//   final int? userId;
//   final String email;
//   final Map<String, dynamic>? selectedLocation; // Accept the selected location

//   const ConnectorSelectionDialog({
//     super.key,
//     required this.chargerData,
//     required this.onConnectorSelected,
//     required this.username,
//     this.userId,
//     required this.email,
//     this.selectedLocation,
//   });

//   @override
//   _ConnectorSelectionDialogState createState() =>
//       _ConnectorSelectionDialogState();
// }

// class _ConnectorSelectionDialogState extends State<ConnectorSelectionDialog> {
//   int? selectedConnector;
//   int? selectedConnectorType;

//   bool _isFormValid() {
//     return selectedConnector != null && selectedConnectorType != null;
//   }

//   String _getConnectorTypeName(int connectorType) {
//     if (connectorType == 1) {
//       return 'Socket';
//     } else if (connectorType == 2) {
//       return 'Gun';
//     }
//     return 'Unknown';
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     // Get the screen size using MediaQuery
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenWidth < 400;

//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: 16.0,
//         horizontal: isSmallScreen ? 12.0 : 16.0,
//       ),
//       decoration: const BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // Ensures it takes minimum space
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           // Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Select Connector',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: isSmallScreen ? 18 : 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white),
//                 onPressed: () {
//                    Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => HomePage(
//                         selectedLocation: widget.selectedLocation,
//                         username: widget.username,
//                         userId: widget.userId,
//                         email: widget.email,
//                       ),
//                     ),
//                   );
                  
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           CustomGradientDivider(),
//           const SizedBox(height: 20),

//           // Connector Grid
//   GridView.builder(
//   shrinkWrap: true, // Prevents unnecessary space
//   physics: const NeverScrollableScrollPhysics(),
//   itemCount: widget.chargerData.keys
//       .where((key) => key.startsWith('connector_') && key.endsWith('_type'))
//       .length,
//   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//     crossAxisCount: 2,
//     mainAxisSpacing: 10,
//     crossAxisSpacing: 10,
//     childAspectRatio: 3,
//   ),
//   itemBuilder: (BuildContext context, int index) {
//     // Fetch the available connector keys dynamically
//     List<String> connectorKeys = widget.chargerData.keys
//         .where((key) => key.startsWith('connector_') && key.endsWith('_type'))
//         .toList();

//     String connectorKey = connectorKeys[index]; // Use the key directly
//     int connectorId = index + 1; // Still keep the numbering for display purposes
//     int? connectorType = widget.chargerData[connectorKey];

//     if (connectorType == null) {
//       return const SizedBox.shrink(); // Skip if there's no valid connector
//     }

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedConnector = connectorId;
//           selectedConnectorType = connectorType;
//         });
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: selectedConnector == connectorId
//               ? Colors.green
//               : Colors.grey[800],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Center(
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 connectorType == 1 ? Icons.power : Icons.ev_station,
//                 color: connectorType == 1 ? Colors.green : Colors.red,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 _getConnectorTypeName(connectorType),
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : 16,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 ' - [ $connectorId ]',
//                 style: TextStyle(
//                   color: Colors.blue,
//                   fontWeight: FontWeight.bold,
//                   fontSize: isSmallScreen ? 14 : 16,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   },
// ),

//           const SizedBox(height: 10), // Adjust this spacing as needed

//           // Continue Button
//           ElevatedButton(
//             onPressed: _isFormValid()
//                 ? () {
//                     if (selectedConnector != null &&
//                         selectedConnectorType != null) {
//                       widget.onConnectorSelected(
//                           selectedConnector!, selectedConnectorType!);
//                       Navigator.of(context).pop();
//                     }
//                   }
//                 : null,
//             style: ButtonStyle(
//               backgroundColor: MaterialStateProperty.resolveWith<Color>(
//                 (Set<MaterialState> states) {
//                   if (states.contains(MaterialState.disabled)) {
//                     return Colors.green.withOpacity(0.2);
//                   }
//                   return const Color(0xFF1C8B40);
//                 },
//               ),
//               minimumSize: MaterialStateProperty.all(
//                 Size(double.infinity, isSmallScreen ? 45 : 50),
//               ),
//               shape: MaterialStateProperty.all(
//                 RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               elevation: MaterialStateProperty.all(0),
//             ),
//             child: Text(
//               'Continue',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: isSmallScreen ? 14 : 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// class SlantedLabel extends StatelessWidget {
//   final String? distance;

//   const SlantedLabel({required this.distance, super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Get screen width and height
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;

//     return Positioned(
//       top: screenHeight * 0.09, // Adjusted for screen height
//       right: screenWidth * 0.05, // Adjusted for screen width
//       child: Stack(
//         children: [
//           ClipPath(
//             clipper: SlantClipper(),
//             child: Container(
//               color: const Color(0xFF0E0E0E),
//               height: screenHeight * 0.05, // Adjusted for screen height
//               width: screenWidth * 0.25, // Adjusted for screen width
//             ),
//           ),
//           Positioned(
//             right: screenWidth * 0.04, // Adjusted for screen width
//             top: screenHeight * 0.005, // Adjusted for screen height
//             child: Text(
//               "$distance",
//               style: TextStyle(
//                 color: Colors.green,
//                 fontWeight: FontWeight.normal,
//                 fontSize: screenWidth * 0.03, // Adjusted for screen width
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SlantClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     Path path = Path();
//     path.lineTo(20, 0);
//     path.lineTo(0, size.height / 2);
//     path.lineTo(20, size.height);
//     path.lineTo(size.width, size.height);
//     path.lineTo(size.width, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) {
//     return false;
//   }
// }

// class CrossPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF8E8E8E)
//       ..strokeWidth = 2.0
//       ..strokeCap = StrokeCap.round;

//     // Calculate offsets for top and bottom reduction
//     final offset =
//         size.height * 0.1; // Adjust this factor to change the reduction

//     // Draw the diagonal line from top-right to bottom-left with equal reduction
//     canvas.drawLine(
//       Offset(size.width - offset,
//           offset), // Starting point (inward from top-right)
//       Offset(offset,
//           size.height - offset), // Ending point (inward from bottom-left)
//       paint,
//     );
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }

// class CurrentLocationMarkerPainter extends CustomPainter {
//   final double animatedRadius;

//   CurrentLocationMarkerPainter({required this.animatedRadius});

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Ensure size is appropriate
//     if (size.width == 0 || size.height == 0) return;

//     final double outerCircleRadius = animatedRadius;
//     final double dotRadius = size.width / 8;
//     final double borderThickness = size.width / 24;

//     // Draw the translucent outer circle
//     final Paint circlePaint = Paint()
//       ..color = Colors.blue.withOpacity(0.2)
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(
//       Offset(size.width / 2, size.height / 2),
//       outerCircleRadius,
//       circlePaint,
//     );

//     // Draw the solid blue dot
//     final Paint dotPaint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;

//     canvas.drawCircle(
//       Offset(size.width / 2, size.height / 2),
//       dotRadius,
//       dotPaint,
//     );

//     // Draw the white border
//     final Paint borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = borderThickness;

//     canvas.drawCircle(
//       Offset(size.width / 2, size.height / 2),
//       dotRadius,
//       borderPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     if (oldDelegate is CurrentLocationMarkerPainter) {
//       return oldDelegate.animatedRadius != animatedRadius;
//     }
//     return true; // Repaint if not the same type
//   }
// }

// class CurrentLocationMarker extends StatefulWidget {
//   const CurrentLocationMarker({super.key});

//   @override
//   _CurrentLocationMarkerState createState() => _CurrentLocationMarkerState();
// }

// class _CurrentLocationMarkerState extends State<CurrentLocationMarker>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);

//     _animation = Tween<double>(begin: 50.0, end: 100.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: CurrentLocationMarkerPainter(
//             animatedRadius: _animation.value,
//           ),
//           child: const SizedBox(
//             width: 150, // Set a specific size for your marker
//             height: 150,
//           ),
//         );
//       },
//     );
//   }
// }

// class LoadingOverlay extends StatelessWidget {
//   final bool showAlertLoading;
//   final Widget child;

//   LoadingOverlay(
//       {super.key, required this.showAlertLoading, required this.child});

//   Widget _buildLoadingIndicator() {
//     return Container(
//       width: double.infinity,
//       height: double.infinity,
//       // color: Colors.black.withOpacity(0.75), // Transparent black background
//       color: Colors.black.withOpacity(0.90), // Transparent black background
//       child: Center(
//         child: _AnimatedChargingIcon(), // Use the animated charging icon
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         child, // The main content
//         if (showAlertLoading)
//           _buildLoadingIndicator(), // Use the animated loading indicator
//       ],
//     );
//   }
// }

// class _AnimatedChargingIcon extends StatefulWidget {
//   @override
//   __AnimatedChargingIconState createState() => __AnimatedChargingIconState();
// }

// class __AnimatedChargingIconState extends State<_AnimatedChargingIcon>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _slideAnimation;
//   late Animation<double> _opacityAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..forward(); // Start the animation

//     // Slide animation for moving the bolt icon vertically downwards
//     _slideAnimation = Tween<double>(begin: -130.0, end: 60.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );

//     // Opacity animation for smooth fading in and out
//     _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: Curves.easeInOut,
//       ),
//     );

//     _controller.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         // Reset the animation to start from the top when it reaches the bottom
//         _controller.reset();
//         _controller.forward();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Transform.translate(
//           offset: Offset(0, _slideAnimation.value), // Move vertically
//           child: Opacity(
//             opacity: _opacityAnimation.value,
//             child: child,
//           ),
//         );
//       },
//       child: const Icon(
//         Icons.bolt_sharp, // Charging icon
//         color: Colors.green, // Set the icon color
//         size: 200, // Adjust the size as needed
//       ),
//     );
//   }
// }

// class ErrorDetails extends StatelessWidget {
//   final String? errorData;
//   final String username;
//   final int? userId;
//   final String email;
//   final Map<String, dynamic>? selectedLocation; // Accept the selected location

//   const ErrorDetails(
//       {Key? key,
//       required this.errorData,
//       required this.username,
//       this.userId,
//       required this.email,
//       this.selectedLocation})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: const BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center, // Center the content
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               const Text(
//                 'Error Details',
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white),
//                 onPressed: () {
//                   // Use Navigator.push to add the new page without disrupting other content  
//                                   // Navigate to HomePage without disrupting other content
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => HomePage(
//                         selectedLocation: selectedLocation,
//                         username: username,
//                         userId: userId,
//                         email: email,
//                       ),
//                     ),
//                   );
//                   // Close the QR code scanner page and return to the Home Page
//                 },
//               ),
//             ],
//           ),
//           const SizedBox(
//               height: 10), // Add spacing between the header and the green line
//           CustomGradientDivider(),
//           const SizedBox(
//               height: 20), // Add spacing between the green line and the icon
//           const Icon(
//             Icons.error_outline,
//             color: Colors.red,
//             size: 70,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             errorData ?? 'An unknown error occurred.',
//             style: const TextStyle(color: Colors.white70, fontSize: 20),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }
// }
