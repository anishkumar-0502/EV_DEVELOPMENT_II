import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class TripLoadingAnimation extends StatelessWidget {
  const TripLoadingAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rotating Map Marker
          SpinKitRotatingCircle(
            color: Colors.green, // Use marker color or theme color
            size: 60.0,
          ),
          SizedBox(height: 16),
          // Loading Text
          Text(
            "Finding your location...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
