import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';  // Import shimmer package

class TransactionHistoryPage extends StatefulWidget {
  final String username;
  final int? userId;

  const TransactionHistoryPage({super.key, required this.username, this.userId});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  List<Map<String, dynamic>> transactionDetails = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
      isLoading = false; // Stop loading once data is set
    });
  }

  // Function to fetch transaction details
  void fetchTransactionDetails() async {
    String? username = widget.username;
    print(username);

    if (username.isEmpty) {
      print('Error: Username is null or empty');
      return;
    }

    print('Fetching transaction details for username: $username');

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/wallet/getTransactionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> transactionData = data['value'];
          List<Map<String, dynamic>> transactions = transactionData.map((transaction) {
            return {
              'status': transaction['status'] ?? 'Unknown',
              'amount': transaction['amount'] ?? '0.00',
              'time': transaction['time'] ?? 'N/A',
            };
          }).toList();
          setTransactionDetails(transactions);
        } else {
          print('Error: transaction details format is incorrect');
        }
      } else {
        print('Error: Failed to load transaction details');
        throw Exception('Failed to load transaction details');
      }
    } catch (error) {
      print('Error fetching transaction details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomGradientDivider(),
              const SizedBox(height: 15),
              TransactionDetailsWidget(
                transactionDetails: transactionDetails,
                isLoading: isLoading, // Pass loading state
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
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
          Color.fromRGBO(0, 0, 0, 0.75),
          Color.fromRGBO(0, 128, 0, 0.75),
          Colors.green,
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

class TransactionDetailsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactionDetails;
  final bool isLoading;

  const TransactionDetailsWidget({
    Key? key,
    required this.transactionDetails,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? _buildShimmer()
        : transactionDetails.isEmpty
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
            'No Payment History Found!', // Add your desired text
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70, // Optional: Adjust text color
            ),
          ),
        ],
      ),
    )
        : Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          for (int index = 0; index < transactionDetails.length; index++)
            Column(
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
                              transactionDetails[index]['status'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              (() {
                                final timeString = transactionDetails[index]['time'];
                                if (timeString != null && timeString.isNotEmpty) {
                                  try {
                                    final dateTime = DateTime.parse(timeString).toLocal();
                                    return DateFormat('MM/dd/yyyy, hh:mm:ss a').format(dateTime);
                                  } catch (e) {
                                    print('Error parsing date: $e');
                                  }
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
                        '${transactionDetails[index]['status'] == 'Credited'
                            ? '+ ₹'
                            : '- ₹'}${transactionDetails[index]['amount']}',
                        style: TextStyle(
                          fontSize: 19,
                          color: transactionDetails[index]['status'] == 'Credited' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != transactionDetails.length - 1) CustomGradientDivider(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade700,
      highlightColor: Colors.grey.shade500,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: List.generate(3, (index) => _buildShimmerItem()),
        ),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.grey,
                ),
                const SizedBox(height: 5),
                Container(
                  height: 15,
                  width: 100,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            width: 80,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
