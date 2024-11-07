import 'package:flutter/material.dart';


class LocationProvider with ChangeNotifier {
  Map<String, dynamic>? _selectedLocation;

  Map<String, dynamic>? get selectedLocation => _selectedLocation;

  void setLocation(Map<String, dynamic> location) {
    _selectedLocation = location;
    notifyListeners(); // Notify listeners to update UI when the location changes
  }

  void clearLocation() {
    _selectedLocation = null;
    notifyListeners();
  }
}
