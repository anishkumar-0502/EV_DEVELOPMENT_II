import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactionDetails;
  final String username;
  final int? userId;

  const TransactionDetailsWidget(
      {Key? key, required this.username, this.userId, required this.transactionDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return transactionDetails.isEmpty
        ? Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20.0),
      child: const Center(
        child: Text(
          'No transaction history found.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
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
                                    // Handle the parsing error
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
                          color: transactionDetails[index]['status'] ==
                              'Credited' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index !=
                    transactionDetails.length - 1) CustomGradientDivider(),
              ],
            ),
        ],
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
