import 'dart:isolate';
import 'dart:async';
import 'package:flutter/material.dart';
import 'Home_contents/home_content.dart'; // Import the HomeContent file
import '../components/footer.dart';
import 'wallet/wallet.dart';
import 'history/history.dart';
import 'profile/profile.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'; // Import the foreground task package
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int? userId;
  final String email;
    final Map<String, dynamic>? selectedLocation; // Accept the selected location


  const HomePage({super.key, required this.username, this.userId, required this.email, this.selectedLocation});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final GlobalKey<FooterState> _footerKey = GlobalKey();
  late Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isDialogOpen = false; // Track if the dialog is open


  @override
  void initState() {
    super.initState();
     _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
    startForegroundService(); // Start the foreground service
  }


  Future<void> _checkInitialConnection() async {
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }
  void _updateConnectionStatus(ConnectivityResult result) {

    // Check for specific connection types (Wi-Fi or Mobile Data)
    if (result == ConnectivityResult.mobile) {
      // Connected to mobile data
      _dismissConnectionDialog(); // Close any dialog if mobile data is connected
    } else if (result == ConnectivityResult.wifi) {
      // Connected to Wi-Fi
      _dismissConnectionDialog(); // Close any dialog if Wi-Fi is connected
    } else if (result == ConnectivityResult.none) {
      // No internet connection
      if (!_isDialogOpen) {
        _showNoConnectionDialog(result); // Show dialog with specific message
      }
    }
  }

  void _showNoConnectionDialog(ConnectivityResult result) {
    String message;

    if (result == ConnectivityResult.none) {
      message = 'Mobile data is off. Please turn it on or connect to Wi-Fi.';
    } else {
      message = 'No Internet Connection. Please check your connection.';
    }

    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 35),
                  SizedBox(width: 10),
                  Text(
                    "Mobile data required",
                    style: TextStyle(color: Colors.white,fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(), // Custom gradient divider
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70), // Adjusted text color for contrast
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                _checkInitialConnection(); // Retry connection check
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Retry", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                SystemNavigator.pop(); // Close the app
              },
              child: const Text("Close App", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isDialogOpen = false; // Update state when dialog is dismissed
      });
    });
  }
  void _dismissConnectionDialog() {
    if (_isDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss the alert
      _isDialogOpen = false;
    }
  }
  
  @override
  void dispose() {
    FlutterForegroundTask.stopService(); // Stop the foreground service when the app is closed
     _connectivitySubscription.cancel();
    super.dispose();
  }


  void startForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service_channel',
        channelName: 'Foreground Service Channel',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        iconData: const NotificationIconData(
          resType: ResourceType.drawable,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // The interval at which the foreground task will be executed (in milliseconds)
        isOnceEvent: false, // Whether to execute the task only once
        autoRunOnBoot: true, // Whether to automatically run the task on boot
      ),
    );

    FlutterForegroundTask.startService(
      notificationTitle: 'EV App is running',
      notificationText: 'Your app is running in the background',
      callback: startCallback,
    );
  }

  void startCallback() {
    FlutterForegroundTask.setTaskHandler(YourTaskHandler());
  }

  void _onTabChanged(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _pageOptions = [
      HomeContent(username: widget.username, userId: widget.userId, email: widget.email, selectedLocation: widget.selectedLocation),
      WalletPage(username: widget.username, userId: widget.userId, email: widget.email ),
      HistoryPage(username: widget.username, userId: widget.userId),
      ProfilePage(username: widget.username, userId: widget.userId, email: widget.email),
    ];

    return WillPopScope(
      onWillPop: () async {
        final footerState = _footerKey.currentState;
        if (footerState != null) {
          return footerState.handleBackPress();
        }
        return true;
      },
      child: Scaffold(
        body: _pageOptions[_pageIndex],
        bottomNavigationBar: Footer(
          key: _footerKey,
          onTabChanged: _onTabChanged,
        ),
      ),
    );
  }
}

class YourTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // Perform any initialization you need here.
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Your background task logic here
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cleanup tasks when the foreground service is destroyed
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp(); // Bring your app to the foreground
  }
}
