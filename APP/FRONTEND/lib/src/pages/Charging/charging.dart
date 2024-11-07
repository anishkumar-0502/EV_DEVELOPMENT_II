import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../home.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import './Settings/stop_charger.dart';
import '../../utilities/Alert/alert_banner.dart';

String formatTimestamp(DateTime originalTimestamp) {
  return DateFormat('MM/dd/yyyy, hh:mm:ss a').format(originalTimestamp.toLocal());
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.2, // Adjust this to change the overall height of the divider
      child: CustomPaint(
        painter: GradientPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.75), // Darker black shade
          Color.fromRGBO(0, 128, 0, 0.75), // Darker green for blending
          Colors.green, // Green color in the middle
        ],
        end: Alignment.center,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.0)
      ..quadraticBezierTo(size.width / 3, 0, size.width, size.height * 0.99)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class Charging extends StatefulWidget {
  final String username; // Make the username parameter nullable
  final String searchChargerID;
  final int? connector_id;
  final int? userId;
  final int? connector_type;
  final String email;



  const Charging({
    Key? key,
    required this.searchChargerID,
    required this.username,
    required this.connector_id,
    required this.userId,
    required this.connector_type, required this.email,
  }) : super(key: key);

  @override
  State<Charging> createState() => _ChargingPageState();
}

class _ChargingPageState extends State<Charging> with SingleTickerProviderStateMixin {
  String activeTab = 'home';
  late WebSocketChannel channel;
  late AnimationController _controller;
  bool showMeterValuesContainer = false; // Declare this in your state class

  String chargerStatus = '';
  String TagIDStatus = '';
  bool NoResponseFromCharger = false;
  String timestamp = '';
  String chargerCapacity = '';
  bool isTimeoutRunning = false;
  bool isStarted = false;
  bool checkFault = false;
  bool isErrorVisible = false;
  bool isThresholdVisible = false;
  bool isBatteryScreenVisible = false;
  bool showVoltageCurrentContainer = false;
  bool showAlertLoading = false;
  List<Map<String, dynamic>> history = [];
  String voltage = '';
  String current = '';
  String power = '';
  String energy = '';
  String frequency = '';
  String temperature = '';



  // State for voltage and current of three phases
  String voltageV1 = '';
  String voltageV2 = '';
  String voltageV3 = '';
  String currentA1 = '';
  String currentA2 = '';
  String currentA3 = '';


  late double _currentTemperature;

  final ScrollController _scrollController = ScrollController();
  bool isStartButtonEnabled = true; // Initial state
  bool isStopButtonEnabled = false;
  bool charging = false;
  String chargerID = '';
  String username = '';
  String errorCode = '';

  void seterrorCode(String errorCode) {
    setState(() {
      this.errorCode = errorCode;
    });
  }

bool _isStopLoading = false;
  bool showSuccessAlert = false;
  bool showErrorAlert = false;
  bool showAlert = false;
  Map<String, dynamic> chargingSession = {};
  Map<String, dynamic> updatedUser = {};

  void setApiData(Map<String, dynamic> chargerSession, Map<String, dynamic> userValue) {
    setState(() {
      chargingSession = chargerSession;
      updatedUser = userValue;
      showAlert = true;
    });
  }

Widget _buildLoadingIndicator() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.black.withOpacity(0.7), // Transparent black background
    child: const Center(
      child: Icon(
        Icons.bolt, // Use a charging icon like 'bolt' or 'electric_car'
        color: Colors.yellow, // Set the icon color
        size: 300, // Adjust the size as needed
      ),
    ),
  );
}


  void handleCloseAlert() async {
    bool checkFault = false; // Example value, set it based on your logic
    if (!checkFault) {
      Navigator.of(context).pop();
    }
    setState(() {
      showAlert = false;
    });
  }

  void showSuccess() {
    setState(() {
      showSuccessAlert = true;
    });
  }

  void closeSuccess() {
    setState(() {
      showSuccessAlert = false;
    });
  }

  void showError() {
    setState(() {
      showErrorAlert = true;
    });
  }

  void closeError() {
    setState(() {
      showErrorAlert = false;
    });
  }

  void handleLoadingStart() {
    setState(() {
      showAlertLoading = true;
    });
  }

  void handleLoadingStop() {
    setState(() {
      showAlertLoading = false;
    });
  }

  void setIsStarted(bool value) {
    setState(() {
      isStarted = value;
    });
  }

  void setCheckFault(bool value) {
    setState(() {
      checkFault = value;
    });
  }

  void startTimeout() {
    setState(() {
      isTimeoutRunning = true;
    });
  }

  void stopTimeout() {
    setState(() {
      isTimeoutRunning = false;
    });
  }

  bool isLoading = false; // Track loading state

  void handleAlertLoadingStart(BuildContext context) {
    setState(() {
      showAlertLoading = true;
    });
  }

  void showNoResponseAlert() {
  setState(() {
    NoResponseFromCharger = true;
  });

  // Automatically hide the alert after 3 seconds
  Timer(const Duration(seconds: 3), () {
    setState(() {
      NoResponseFromCharger = false;
    });
  });
}

  Future<void> endChargingSession(String chargerID, int? connectorId) async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/endChargingSession'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'charger_id': chargerID, 'connector_id': connectorId}),
      );

        final data = jsonDecode(response.body);
        print("endChargingSession $data");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Charging session ended: $data');
      } else {
        print('Failed to end charging session. Status code: ${response.statusCode}');
      }
      dispose();
    } catch (error) {
      print('Error ending charging session: $error');
    }
  }

  Future<void> updateSessionPriceToUser(int? connectorId) async {
    try {
      handleAlertLoadingStart(context);

    // Introduce a 3-second delay before sending the request
    await Future.delayed(const Duration(seconds: 4));

      var url = Uri.parse('http://122.166.210.142:4444/charging/getUpdatedCharingDetails');
      var body = {
        'chargerID': chargerID,
        'user': username,
        "connectorId": connectorId,
      };
      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await http.post(url, headers: headers, body: jsonEncode(body));


      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        showAlertLoading = false;
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var chargingSession = data['value']['chargingSession'];
        var updatedUser = data['value']['user'];

        print('Charging Session: $chargingSession');
        print('Updated User: $updatedUser');

        Future<void> handleCloseButton() async {
          handleLoadingStop();  // Stop loading when the button is clicked
          if (chargerStatus == "Faulted" || chargerStatus == 'Unavailable') {
            Navigator.pop(context);
          } else {
            await endChargingSession(chargerID, widget.connector_id);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(username: username,userId: widget.userId, email: widget.email,),
              ),
            );
          }
        }

        Future<void> showCustomAlertDialog(BuildContext context, Map<String, dynamic> chargingSession, Map<String, dynamic> updatedUser) async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return ChargingCompleteModal(
                chargingSession: chargingSession,
                updatedUser: updatedUser,
                onClose: () {
                  // Your close button logic here
                  handleCloseButton();
                },
              );
            },
          );
        }

        showCustomAlertDialog(context, chargingSession, updatedUser);
      } else {
        // showDialog(
        //   context: context,
        //   builder: (context) => AlertDialog(
        //     title: const Text('Error'),
        //     content: const Text('Updation unsuccessful!'),
        //     actions: [
        //       TextButton(
        //         onPressed: () => Navigator.pop(context),
        //         child: const Text('OK'),
        //       ),
        //     ],
        //   ),
        // );
        const AlertBanner(
          message:'Updation unsuccessful!' ,
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      setState(() {
        showAlertLoading = false;
      });

      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: const Text('Error'),
      //     content: Text('Failed to update charging details: $error'),
      //     actions: [
      //       TextButton(
      //         onPressed: () => Navigator.pop(context),
      //         child: const Text('OK'),
      //       ),
      //     ],
      //   ),
      // );
      const AlertBanner(
        message:'Failed to update charging details' ,
        backgroundColor: Colors.red,
      );

      print('Error updating charging details: $error');
    }
  }

  void handleAlertLoadingStop() {
    setState(() {
      showAlertLoading = false;
    });
  }

  void setVoltage(String value) {
    setState(() {
      voltage = value;
    });
  }

  void setCurrent(String value) {
    setState(() {
      current = value;
    });
  }

  void setPower(String value) {
    setState(() {
      power = value;
    });
  }

  void setEnergy(String value) {
    setState(() {
      energy = value;
    });
  }

  void setFrequency(String value) {
    setState(() {
      frequency = value;
    });
  }

  void setTemperature(String value) {
    setState(() {
      temperature = value;
    });
  }

  void setHistory(Map<String, dynamic> entry) {
    setState(() {
      history.add(entry);
    });
    print("entry $entry");
  }

  void setChargerStatus(String value) {
    setState(() {
      chargerStatus = value;
    });
  }

  void setchargerCapacity(String value){
    setState(() {
      chargerCapacity = value;
    });
  }

  void setTimestamp(String currentTime) {
    setState(() {
      timestamp = currentTime;
    });
  }

  void appendStatusTime(String status, String currentTime) {
    setState(() {
      chargerStatus = status;
      timestamp = currentTime;
    });
  }

  String getCurrentTime() {
    DateTime currentDate = DateTime.now();
    String currentTime = currentDate.toIso8601String();
    return formatTimestamp(currentTime as DateTime);
  }

  Map<String, dynamic> convertToFormattedJson(List<dynamic> measurandArray) {
    Map<String, dynamic> formattedJson = {};
    for (var measurandObj in measurandArray) {
      String key = measurandObj['measurand'];
      dynamic value = measurandObj['value'];
      formattedJson[key] = value;
    }
    return formattedJson;
  }

  Future<void> fetchLastStatus(String chargerID, int? connectorId) async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/FetchLaststatus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': chargerID, 'connector_id': connectorId, 'connector_type': widget.connector_type}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("data $responseData");

        // Access the 'data' field
        final data = responseData['data'];

        // Extract necessary fields from 'data'
        final status = data['charger_status'];
        final timestamp = data['timestamp'];

        // Extract UnitPrice and ChargerCapacity
        final unitPrice = responseData['UnitPrice'];
        final chargerCapacity = responseData['ChargerCapacity'];
        print('ChargerCapacity: $chargerCapacity');
        // setState((value) {
        //   chargerCapacity = value(),
        // });

        // Format the timestamp
        final formattedTimestamp = formatTimestamp(DateTime.parse(timestamp));

        // Process the status
        if (status == 'Available' || status == 'Unavailable') {
          startTimeout();
        } else if (status == 'Charging') {
          setIsStarted(true);
          setState(() {
            charging = true;
          });
          toggleBatteryScreen();
        }

        appendStatusTime(status, formattedTimestamp);

        // Optionally, you can use unitPrice and chargerCapacity here
        print('UnitPrice: $unitPrice');
        setchargerCapacity(chargerCapacity.toString());

      } else {
        print('Failed to fetch status. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error while fetching status: $error');
    }
  }


void RcdMsg(Map<String, dynamic> parsedMessage) async {
  final String chargerID = widget.searchChargerID;

  if (parsedMessage['DeviceID'] != chargerID) return;

  final List<dynamic> message = parsedMessage['message'];

  if (message.length < 4 || message[3] == null) return;

  if (message[2] == 'MeterValues') {
    final meterValues = message[3]['meterValue'] ?? [];
    if (meterValues.isNotEmpty) {
      final sampledValue = meterValues[0]['sampledValue'] ?? [];
      // Reset all values initially
      voltageV1 = '';
      voltageV2 = '';
      voltageV3 = '';
      currentA1 = '';
      currentA2 = '';
      currentA3 = '';

      for (var value in sampledValue) {
        switch (value['unit']) {
          case 'V1':
            voltageV1 = value['value'];
            break;
          case 'V2':
            voltageV2 = value['value'];
            break;
          case 'V3':
            voltageV3 = value['value'];
            break;
          case 'A1':
            currentA1 = value['value'];
            break;
          case 'A2':
            currentA2 = value['value'];
            break;
          case 'A3':
            currentA3 = value['value'];
            break;
        }
      }

  // Determine whether to show meter values container
      setState(() {
        showMeterValuesContainer = voltageV1.isNotEmpty || currentA1.isNotEmpty;
        showVoltageCurrentContainer = voltageV1.isNotEmpty || currentA1.isNotEmpty;
      });
    }
  }

  String chargerStatus = '';
  String currentTime = '';
  String vendorErrorCode = '';
  int? connectorIds = message[3]['connectorId']; // Extract connectorId
  String msg = message[2]; // Extract msg

  if (parsedMessage['DeviceID'] == chargerID && connectorIds == widget.connector_id && msg.isNotEmpty) {
    print('Received message: $parsedMessage');
    switch (message[2]) {
      case 'StatusNotification':
        vendorErrorCode = message[3]['vendorErrorCode'] ?? '';
        chargerStatus = message[3]['status'] ?? '';
        TagIDStatus = message[3]['TagIDStatus'] ?? '';
        currentTime = formatTimestamp(DateTime.tryParse(message[3]['timestamp'] ?? DateTime.now().toString()) ?? DateTime.now());
        errorCode = message[3]['errorCode'] ?? '';


        if (chargerStatus == 'Preparing') {
          setState(() {
            charging = false;
          });
          toggleBatteryScreen();
          stopTimeout();
          setIsStarted(false);
          isStartButtonEnabled = true;
        } else if (TagIDStatus == 'Invalid') {
          setState(() {
            TagIDStatus = 'Invalid';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'Blocked') {
          setState(() {
            TagIDStatus = 'Blocked';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'Expired') {
          setState(() {
            TagIDStatus = 'Expired';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (TagIDStatus == 'ConcurrentTx') {
          setState(() {
            TagIDStatus = 'ConcurrentTx';
          });
          // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              TagIDStatus = ''; // Clear the status after 3 seconds
            });
          });
        } else if (chargerStatus == 'Available' || chargerStatus == 'Unavailable') {
          setState(() {
            charging = false;
          });
          toggleBatteryScreen();
          startTimeout();
          setIsStarted(false);
        } else if (chargerStatus == 'Charging') {
          setState(() {
            charging = true;
            isLoading = false; // Stop loading when charging starts
          });
          toggleBatteryScreen();
          setIsStarted(true);
        } else if (chargerStatus == 'Finishing') {
          setIsStarted(false);
          setState(() {
            charging = false;
            isLoading = false; // Stop loading if it was still running
          });
          handleLoadingStop();
          toggleBatteryScreen();
          await updateSessionPriceToUser(widget.connector_id);
        } else if (chargerStatus == 'Faulted' || chargerStatus ==  'SuspendedEV' ) {
          setIsStarted(false);
          setState(() async {
            charging = false;
            isLoading = false; // Stop loading if it was still running
            toggleBatteryScreen();
            print("checkout: $checkFault");
            if (!checkFault) {
              showErrorDialog(context);
              setCheckFault(true);
            }
          });

               // Clear the TagIDStatus after 3 seconds
          Future.delayed(const Duration(seconds: 3), () async {
                await updateSessionPriceToUser(widget.connector_id);

          });
          print("checkout: $checkFault");
        } else if (chargerStatus == 'Unavailable') {
          setIsStarted(false);
          setState(() {
            charging = false;
            isLoading = false; // Stop loading if it was still running
            toggleBatteryScreen();
            if (!checkFault) {
              showErrorDialog(context);
            }
          });
        }

        if (errorCode != 'NoError') {
          Map<String, dynamic> entry = {
            'serialNumber': history.length + 1,
            'currentTime': currentTime,
            'chargerStatus': chargerStatus,
            'errorCode': errorCode != 'InternalError' ? errorCode : vendorErrorCode,
          };

          setState(() {
            history.add(entry);
            checkFault = true;
          });
        } else {
          setState(() {
            checkFault = false;
          });
        }
        seterrorCode(errorCode);
        break;

      case 'Heartbeat':
        currentTime = formatTimestamp(DateTime.now());
        setState(() {
          timestamp = currentTime;
        });
        print("chargerStatus: $chargerStatus $errorCode");
        break;

      case 'MeterValues':
        final meterValues = message[3]['meterValue'] ?? [];
        print(meterValues);
        final sampledValue = meterValues.isNotEmpty ? meterValues[0]['sampledValue'] : [];


        Map<String, dynamic> formattedJson = convertToFormattedJson(sampledValue);
        currentTime = formatTimestamp(DateTime.now());

        setState(() {
          setChargerStatus('Charging');
          setTimestamp(currentTime);
          setVoltage((formattedJson['Voltage'] ?? '').toString());
          setCurrent((formattedJson['Current.Import'] ?? '').toString());
          setPower((formattedJson['Power.Active.Import'] ?? '').toString());
          setEnergy((formattedJson['Energy.Active.Import.Register'] ?? '').toString());
          setFrequency((formattedJson['Frequency'] ?? '').toString());
          setTemperature((formattedJson['Temperature'] ?? '').toString());
        });

        print('{ "V": ${formattedJson['Voltage']},"A": ${formattedJson['Current.Import']},"W": ${formattedJson['Power.Active.Import']},"Wh": ${formattedJson['Energy.Active.Import.Register']},"Hz": ${formattedJson['Frequency']},"Kelvin": ${formattedJson['Temperature']}}');
        break;

      case 'Authorize':
        print("errorCode: $errorCode");
        chargerStatus = (errorCode == 'NoError' || errorCode.isEmpty) ? 'Authorize' : 'Faulted';
        currentTime = formatTimestamp(DateTime.now());
        break;

      case 'FirmwareStatusNotification':
        chargerStatus = message[3]['status']?.toUpperCase() ?? '';
        currentTime = formatTimestamp(DateTime.now());
        break;

      case 'StopTransaction':
        setIsStarted(false);
        setState(() {
          charging = false;
          //isLoading = false; // Stop loading if it was still running
        });
        currentTime = formatTimestamp(DateTime.now());
        print("StopTransaction");
        break;

      case 'Accepted':
        chargerStatus = 'ChargerAccepted';
        currentTime = formatTimestamp(DateTime.now());
        break;

      default:
        break;
    }
  }

  if (chargerStatus.isNotEmpty) {
    appendStatusTime(chargerStatus, currentTime);
  }
}


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _currentTemperature = double.tryParse(temperature) ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.searchChargerID.isNotEmpty) {
        fetchLastStatus(widget.searchChargerID, widget.connector_id);
      }
    });
    initializeWebSocket();
    chargerID = widget.searchChargerID;
    username = widget.username;
    print('Initialized chargerID: $chargerID');
    print('Initialized username: $username');
  }



  void initializeWebSocket() {
    channel = WebSocketChannel.connect(
      // Uri.parse('ws://122.166.210.142:8566'),
      Uri.parse('ws://122.166.210.142:7002'),
        // Uri.parse('ws://192.168.1.7:7050'),

    );

    channel.stream.listen(
          (message) {
        final parsedMessage = jsonDecode(message);
        if (mounted) {
          RcdMsg(parsedMessage);
        }
      },
      onDone: () async {
        if (mounted) {
          setState(() {
            charging = false;
          });
          setIsStarted(false);
          await endChargingSession(widget.searchChargerID, widget.connector_id
          );
          print('WebSocket connection closed');
        }
      },
      onError: (error) {
        if (mounted) {
          print('WebSocket error: $error');
        }
      },
      cancelOnError: true,
    );
  }

 @override
  void dispose() {
    _controller.dispose();
    channel.sink.close();
    _scrollController.dispose();
    super.dispose();
  }
  
  void toggleErrorVisibility() {
    print("isErrorVisible: $isErrorVisible");
    setState(() {
      if (isErrorVisible) {
        isErrorVisible = !isErrorVisible;
        isErrorVisible = false;
      } else {
        isThresholdVisible = false;
        isErrorVisible = !isErrorVisible;
        isErrorVisible = true;
      }
    });
  }

void toggleBatteryScreen() {
  print("Charging $charging");

  if (charging) {
    setState(() {
      // Show the battery screen and hide the meter values container
      if (!isBatteryScreenVisible) {
        isBatteryScreenVisible = true;
        showMeterValuesContainer = false;
      } else {
        // Show the meter values container and hide the battery screen
        showMeterValuesContainer = true;
        isBatteryScreenVisible = false;
      }
      
      isStartButtonEnabled = !isStartButtonEnabled;
      isStopButtonEnabled = !isStopButtonEnabled;
    });
  } else {
    setState(() {
      // Ensure both are hidden when not charging
      isBatteryScreenVisible = false;
      showMeterValuesContainer = false;
      isStopButtonEnabled = false;
    });
  }
}


  void toggleThresholdVisibility() {
    setState(() {
      if (!isThresholdVisible) {
        isErrorVisible = false;
      }
      isThresholdVisible = !isThresholdVisible;
    });
  }

  // This function starts the transaction and checks for a response
  void handleStartTransaction() async {
    String chargerID = widget.searchChargerID;
    final int? connectorId = widget.connector_id;

    try {
      setState(() {
      isLoading = true;
      NoResponseFromCharger = false;  // Reset the flag before starting
    });

    // Start a timer that will automatically stop loading after 10 seconds if no status is received
    Timer(const Duration(seconds: 10), () {
      if (isLoading) { // If still loading after 10 seconds
        setState(() {
          isLoading = false;  // Stop loading
          NoResponseFromCharger = true;  // Set the flag to show the alert banner
        });

        // Automatically hide the alert after 3 seconds
        Timer(const Duration(seconds: 3), () {
          setState(() {
            NoResponseFromCharger = false;  // Hide the alert
          });
        });
      }
    });

      final response = await http.post(
        Uri.parse('http://122.166.210.142:4444/charging/start'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'id': chargerID,
          'user_id': widget.userId,
          'connector_id': connectorId,
          'connector_type': widget.connector_type,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('ChargerStartInitiated');
        print(data['message']);
      } else {
        print('Failed to start charging: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }


  void startButtonPressed() {
    print("startButtonPressed");
    handleStartTransaction();
  }
void handleStopTransaction() async {
  String chargerID = widget.searchChargerID;
  final int? connectorId = widget.connector_id;

  try {
    setState(() {
      isLoading = true;
      _isStopLoading = true;
      NoResponseFromCharger = false;  // Reset the flag before starting
    });

    // Start a timer that will automatically stop loading after 10 seconds if no status is received
    Timer(const Duration(seconds: 10), () {
      if (isLoading) {
        setState(() {
          isLoading = false;
          _isStopLoading = false;
        });
        showNoResponseAlert();  // Show the "No response from charger" alert
      }
    });

    final response = await http.post(
      Uri.parse('http://122.166.210.142:4444/charging/stop'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'id': chargerID,
        'connectorId': connectorId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('ChargerStopInitiated');
      print(data['message']);
      // await updateSessionPriceToUser(connectorId);
    } else {
      print('Failed to stop charging: ${response.reasonPhrase}');
    }
  } catch (error) {
    print('Error: $error');
  } finally {
    // setState(() {
    //   isLoading = false;
    //   _isStopLoading = false;
    // });
  }
}

  void stopButtonPressed() {
    handleStopTransaction();
  }

  Color _getTemperatureColor() {
    if (_currentTemperature < 30) {
      return Colors.green;
    } else if (_currentTemperature < 50) {
      return const Color.fromARGB(255, 209, 99, 16);
    } else {
      return Colors.red;
    }
  }

Widget _buildAnimatedTempColorCircle() {
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: 225,
          height: 102, // Adjusted to make the card background more visible
          padding: const EdgeInsets.all(16.0), // Add padding inside the card
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current t°',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    // '${_currentTemperature.toInt()} °C' ,
                    '33.5 °C',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(width: 20), // Add some space between the circle and the text
              Container(
                width: 90,
                height: 90, // Adjusted to fit the card
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _getTemperatureColor().withOpacity(0.6),
                      _getTemperatureColor(),
                      _getTemperatureColor().withOpacity(0.6),
                    ],
                    stops: [0.0, _controller.value, 1.0],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            // '${_currentTemperature.toInt()}',
                            '33.5 ',
                            style: TextStyle(color: _getTemperatureColor(), fontSize: 15),
                          ),
                          Text(
                            '°C',
                            style: TextStyle(color: _getTemperatureColor(), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void thresholdlevel() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.black,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Colors.black,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Static Header with Close Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'THRESHOLD LEVEL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                CustomGradientDivider(),
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Voltage Level
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 10),
                                      child: Text(
                                        'Voltage Level:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Input under voltage - 175V and below.',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Input over voltage - 270V and below.',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Current
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                              child: Container(
                                width: 330,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        'Current:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Over Current- 33A',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Frequency
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                              child: Container(
                                width: 330,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        'Frequency:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Under Frequency - 47HZ',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Over Frequency - 53HZ',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Temperature
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                              child: Container(
                                width: 330,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        'Temperature:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Low Temperature - 0 °C.',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'High Temperature - 58 °C.',
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  void showErrorDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, 
          child: ErrorDialog(isErrorVisible: isErrorVisible, history: history));
      },
    );
  }

  void chargerStopSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, 
          child:  StopCharger(userId: widget.userId));
      },
    );
  }

  void navigateToHomePage(BuildContext context, String username) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(username: username,userId: widget.userId, email: widget.email),
      ),
    );
    endChargingSession(chargerID, widget.connector_id);
  }

  void _scrollToNext() {
    _scrollController.animateTo(
      _scrollController.position.pixels + 800, // Adjust the value as needed
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

   void _scrollToPrevious() {
    _scrollController.animateTo(
      _scrollController.position.pixels - 400, // Adjust the value as needed
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

 
@override
Widget build(BuildContext context) {
  String? ChargerID = widget.searchChargerID;
  int? connectorId = widget.connector_id;
  int? connector_type = widget.connector_type;

  String displayText;
  switch (connector_type) {
    case 1:
      displayText = 'Socket';
      break;
    case 2:
      displayText = 'Gun';
      break;
    default:
      displayText = 'Unknown'; // or some default value
      break;
  }

  return WillPopScope(
    onWillPop: () async {
      // This block of code will execute when the back button is pressed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(username: username, userId: widget.userId, email: widget.email),
        ),
      );
      return false; // Return false to prevent the default back behavior
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      body: LoadingOverlay(
        showAlertLoading: showAlertLoading || isLoading, // Combine both loading states
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                  top: 40.0, bottom: 23, left: 12.0, right: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      navigateToHomePage(context, username);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(0),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const Spacer(), // Adds space between the settings icons and the back icon
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: IconButton(
                      onPressed: chargerStopSettings,
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: IconButton(
                      onPressed: thresholdlevel,
                      icon: const Icon(Icons.power_outlined, color: Colors.green),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0),
                    child: IconButton(
                      onPressed: () => showErrorDialog(context),
                      icon: const Icon(Icons.info_outline, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20),
                        child: Container(
                          height: 65,
                          width: 500,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.charging_station,
                                    color: Colors.green,
                                    size: 25,
                                  ),
                                  const SizedBox(width: 15,),
                                  Text(
                                    ChargerID,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Text('||', style: TextStyle(fontSize: 30)),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.ev_station,
                                    color: Colors.red,
                                    size: 25,
                                  ),
                                  const SizedBox(width: 15,),
                                  Text(
                                    displayText,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/Image/Car.png',
                        height: 300,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 13.0, bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              // Column for status and timestamp aligned to the left
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                children: [
                                  Text(
                                    chargerStatus,
                                    style: TextStyle(
                                      color: chargerStatus == 'Faulted' ? Colors.red : Colors.green,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    timestamp,
                                    style: const TextStyle(fontSize: 14, color: Colors.white60),
                                  ),
                                ],
                              ),
                              // Spacer to push the connectorId to the right
                              const Spacer(),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      if (connectorId != null)
                                        Text(
                                          '$connectorId',
                                          style: const TextStyle(fontSize: 24, color: Colors.white70, fontWeight: FontWeight.normal),
                                        ),
                                      const SizedBox(width: 20,),
                                      const Icon(Icons.ev_station_outlined, color: Colors.red,),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$chargerCapacity ',
                                              style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.normal),
                                            ),
                                            const TextSpan(
                                              text: 'kwh',
                                              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.normal),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (chargerStatus == 'Preparing')
                              StartButton(
                                chargerStatus: chargerStatus,
                                isStartButtonEnabled: isStartButtonEnabled,
                                onPressed: startButtonPressed,
                              )
                            else if (chargerStatus == 'Available' || chargerStatus == 'Finishing' || chargerStatus == 'Faulted' || chargerStatus == "SuspendedEV")
                              const DisableButton()
                            else if (chargerStatus == 'Charging')
                              StopButton(
                                isStopButtonEnabled: isStopButtonEnabled,
                                isStopLoading: _isStopLoading, // Pass the loading state here
                                onPressed: stopButtonPressed,
                              ),
                            const SizedBox(width: 8),
                            _buildAnimatedTempColorCircle(),
                          ],
                        ),
                      ),
                      if (isBatteryScreenVisible)
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15, left: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            energy.isNotEmpty ? energy : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Energy',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                current.isNotEmpty ? current : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltage.isNotEmpty ? voltage : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToNext,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 35.0),
                                          child: Container(
                                            width: 280,
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, right: 0),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: 300, // Reduced width
                                                  height: 87, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            frequency.isNotEmpty ? frequency : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Frequency',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 300, // Reduced width
                                                  height: 87, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            power.isNotEmpty ? power : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Power',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
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
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToPrevious,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (showMeterValuesContainer) // Check if the meter values container should be shown
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15, left: 20),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _scrollController,
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            currentA1.isNotEmpty ? currentA1 : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Current 1',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                currentA2.isNotEmpty ? currentA2 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current 2',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                currentA3.isNotEmpty ? currentA3 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Current 3',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToNext,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            voltageV1.isNotEmpty ? voltageV1 : '0',                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Voltage 1',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltageV2.isNotEmpty ? voltageV2: '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage 2',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                voltageV3.isNotEmpty ? voltageV3 : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Voltage 3',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _scrollToPrevious,
                                        child: FadeTransition(
                                          opacity: _controller,
                                          child: Icon(
                                            Icons.arrow_back_ios,
                                            color: Colors.white.withOpacity(0.5),
                                            size: 50, // Reduced icon size
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Container(
                                            height: 190,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: BorderRadius.circular(15.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 10,
                                                  offset: Offset(4, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 16.0, left: 10),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                  width: 120, // Reduced width
                                                  height: 180, // Reduced height
                                                  child: Card(
                                                    color: Colors.black,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(
                                                            energy.isNotEmpty ? energy : '0',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 20, // Adjusted font size
                                                            ),
                                                          ),
                                                          const Text(
                                                            'Energy',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 16, // Adjusted font size
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                frequency.isNotEmpty ? frequency : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Frequency',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 150, // Reduced width
                                                      height: 85, // Reduced height
                                                      child: Card(
                                                        color: Colors.black,
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(1.0),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Text(
                                                                power.isNotEmpty ? power : '0',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20, // Adjusted font size
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Power',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 16, // Adjusted font size
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (TagIDStatus == 'Invalid')
              const AlertBanner(
                message: 'Invalid NFC Card',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'blocked')
              const AlertBanner(
                message: 'Your account is blocked',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'expired')
              const AlertBanner(
                message: 'Your NFC Card has expired',
                backgroundColor: Colors.red,
              ),
            if (TagIDStatus == 'Concurrent')
              const AlertBanner(
                message: 'Concurrent transaction in progress',
                backgroundColor: Colors.red,
              ),
              if (NoResponseFromCharger)
                const AlertBanner(
                message:'No response from the charger. Please try again!' ,
                backgroundColor: Colors.red,
              ),
          ],
        ),
      ),
    ),
  );
}

}

class BatteryChargeScreen extends StatefulWidget {
  @override
  _BatteryChargeScreenState createState() => _BatteryChargeScreenState();
}

class _BatteryChargeScreenState extends State<BatteryChargeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _animation = Tween<double>(begin: 0, end: 100).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: BatteryPainter(_animation.value),
        child: const SizedBox(
          width: 200,
          height: 70,
        ),
      ),
    );
  }
}

class BatteryPainter extends CustomPainter {
  final double chargeLevel;

  BatteryPainter(this.chargeLevel);

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerRadius = 3.0;
    const double tipWidth = 20.0;
    final double batteryWidth = size.width - tipWidth - 2 * cornerRadius;

    final double chargeWidth = batteryWidth * (chargeLevel / 100);
    final Paint dotPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    const double dotRadius = 10.0;
    const double dotSpacing = 29.0;
    double center = size.width / 2;
    double currentX = center;
    double maxDistance = chargeWidth / 2;

    while (currentX > center - maxDistance) {
      canvas.drawCircle(Offset(currentX, size.height / 2), dotRadius, dotPaint);
      currentX -= dotSpacing;
    }

    currentX = center + dotSpacing;

    while (currentX < center + maxDistance) {
      canvas.drawCircle(Offset(currentX, size.height / 2), dotRadius, dotPaint);
      currentX += dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


class StartButton extends StatefulWidget {
  final String chargerStatus;
  final bool isStartButtonEnabled;
  final VoidCallback? onPressed;

  const StartButton({
    required this.chargerStatus,
    required this.isStartButtonEnabled,
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _PowerButtonWidgetState createState() => _PowerButtonWidgetState();
}


class _PowerButtonWidgetState extends State<StartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.green.shade700,
      end: Colors.lightGreen,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17.0),
        child: AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.green, _colorAnimation.value!, Colors.lightGreen],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 32),
                onPressed: widget.chargerStatus == 'Preparing' && widget.isStartButtonEnabled ? widget.onPressed : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class StopButton extends StatefulWidget {
  final bool isStopButtonEnabled;
  final bool isStopLoading; // New parameter for loading state
  final VoidCallback? onPressed;

  const StopButton({
    required this.isStopButtonEnabled,
    required this.isStopLoading, // Pass the loading state
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  _StopButtonWidgetState createState() => _StopButtonWidgetState();
}

class _StopButtonWidgetState extends State<StopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.orange,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17.0),
        child: AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.red, _colorAnimation.value!, Colors.redAccent],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 32),
                onPressed: widget.isStopButtonEnabled ? widget.onPressed : null,
              ),

            ),
          ),
        ),
      ),
    );
  }
}


class DisableButton extends StatefulWidget {

  const DisableButton({
    Key? key,
  }) : super(key: key);

  @override
  _DisableButtonWidgetState createState() => _DisableButtonWidgetState();
}

class _DisableButtonWidgetState extends State<DisableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.black,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17.0),
        child: AnimatedContainer(
          duration: const Duration(seconds: 1),
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.grey, _colorAnimation.value!, Colors.white10],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.power_off, color: Colors.white, size: 32), onPressed: () {  },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class ErrorDialog extends StatelessWidget {
  final bool isErrorVisible;
  final List<Map<String, dynamic>> history;
  
  const ErrorDialog({
    Key? key,
    required this.isErrorVisible,
    required this.history,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // Hides the default back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          color: Colors.black,
          child: Column(
            children: [
              CustomGradientDivider(),
              const SizedBox(height: 25),
              history.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: const Center(
                        child: Text(
                          'History not found.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                  : Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Scrollbar(
                          child: ListView.builder(
                            shrinkWrap: true, // This ensures the ListView takes only the required space
                            itemCount: history.length,
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> transaction = history[index];
                              return Column(
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
                                                transaction['chargerStatus'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                (() {
                                                  final timeString = transaction['currentTime'];
                                                  if (timeString != null && timeString.isNotEmpty) {
                                                    return timeString;
                                                  }
                                                  return 'N/A';
                                                })(),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white60,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          transaction['errorCode'],
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index != history.length - 1) CustomGradientDivider(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}

class ChargingCompleteModal extends StatelessWidget {
  final Map<String, dynamic> chargingSession;
  final Map<String, dynamic> updatedUser;
  final VoidCallback onClose;

  const ChargingCompleteModal({
    super.key,
    required this.chargingSession,
    required this.updatedUser,
    required this.onClose,
  });

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
    return Material(
      type: MaterialType.transparency, // This ensures that Material features like elevation work
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView( // Prevent overflow
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Charging Complete',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
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
                  '${chargingSession['charger_id']}',
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
                  '${chargingSession['connector_id']}',
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
                    _getConnectorTypeName(chargingSession['connector_type']),
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
                  chargingSession['start_time'] != null
                      ? formatTimestamp(chargingSession['start_time'])
                      : "N/A",
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
                  chargingSession['stop_time'] != null
                      ? formatTimestamp(chargingSession['stop_time'])
                      : "N/A",
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
                  '${chargingSession['unit_consummed']} Kwh',
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
                  'Charging Price',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  'Rs. ${chargingSession['price']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                ),
                title: const Text(
                  'Available Balance',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                subtitle: Text(
                  '${updatedUser['wallet_bal']}',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(timestamp).toLocal());
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool showAlertLoading;
  final Widget child;

  LoadingOverlay({required this.showAlertLoading, required this.child});

  Widget _buildLoadingIndicator() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      // color: Colors.black.withOpacity(0.75), // Transparent black background
      color: Colors.black.withOpacity(0.90), // Transparent black background
      child: Center(
        child: _AnimatedChargingIcon(), // Use the animated charging icon
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // The main content
        if (showAlertLoading)
          _buildLoadingIndicator(), // Use the animated loading indicator
      ],
    );
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
