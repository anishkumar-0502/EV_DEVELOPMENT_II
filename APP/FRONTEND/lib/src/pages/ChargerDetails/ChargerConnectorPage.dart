import 'dart:convert';
import 'package:ev_app/src/pages/Charging/charging.dart';
import 'package:ev_app/src/pages/Home_contents/home_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this package for launching URLs
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

class ChargerConnectorPage extends StatefulWidget {
  final String address;
  final int? userId;
  final LatLng position;
  final String username; // Make the username parameter nullable
  final String email;

  const ChargerConnectorPage({
    required this.address,
    super.key,
    required this.position,
    this.userId,
    required this.username,
    required this.email,
  });

  @override
  _ChargerConnectorPageState createState() => _ChargerConnectorPageState();
}

class _ChargerConnectorPageState extends State<ChargerConnectorPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  late String mapStyle; // Declare the mapStyle variable
  List<Map<String, dynamic>> availableChargers =
      []; // List to store multiple chargers
  bool isLoading = true;
  String searchChargerID = '';
  List recentSessions = [];
  GoogleMapController? mapController;
  bool isSearching = false;
  bool areMapButtonsEnabled = false;
  bool isChargerAvailable = false; // Flag to track if any charger is available
  static const String apiKey = 'AIzaSyDezbZNhVuBMXMGUWqZTOtjegyNexKWosA';
  Map<String, String> _addressCache = {};
  List<String> chargerIdsList = [];
  // Declare charger at the class level
  Map<String, dynamic> charger = {
    'charger_id': '',
    'charger_type': '',
    'last_used_time': '',
    'unit_price': 0.0,
    "status": '',
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Set the initial index to 0 for the "Charger" tab
    _currentIndex = 0; // Active state for the first tab
    fetchAllChargers();
    _loadMapStyle(); // Load the map style when the page is initialized
  }

  Future<void> _loadMapStyle() async {
    mapStyle = await rootBundle.loadString('assets/Map/map.json');
    setState(() {}); // Call setState to update the UI after loading the style
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void showErrorDialog(BuildContext context, String message) {
     setState(() {
      isSearching = false;
              isLoading = false; // Set loading to false on error

      });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: ErrorDetails(
              errorData: message,
              username: widget.username,
              email: widget.email,
              userId: widget.userId),
        );
      },
    ).then((_) {});
  }

  Future<String> _getPlaceName(LatLng position, String chargerId) async {
    // Check if the address is already cached
    if (_addressCache.containsKey(chargerId)) {
      return _addressCache[chargerId]!;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        String fetchedAddress = data['results'][0]['formatted_address'];
        // Store the fetched address in the cache
        _addressCache[chargerId] = fetchedAddress;
        return fetchedAddress;
      } else {
        return "Unknown Location";
      }
    } else {
      throw Exception('Failed to fetch place name');
    }
  }

  Future<void> fetchAllChargers() async {
    // Set loading state to true
    setState(() {
      isLoading = true;
      availableChargers.clear(); // Clear previous chargers if needed
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://122.166.210.142:4444/getAllChargersWithStatusAndPrice'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': widget.userId}),
      );

      final data = json.decode(response.body);
      print("Filtered Charger Data Position: $data");

      // Check if the response is successful
      if (response.statusCode == 200) {
        final List<dynamic> chargerData = data['data'] ?? [];

        // Filter chargers based on the specific latitude and longitude from widget.position
        List<dynamic> filteredChargerData = chargerData.where((charger) {
          final lat = double.tryParse(charger['lat'] ?? '0');
          final long = double.tryParse(charger['long'] ?? '0');
          return lat == widget.position.latitude &&
              long == widget.position.longitude;
        }).toList();
        print("filteredChargerData $filteredChargerData");

        // Create a list to hold unique chargers with addresses
        List<Map<String, dynamic>> uniqueChargers = [];
        final Set<String> chargerIds = {}; // To track unique charger IDs

        // Fetch addresses for each filtered charger and store in a new field
        for (var charger in filteredChargerData) {
          final chargerId = charger['charger_id'] ?? 'Unknown ID';

          // Check if this charger has already been added to the unique list
          if (!chargerIds.contains(chargerId)) {
            chargerIds.add(chargerId); // Add to the set of unique IDs
            final lat = double.tryParse(charger['lat'] ?? '0');
            final long = double.tryParse(charger['long'] ?? '0');

            // Fetch address using the charger’s coordinates
            String address =
                await _getPlaceName(LatLng(lat!, long!), chargerId);

            // Extract the last used time from the status array, if available
            String lastUsedTime = 'Not yet received';
            if (charger['status'] != null &&
                charger['status'] is List &&
                charger['status'].isNotEmpty) {
              // Assuming the status array contains timestamp inf
              final status = charger['status'].firstWhere(
                (status) => status['timestamp'] != null,
                orElse: () => null,
              );
              if (status != null) {
                lastUsedTime = formatTimestamp(
                    status['timestamp']); // Format the timestamp
              }
            }

            // Determine accessibility
            final isPrivate = charger['charger_accessibility'] ==
                2; // Assuming 1 means public

            // Extract and update charger status
            String chargerStatus = 'Not yet updated';
            if (charger['status'] != null &&
                charger['status'] is List &&
                charger['status'].isNotEmpty) {
              final status = charger['status'].firstWhere(
                (status) => status['charger_status'] != null,
                orElse: () => null,
              );
              if (status != null) {
                chargerStatus = status['charger_status'];
              }
            }

            // Add the charger with the fetched address, formatted status timestamp, accessibility status, and charger status to the unique list
            uniqueChargers.add({
              'charger_id': chargerId,
              'charger_type': charger['charger_type'] ?? 'Unknown Type',
              'last_used_time':
                  lastUsedTime, // Store the formatted status timestamp
              'unit_price': charger['unit_price'] ?? 0.0,
              'address': address, // Store the fetched address
              'is_private': isPrivate, // Store the accessibility
              'status': chargerStatus, // Store the charger status
            });
          }
        }

        // Update available chargers with the unique chargers data
        setState(() {
          availableChargers = uniqueChargers; // Set the unique chargers
          isLoading = false; // Set loading to false after data is set

          // Optional: Set the first charger as the sample charger data
          if (uniqueChargers.isNotEmpty) {
            final firstCharger = uniqueChargers.first;
            print("firstCharger $firstCharger");
            charger = {
              'charger_id': firstCharger['charger_id'] ?? 'Unknown ID',
              'charger_type': firstCharger['charger_type'] ?? 'Unknown Type',
              'last_used_time': firstCharger['last_used_time'] ?? ' - ',
              'unit_price': firstCharger['unit_price'] ?? 0.0,
              'status': firstCharger['status'] ?? 'Unknown',
            };
          }
        });
      } else {
        // Handle error response
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false; // Set loading to false on error
        });
      }
    } catch (error) {
      print('Internal server error: $error');
      // Handle general errors
      showErrorDialog(
          context, 'An unexpected error occurred. Please try again.');
      setState(() {
        isLoading = false; // Set loading to false on error
      });
    }
  }

// Function to format the timestamp
  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A'; // Handle null case

    // Define date format patterns
    final rawFormat = DateTime.tryParse(timestamp);
    final formatter = intl.DateFormat('MM/dd/yyyy, hh:mm:ss a');
    // final formatter = intl.DateFormat('MM/dd/yyyy');

    if (rawFormat != null) {
      // If the timestamp is in ISO format, parse and format
      final parsedDate = rawFormat.toLocal();
      return formatter.format(parsedDate);
    } else {
      // Otherwise, assume it's already in the desired format and return it
      return timestamp; // Or 'Invalid date' if you want to handle improperly formatted strings
    }
  }
@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final String location = widget.address;
  final LatLng position = widget.position;

  return Scaffold(
    body: Stack(
      children: [
        // The main content of the page
        Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 250.0,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Image.asset(
                    'assets/Image/Connecter_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Positioned(
                  top: 30,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.share, color: Colors.black),
                    onPressed: () {
                      // Extract latitude and longitude from the position variable
                      double latitude = position.latitude;
                      double longitude = position.longitude;

                      // Create the shareable message with a Google Maps link
                      String message =
                          "Explore the EV POWER for seamless EV charging experience!\n\n"
                          "Location: $location\n\n"
                          "Charge your EV now!\n"
                          "Check the location on the map: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

                      // Share the message
                      Share.share(message);
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          "Open Now",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "24 Hours",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildNavigationBar(screenWidth),
                    const SizedBox(height: 10),
                    CustomGradientDivider(),
                    _buildContent(screenWidth),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Conditionally render the loading overlay if `isSearching` is true
        if (isSearching)
          Container(
            color: Colors.black.withOpacity(0.5), // Semi-transparent background
            child: Center(
              child: _AnimatedChargingIcon(), // Loading indicator
            ),
          ),
      ],
    ),
  );
}


  Widget _buildContent(double screenWidth) {
    // Calculate the available height
    final availableHeight = MediaQuery.of(context).size.height;

    return Container(
      height:
          availableHeight, // Set height dynamically based on available space
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildChargerSessionsContent(screenWidth),
          _buildLocationSessionsContent(screenWidth),
        ],
      ),
    );
  }

  Widget _buildChargerSessionsContent(double screenWidth) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(5.0),
        margin: const EdgeInsets.only(bottom: 430),
        child: Column(
          children: availableChargers.isNotEmpty
              ? availableChargers.map((charger) {
                  return _buildChargerDetails(screenWidth, charger);
                }).toList()
              : List.generate(
                  2, // Number of shimmer cards to show
                  (index) => _buildShimmerCard(screenWidth),
                ),
        ),
      ),
    );
  }

  Future<void> updateConnectorUser(
      String searchChargerID, int connectorId, int connectorType) async {
    setState(() {
      isSearching = false;
    });
    print("response: updateConnectorUser");

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/updateConnectorUser'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
          'connector_id': connectorId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Charging(
              searchChargerID: searchChargerID,
              username: widget.username,
              userId: widget.userId,
              connector_id: connectorId,
              connector_type: connectorType,
              email: widget.email,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      showErrorDialog(context, 'Internal server error ');
    }
  }
  void showloadingpage() {
     setState(() {
      isSearching = false;
      });

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Center(
          child: SizedBox(
            child: _AnimatedChargingIcon(),
          ),
        );
      },
    );
  }
  Future<Map<String, dynamic>?> handleSearchRequest(
      String searchChargerID) async {
    if (isSearching) return null;

    print("response: handleSearchRequest");

    if (searchChargerID.isEmpty) {
      showErrorDialog(context, 'Please enter a charger ID.');
      return {'error': true, 'message': 'Charger ID is empty'};
    }

    setState(() {
      isSearching = true;
    });


    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/SearchCharger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
        }),
      );
      // Optional: Delay to show the loading animation for a bit longer if needed
      await Future.delayed(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          this.searchChargerID = searchChargerID;
          isSearching = false;
        });

        // Dismiss the loading animation
        // if (mounted) Navigator.of(context).pop();

        // Return the successful response data
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorDatas =  errorData['message'];
         print("ododod 2: $errorDatas");

        showErrorDialog(context, errorData['message']);

        // Dismiss the loading animation
        // if (mounted) Navigator.of(context).pop();

      }
    } catch (error) {
      showErrorDialog(context, 'Internal server error');

      // Dismiss the loading animation
      if (mounted) Navigator.of(context).pop();

      return {'error': true, 'message': 'Internal server error'};
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
    return null;
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Preparing':
        return Colors.orange;
      case 'Charging':
        return Colors.orange;
      case 'Finishing':
        return Colors.orange;
      case 'Unavailable':
        return Colors.red;
      case 'Faulted':
        return Colors.red;
      default:
        return Colors
            .white54; // Default color for other statuses or if not updated
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case 'Available':
        return 'Available';
      case 'Faulted':
        return 'Faulted';
      case 'Preparing':
        return 'Busy';
      case 'Charging':
        return 'Busy';
      case 'Finishing':
        return 'Busy';
      case 'Unavailable':
        return 'Unavailable';
      default:
        return 'Not yet updated';
    }
  }

  Widget _buildChargerDetails(
      double screenWidth, Map<String, dynamic> charger) {
    return Card(
      // margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: Colors.grey[900],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Expanded(
            //       child: Text(
            //         charger['charger_id'] ?? 'Unknown Charger ID',
            //         style: TextStyle(
            //           fontSize: screenWidth * 0.045,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white,
            //         ),
            //       ),
            //     ),
            //     Icon(
            //       charger['is_private'] == true ? Icons.lock : Icons.lock_open,
            //       color: charger['is_private'] == true
            //           ? Colors.orange
            //           : Colors.green,
            //       size: 22,
            //     ),
            //   ],
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    charger['charger_id'] ?? 'Unknown Charger ID',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  charger['is_private'] == true ? 'Private' : 'Public',
                  style: TextStyle(
                    color: charger['is_private'] == true
                        ? Colors.orange
                        : Colors.green,
                    fontSize: screenWidth * 0.04, // Adjust font size as needed
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                                    Text(
                  getStatusText(charger['status']),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: getStatusColor(charger['status']),
                  ),
                ),

                  ],
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                    Icon(
                      Icons.access_time, // Clock icon
                      size: screenWidth * 0.04, // Adjust the size as needed
                      color: Colors.grey[400], // Set the icon color
                    ),
                    const SizedBox(
                        width: 4), // Space between the icon and the text
                    Text(
                      "${charger['last_used_time'] ?? 'Not yet received'}",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[400],
                      ),
                    ),
                const Spacer(),
                Text(
                  charger['charger_type'] ?? 'Unknown Type',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.currency_rupee,
                  color: Colors.yellowAccent,
                  size: screenWidth * 0.04,
                ),
                const SizedBox(width: 4),
                Text(
                  '${charger['unit_price'] ?? 'N/A'}/kWh',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),
            CustomGradientDivider(),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1C),
                  side: const BorderSide(
                    color: Colors.green, // Set the border color to green
                    width: 0.3, // Set the border width
                  ),
                  elevation: 3, // Set elevation for shadow effect
                  shadowColor: const Color(
                      0xFFB2FF59), // Set shadow color to green// Set the background color to green
                ),
                onPressed: () async {
                  final data = await handleSearchRequest(charger['charger_id']);
                  print("connectorIdconnectorId data $data" );
                  if (data != null && !data.containsKey('error')) {
                    if (mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        isDismissible: false,
                        enableDrag: false,
                        backgroundColor: Colors.black,
                        builder: (BuildContext context) {
                          return Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: ConnectorSelectionDialog(
                              chargerData: data['socketGunConfig'] ?? {},
                              onConnectorSelected:
                                  (connectorId, connectorType) {
                                updateConnectorUser(charger['charger_id'],
                                    connectorId, connectorType);
                              },
                              username: widget.username,
                              email: widget.email,
                              userId: widget.userId,
                            ),
                          );
                        },
                      );
                    }
                  }
                },
                child: const Text(
                  'View Connectors',
                  style: TextStyle(
                    color: const Color(0xFFB2FF59),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(double screenWidth) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        color: Colors.grey[900],
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.5,
                height: 15, // Height for the shimmer effect
                color: Colors.white,
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    height: 15, // Height for the shimmer effect
                    color: Colors.white,
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                width: screenWidth * 0.5,
                height: 15, // Height for the shimmer effect
                color: Colors.white,
              ),
              const SizedBox(height: 3),
              Container(
                width: screenWidth * 0.5,
                height: 15, // Height for the shimmer effect
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              CustomGradientDivider(),
              const SizedBox(height: 5),
              Center(
                child: Container(
                  width: screenWidth * 0.3,
                  height: 30, // Height for the shimmer effect
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar(double screenWidth) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly, // Distributes space evenly
      children: [
        Expanded(child: _buildNavItem("Charger", 0, screenWidth)),
        Expanded(child: _buildNavItem("Location", 1, screenWidth)),
      ],
    );
  }

  Widget _buildNavItem(String title, int index, double screenWidth) {
    // Determine if the current index is active
    bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.jumpToPage(index);
      },
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Center the text vertically
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.white70,
              fontSize: screenWidth < 600
                  ? 16
                  : 20, // Adjust font size based on screen width
            ),
            textAlign: TextAlign.center, // Center the text horizontally
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            width: isActive ? 50 : 0,
            height: 3,
            color: Colors.green,
            curve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSessionsContent(double screenWidth) {
    return SizedBox(
      child: Padding(
        padding:
            const EdgeInsets.only(top: 15.0, left: 5, right: 5, bottom: 450),
        child: Container(
          height: 100, // Set a fixed height for the map container
          width: double
              .infinity, // Set the width to match the parent width (full width)
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(15), // Optional: Add rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset:
                    const Offset(0, 3), // Optional: Add a shadow for styling
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
                10), // Same as above to clip the map's corners
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.position,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('chargerLocation'),
                  position: widget.position,
                  infoWindow: const InfoWindow(
                    title: 'Charger Location',
                    snippet: "landmark", // Show landmark in the snippet
                  ),
                  onTap: () {
                    _launchMapsUrl(
                        widget.position.latitude, widget.position.longitude);
                  },
                ),
              },
              onMapCreated: (GoogleMapController controller) async {
                String mapStyle =
                    await rootBundle.loadString('assets/Map/map.json');
                controller.setMapStyle(mapStyle);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _launchMapsUrl(double latitude, double longitude) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
}

class _AnimatedChargingIcon extends StatefulWidget {
  @override
  __AnimatedChargingIconState createState() => __AnimatedChargingIconState();
}

class __AnimatedChargingIconState extends State<_AnimatedChargingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward(); // Start the animation

    // Slide animation for moving the bolt icon vertically downwards
    _slideAnimation = Tween<double>(begin: -130.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Opacity animation for smooth fading in and out
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the animation to start from the top when it reaches the bottom
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value), // Move vertically
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.bolt_sharp, // Charging icon
        color: Colors.green, // Set the icon color
        size: 200, // Adjust the size as needed
      ),
    );
  }
}

class ConnectorSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> chargerData;
  final Function(int, int) onConnectorSelected;
  final String username;
  final int? userId;
  final String email;
  final Map<String, dynamic>? selectedLocation; // Accept the selected location

  const ConnectorSelectionDialog({
    super.key,
    required this.chargerData,
    required this.onConnectorSelected,
    required this.username,
    this.userId,
    required this.email,
    this.selectedLocation,
  });

  @override
  _ConnectorSelectionDialogState createState() =>
      _ConnectorSelectionDialogState();
}

class _ConnectorSelectionDialogState extends State<ConnectorSelectionDialog> {
  int? selectedConnector;
  int? selectedConnectorType;

  bool _isFormValid() {
    return selectedConnector != null && selectedConnectorType != null;
  }

  String _getConnectorTypeName(int connectorType) {
    if (connectorType == 1) {
      return 'Socket';
    } else if (connectorType == 2) {
      return 'Gun';
    }
    return 'Unknown';
  }
  
  @override
  Widget build(BuildContext context) {
    // Get the screen size using MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: isSmallScreen ? 12.0 : 16.0,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensures it takes minimum space
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Connector',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomGradientDivider(),
          const SizedBox(height: 20),

          // Connector Grid
  GridView.builder(
  shrinkWrap: true, // Prevents unnecessary space
  physics: const NeverScrollableScrollPhysics(),
  itemCount: widget.chargerData.keys
      .where((key) => key.startsWith('connector_') && key.endsWith('_type'))
      .length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 3,
  ),
  itemBuilder: (BuildContext context, int index) {
    // Fetch the available connector keys dynamically
    List<String> connectorKeys = widget.chargerData.keys
        .where((key) => key.startsWith('connector_') && key.endsWith('_type'))
        .toList();

    String connectorKey = connectorKeys[index]; // Use the key directly
    int connectorId = index + 1; // Still keep the numbering for display purposes
    int? connectorType = widget.chargerData[connectorKey];

    if (connectorType == null) {
      return const SizedBox.shrink(); // Skip if there's no valid connector
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedConnector = connectorId;
          selectedConnectorType = connectorType;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: selectedConnector == connectorId
              ? Colors.green
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                connectorType == 1 ? Icons.power : Icons.ev_station,
                color: connectorType == 1 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _getConnectorTypeName(connectorType),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ' - [ $connectorId ]',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
),

          const SizedBox(height: 10), // Adjust this spacing as needed

          // Continue Button
          ElevatedButton(
            onPressed: _isFormValid()
                ? () {
                    if (selectedConnector != null &&
                        selectedConnectorType != null) {
                      widget.onConnectorSelected(
                          selectedConnector!, selectedConnectorType!);
                      Navigator.of(context).pop();
                    }
                  }
                : null,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.green.withOpacity(0.2);
                  }
                  return const Color(0xFF1C8B40);
                },
              ),
              minimumSize: MaterialStateProperty.all(
                Size(double.infinity, isSmallScreen ? 45 : 50),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
