
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  LatLng? _currentLocation;

  LocationService._internal();

  static LocationService get instance => _instance;

  Future<LatLng?> getCurrentLocation() async {
    if (_currentLocation == null) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);
    }
    return _currentLocation;
  }

  void updateCurrentLocation(LatLng newLocation) {
    _currentLocation = newLocation;
  }
}
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


  // Future<void> _getCurrentLocation() async {
  //   // If a location fetch is already in progress, don't start a new one
  //   if (_isFetchingLocation) return;

  //   setState(() {
  //     _isFetchingLocation = true;
  //   });
    
  // // if (_currentSelectedLocation != null ){
  // //   setState(() {
  // //     _currentSelectedLocation = null;
  // //   });
  // // }

  //   try {
  //     // Ensure location services are enabled and permission is granted before fetching location
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       await _showLocationServicesDialog();
  //       return;
  //     }

  //     PermissionStatus permission = await Permission.location.status;
  //     if (permission.isDenied) {
  //       await _showPermissionDeniedDialog();
  //       return;
  //     } else if (permission.isPermanentlyDenied) {
  //       await _showPermanentlyDeniedDialog();
  //       return;
  //     }

  //     // Fetch the current location if permission is granted
  //     LatLng? currentLocation =
  //         await LocationService.instance.getCurrentLocation();
  //     print("_onMapCreated currentLocation $currentLocation");

  //     if (currentLocation != null) {
  //       // Update the current position
  //       setState(() {
  //         _currentPosition = currentLocation;
  //       });

  //       // Smoothly animate the camera to the new position if the mapController is available
  //       if (mapController != null) {
  //         await mapController!.animateCamera(
  //           CameraUpdate.newCameraPosition(
  //             CameraPosition(
  //               target: _currentPosition!,
  //               zoom: 18.0, // Adjust zoom level as needed
  //               tilt: 45.0, // Add a tilt for a 3D effect
  //               // bearing:
  //               //     _previousBearing ?? 0, // Use previous bearing if available
  //             ),
  //           ),
  //         );
  //       }

  //       // Update the current location marker on the map
  //       _updateMarkers();
  //       fetchAllChargers();
  //       // await _updateCurrentLocationMarker(_previousBearing ?? 0);
  //     } else {
  //       print('Current location could not be determined.');
  //     }
  //   } catch (e) {
  //     print('Error occurred while fetching the current location: $e');
  //   } finally {
  //     setState(() {
  //       _isFetchingLocation = false;
  //     });
  //   }
  // }

