import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // Tile caching
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import custom widgets and utility files
import 'src/pages/Auth/Log_In/login.dart';
import 'src/pages/home.dart';
import 'src/utilities/User_Model/user.dart';
import 'src/utilities/User_Model/ImageProvider.dart';
import 'src/pages/wallet/wallet.dart';
import 'src/pages/profile/Account/Transaction_Details/transaction_details.dart';


void main() async {
  // Ensure Flutter bindings are initialized before calling any asynchronous methods
  WidgetsFlutterBinding.ensureInitialized();

  // Set the system UI overlay styles
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize the tile caching
  Object? initErr;
  try {
    await FMTCObjectBoxBackend().initialise();
  } catch (err) {
    initErr = err;
  }
  // Now run the app with providers
  runApp(MyApp(initialisationError: initErr));
}

// SessionHandler to manage user session and connection status
class SessionHandler extends StatefulWidget {
  final bool loggedIn;

  const SessionHandler({super.key, this.loggedIn = false});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    _retrieveUserData();
  }

  // Retrieve stored user data from SharedPreferences
  Future<void> _retrieveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUser = prefs.getString('user');
    int? storedUserId = prefs.getInt('userId');
    String? storedEmail = prefs.getString('email');

    if (storedUser != null && storedUserId != null && storedEmail != null) {
      Provider.of<UserData>(context, listen: false).updateUserData(storedUser, storedUserId, storedEmail);
    }
  }

  // Update connection status based on connectivity change
  void _updateConnectionStatus(ConnectivityResult result) {
    // Handle connectivity updates
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return userData.username != null
        ? HomePage(username: userData.username ?? '', userId: userData.userId ?? 0, email: userData.email ?? '')
        : const LoginPage();
  }
}

// App Container to manage initialization error and app state
class MyApp extends StatelessWidget {
  const MyApp({required this.initialisationError});

  final Object? initialisationError;

  @override
  Widget build(BuildContext context) {
    final ThemeData customTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
    );

if (initialisationError case final err?) {
  return MaterialApp(
    title: 'FMTC Demo (Initialisation Error)',
    theme: customTheme,
    home: InitialisationError(error: err), // Provide a default message
  );
}


    // Return main app with multiple providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserData()),
        ChangeNotifierProvider(create: (_) => UserImageProvider()),
        ChangeNotifierProvider(create: (_) => GeneralProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RegionSelectionProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ConfigureDownloadProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => DownloadingProvider(), lazy: true),
      ],
      child: MaterialApp(
        title: 'EV',
        debugShowCheckedModeBanner: false,
        theme: customTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SessionHandler(),
          '/home': (context) => const SessionHandler(loggedIn: true),
          '/wallet': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
            return WalletPage(username: args['username'], userId: args['userId'], email: args['email_id'],);
          },
          '/transaction_details': (context) => TransactionDetailsWidget(
            transactionDetails: ModalRoute.of(context)?.settings.arguments as List<Map<String, dynamic>>,
            username: AutofillHints.username,
          ),
        },
      ),
    );
  }
}



class GeneralProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


class MapProvider with ChangeNotifier {
  double _zoomLevel = 12.0;
  String _currentRegion = "Default Region";

  double get zoomLevel => _zoomLevel;
  String get currentRegion => _currentRegion;

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom;
    notifyListeners();
  }

  void setCurrentRegion(String region) {
    _currentRegion = region;
    notifyListeners();
  }
}

class DownloadingProvider with ChangeNotifier {
  double _progress = 0.0;
  bool _isDownloading = false;

  double get progress => _progress;
  bool get isDownloading => _isDownloading;

  void startDownload() {
    _isDownloading = true;
    _progress = 0.0;
    notifyListeners();
  }

  void updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }

  void completeDownload() {
    _isDownloading = false;
    _progress = 100.0;
    notifyListeners();
  }
}

class ConfigureDownloadProvider with ChangeNotifier {
  String _region = "Default Region";
  bool _isConfigured = false;

  String get region => _region;
  bool get isConfigured => _isConfigured;

  void configureDownload(String newRegion) {
    _region = newRegion;
    _isConfigured = true;
    notifyListeners();
  }

  void resetConfiguration() {
    _isConfigured = false;
    notifyListeners();
  }
}


class RegionSelectionProvider with ChangeNotifier {
  String _selectedRegion = "Default Region";

  String get selectedRegion => _selectedRegion;

  void selectRegion(String region) {
    _selectedRegion = region;
    notifyListeners();
  }
}


class InitialisationError extends StatelessWidget {
  final Object error;

  const InitialisationError({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            const Text(
              'An error occurred during initialization:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // You can add a retry mechanism or go back to the previous screen
                Navigator.of(context).pop();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}