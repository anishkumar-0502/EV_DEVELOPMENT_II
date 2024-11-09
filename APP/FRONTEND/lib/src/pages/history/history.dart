import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../utilities/Seperater/gradientPainter.dart';
import 'package:shimmer/shimmer.dart';

class HistoryPage extends StatefulWidget {
  final String? username;
  final int? userId;

  const HistoryPage({super.key, this.username, this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String activeTab = 'history'; // Initial active tab
  List<Map<String, dynamic>> sessionDetails = [];
  bool isLoading = true; // Variable to track loading state

  @override
  void initState() {
    super.initState();
    fetchChargingSessionDetails();
  }

  // Function to set session details
  void setSessionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      sessionDetails = value;
      isLoading = false; // Set loading to false once data is loaded
    });
  }

  // Function to fetch charging session details
  void fetchChargingSessionDetails() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/session/getChargingSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
        if (data['value'] is List) {
          List<dynamic> chargingSessionData = data['value'];
          List<Map<String, dynamic>> sessionDetails = chargingSessionData.cast<Map<String, dynamic>>();
          setState(() {
            this.sessionDetails = sessionDetails; // Update sessionDetails
            isLoading = false; // Stop loading
          });
        } else {
          throw Exception('Session details format is incorrect');
        }
      } else {
        throw Exception('Failed to load session details');
      }
    } catch (error) {
      print('Error fetching session details: $error');
      setState(() {
        isLoading = false; // Stop loading on error
      });
    }
  }


  // Function to show session details modal
  void _showSessionDetailsModal(Map<String, dynamic> sessionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black, // Set background color to black
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SessionDetailsModal(sessionData: sessionData),
        );
      },
    );
  }

  // Function to show help modal
  void _showsessionhelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: const HelpModal(),
          ),
        );
      },
    );
  }

  double _calculateTotalEnergyUsage() {
    double totalEnergy = 0.0;

    for (var session in sessionDetails) {
      totalEnergy += double.tryParse(session['unit_consummed'].toString()) ?? 0.0;
    }

    // Returning the total energy with 3 decimal places
    return double.parse(totalEnergy.toStringAsFixed(3));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showsessionhelp,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 15.5, top: 15.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Sessions',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Explore the details of your charging session',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          isLoading
              ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildShimmerCard(), // Display shimmer card while loading
          )
              :
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              Container(

                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('Total sessions',style: TextStyle(fontSize: 16, color: Colors.white),), // Changed to 'Total sessions' for clarity
                    SizedBox(height: 5),
                    Text(sessionDetails.length.toString(),style: TextStyle(fontSize: 16, color: Colors.white70),), // Display total count of sessions
                  ],
                ),
              ),
              Container(

                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Total energy usage',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_calculateTotalEnergyUsage().toString()}',
                            style: TextStyle(fontSize: 16, color: Colors.green), // The value in green
                          ),
                          TextSpan(
                            text: ' kWh',
                            style: TextStyle(fontSize: 16, color: Colors.white70), // 'kWh' in white70
                          ),
                        ],
                      ),
                    ), // Display the total energy consumed with 'kWh' added, and the value in green
                  ],
                )


              ),
            ],
          ),

          SizedBox(height: 20,),
          Expanded(
            child: SingleChildScrollView(
              child: Scrollbar(
                child: Column(
                  children: [
                    isLoading
                        ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildShimmerCard(), // Display shimmer card while loading
                    )
                        : sessionDetails.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Image.asset(
                              'assets/Image/search.png', // Use the correct path to your asset
                              width: 300, // Optional: Adjust image size
                            ),
                          ),
                          const SizedBox(height: 10), // Add some space between the image and the text
                          const Text(
                            'No Session History Found!', // Add your desired text
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white70, // Optional: Adjust text color
                            ),
                          ),
                        ],
                      ),
                    )
                        : Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 20, bottom: 50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            children: [
                              for (int index = 0; index < sessionDetails.length; index++)
                                InkWell(
                                  onTap: () {
                                    _showSessionDetailsModal(sessionDetails[index]);
                                  },
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    sessionDetails[index]['charger_id'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    sessionDetails[index]['start_time'] != null
                                                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(
                                                      DateTime.parse(sessionDetails[index]['start_time'])
                                                          .toLocal(),
                                                    )
                                                        : "-",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white60,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  ' Rs. ${sessionDetails[index]['price']}',
                                                  style: const TextStyle(
                                                    fontSize: 19,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  '${sessionDetails[index]['unit_consummed']} kWh',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index != sessionDetails.length - 1) CustomGradientDivider(),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }

  // Shimmer loading card widget
  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 100, height: 20, color: Colors.white),
              const SizedBox(height: 5),
              Container(width: 80, height: 20, color: Colors.white),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(width: 50, height: 20, color: Colors.white),
                  const SizedBox(width: 5),
                  Container(width: 20, height: 20, color: Colors.white),
                ],
              ),
              const SizedBox(height: 5),
              Container(width: double.infinity, height: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionDetailsModal extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailsModal({Key? key, required this.sessionData}) : super(key: key);

  String _getConnectorTypeName(int? connectorType) {
    switch (connectorType) {
      case 1:
        return 'Socket';
      case 2:
        return 'Gun';

      default:
        return 'Unknown';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session Details',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.ev_station, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Charger ID',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              '${sessionData['charger_id']}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),


          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.numbers, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Connector Id',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              '${sessionData['connector_id']}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.numbers, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Connector Type',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              _getConnectorTypeName(sessionData['connector_type']),
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.numbers, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Session ID',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              '${sessionData['session_id']}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.access_time, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Start Time',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              sessionData['start_time'] != null
                  ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(sessionData['start_time']).toLocal())
                  : "-",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.stop, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Stop Time',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              sessionData['stop_time'] != null
                  ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(sessionData['stop_time']).toLocal())
                  : "-",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Icon(Icons.electric_car, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Units Consumed',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              '${sessionData['unit_consummed']} kWh',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              child: const Text(
                '\u20B9', // Indian Rupee symbol
                style: TextStyle(color: Colors.white, fontSize: 24), // Customize size as needed
              ),
            ),
            title: const Text(
              'Price',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              'Rs. ${sessionData['price']}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Help modal widget
class HelpModal extends StatelessWidget {
  const HelpModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Help & Support',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          CustomGradientDivider(),
          const SizedBox(height: 16),

          // Wrap the scrollable content inside a SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session History',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This page displays a list of your past charging sessions. You can tap on any session to view detailed information, including charger ID, session ID, start time, end time, units consumed, and price.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Viewing Session Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To view details of a specific session, tap on the session entry in the list. This will open a modal at the bottom of the screen displaying detailed information about the session.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Help & Support',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For any further assistance or issues, please contact our support team @ support@outdidtech.com. You can find contact details in the app settings or visit our website for more help.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


