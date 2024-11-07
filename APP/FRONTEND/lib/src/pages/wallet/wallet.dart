import 'dart:convert';
import 'package:ev_app/src/utilities/Alert/alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../utilities/Seperater/gradientPainter.dart';

class WalletPage extends StatefulWidget {
  final String username;
  final int? userId;
    final String email;

  const WalletPage({super.key, required this.username, this.userId, required this.email});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Razorpay _razorpay;
  double? walletBalance;
  bool isLoading = true;
  bool showAlertLoading = false;

  double? _lastPaymentAmount; // Store the last payment amount
  final TextEditingController _amountController = TextEditingController(text: '500');
  String? _alertMessage; // Variable to hold the alert message
  String? _errorMessage;

  List<Map<String, dynamic>> transactionDetails = []; // Define transactionDetails

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchWallet(); // Fetch wallet balance when the page is initialized
    fetchTransactionDetails(); // Fetch transaction details
    _amountController.addListener(() {
      _validateAmount(); // Validate the amount and update the error message
    });
  }

  void _validateAmount() {
    setState(() {
      // Trigger the custom formatter to handle validation
      final formatter = CustomTextInputFormatter(
        _calculateRemainingBalance(),
            (String? error) {
          setState(() {
            _errorMessage = error;
          });
        },
      );
      formatter.formatEditUpdate(
        _amountController.value,
        TextEditingValue(text: _amountController.text),
      );
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.removeListener(_validateAmount);
    super.dispose();
  }

  // Method to set wallet balance
  void setWalletBalance(double balance) {
    setState(() {
      walletBalance = balance.toDouble(); // Convert integer to double
    });
  }

  // Function to fetch wallet balance
  void fetchWallet() async {
    int? userId = widget.userId;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/FetchWalletBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("dataaaa $data");
        if (data['data'] != null) {
          setState(() {
            walletBalance = data['data'].toDouble(); // Set wallet balance
            isLoading = false; // Data is loaded
          });
        } else {
          print('Error: balance field is null');
        }
      } else {
        throw Exception('Failed to load wallet balance');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  // Function to set transaction details
  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
    });
  }

  // Function to fetch transaction details
  void fetchTransactionDetails() async {
    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/getTransactionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> transactionData = data['value'];
          List<Map<String, dynamic>> transactions = transactionData.map((transaction) {
            return {
              'status': transaction['status'],
              'amount': transaction['amount'],
              'time': transaction['time'],
            };
          }).toList();
          setTransactionDetails(transactions);
        } else {
          print('Error: transaction details format is incorrect');
        }
      } else {
        throw Exception('Failed to load transaction details');
      }
    } catch (error) {
      print('Error fetching transaction details: $error');
    }
  }

  void handlePayment(double amount) async {
    String? username = widget.username;
    const String currency = 'INR';
    int? user_Id= widget.userId;

    setState(() {
      showAlertLoading = true; // Show loading overlay
    });

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/createOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'currency': currency , 'userId' : user_Id }),
      );
      await Future.delayed(const Duration(seconds: 2));
        var data = json.decode(response.body);
        print("dataa: $data");

        print("WalletResponse: $data");
      // Check if the response is successful
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("dataa: $data");
        ////LIVE
        // Map<String, dynamic> options = {
        //   'key': 'rzp_live_TFodb8l3ihW2nM',
        //   'amount': data['amount'],
        //   'currency': data['currency'],
        //   'name': 'EV Power',
        //   'description': 'Wallet Recharge',
        //   'order_id': data['id'],
        //   'prefill': {'name': username},
        //   'theme': {'color': '#3399cc'},
        // };
        
        //TEST
        Map<String, dynamic> options = {
          'key': 'rzp_test_dcep4q6wzcVYmr',
          'amount': data['amount'],
          'currency': data['currency'],
          'name': 'Anish kumar A',
          'description': 'Wallet Recharge',
          'order_id': data['id'],
          'prefill': {'name': username},
          'theme': {'color': '#3399cc'},
        };
        _lastPaymentAmount = amount; // Store the amount

        // Open the Razorpay payment gateway
        _razorpay.open(options);
      }else {
        // Handle non-200 responses here
        final errorData = json.decode(response.body);
        final errorDatas =  errorData['message'];
         print("WalletResponse ododod 2: $errorDatas");

        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      print('Error during payment: $error');
    } finally {
      setState(() {
        showAlertLoading = false; // Hide loading overlay after payment process
      });
    }
  }

  void showErrorDialog(BuildContext context, String message) {
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
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    String? username = widget.username;

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      Map<String, dynamic> result = {
        'user': username,
        'RechargeAmt': _lastPaymentAmount, // Use the stored amount
        'transactionId': response.orderId,
        'responseCode': 'SUCCESS',
        'date_time': DateTime.now().toString(),
      };

      var output = await http.post(
        Uri.parse('http://122.166.210.142:4444/wallet/savePayments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(result),
      );

      var responseData = json.decode(output.body);
      if (responseData == 1) {
        print('Payment successful!');
        _showPaymentSuccessModal(result);

        setState(() {
          fetchWallet(); // Fetch wallet balance after successful payment
          fetchTransactionDetails(); // Fetch transaction details after successful payment
        });
      } else {
        print('Payment details not saved!');
      }
    } catch (error) {
      print('Error saving payment details: $error');
    } finally {
      setState(() {
        isLoading = false; // End loading
      });
    }
  }

void _showAlertBanner(String message) {
  setState(() {
    _alertMessage = message; // Set the alert message
  });

  // Clear the alert message after 3 seconds
  Future.delayed(const Duration(seconds: 3), () {
    setState(() {
      _alertMessage = null; // Clear the alert message
    });
  });
}
  void _handlePaymentError(PaymentFailureResponse response) {
    String? username = widget.username;
    Map<String, dynamic> paymentError = {
      'user': username,
      'RechargeAmt': _lastPaymentAmount, // Use the stored amount
      'message': response.message,
      'date_time': DateTime.now().toString(),
    };

    setState(() {
      isLoading = true; // Start loading
    });

    // Simulate a delay or asynchronous operation if needed
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isLoading = false; // End loading
      });
      _showPaymentFailureModal(paymentError);
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  void _showPaymentSuccessModal(Map<String, dynamic> paymentResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: isLoading
              ? _buildShimmer() // Show shimmer effect while loading
              : PaymentSuccessModal(paymentResult: paymentResult),
        );
      },
    );
  }

  Widget _buildShimmer() {
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
          Shimmer.fromColors(
            baseColor: Colors.grey.shade700,
            highlightColor: Colors.grey.shade500,
            child: Container(
              height: 48,
              width: double.infinity,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade700,
            highlightColor: Colors.grey.shade500,
            child: Container(
              height: 48,
              width: double.infinity,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade700,
            highlightColor: Colors.grey.shade500,
            child: Container(
              height: 48,
              width: double.infinity,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailureModal(Map<String, dynamic> paymentError) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: isLoading
              ? _buildShimmer() // Show shimmer effect while loading
              : PaymentFailureModal(paymentError: paymentError),
        );
      },
    );
  }

  double _calculateProgress() {
    const double maxLimit = 10000.0; // Updated max limit
    if (walletBalance != null && walletBalance! > 0) {
      return walletBalance! / maxLimit;
    }
    return 0.0;
  }

  String _getBalanceLevel() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return 'Low';
    } else if (progress < 0.66) {
      return 'Medium';
    } else {
      return 'Full';
    }
  }

  Color _getBalanceColor() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return Colors.red;
    } else if (progress < 0.66) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const HelpModal(),
        );
      },
    );
  }

  double _calculateRemainingBalance() {
    const double maxLimit = 10000.0; // Maximum wallet balance
    if (walletBalance != null) {
      return maxLimit - walletBalance!; // Remaining balance that can be added
    }
    return maxLimit;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: showAlertLoading,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showHelpModal,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Wallet',
                style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fast, one-click payments\nSeamless charging',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              isLoading
                  ? Shimmer.fromColors(
                baseColor: Colors.grey[700]!,
                highlightColor: Colors.grey[500]!,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 18, width: 100, color: Colors.white),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(height: 32, width: 150, color: Colors.white),
                          const Spacer(),
                          Container(height: 20, width: 50, color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 14, width: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      Container(height: 8, color: Colors.white),
                    ],
                  ),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${walletBalance?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontSize: 32, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBalanceColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getBalanceLevel(),
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Max ₹10,000',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    // Conditional error message
                    if (walletBalance != null && walletBalance! < 100)
                      const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 18), // Error icon
                          SizedBox(width: 8), // Space between icon and text
                          Text(
                            'Maintain min balance of ₹100 for optimal charging.',
                            style: TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: walletBalance != null ? _calculateProgress() : 0,
                      color: Colors.orange,
                      backgroundColor: Colors.white12,
                    ),
                  ],
                ),
              ),
      
              const SizedBox(height: 24),
              const Text(
                'Add money',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter amount',
                              hintStyle: const TextStyle(color: Colors.white54),
                              errorText: _errorMessage,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: <TextInputFormatter>[
                              CustomTextInputFormatter(
                                _calculateRemainingBalance(),
                                    (String? error) {
                                  setState(() {
                                    _errorMessage = error;
                                  });
                                },
                              ),
                            ],
                          ),
      
      
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _amountController.clear();
                          },
                        ),
                      ],
                    ),
                    if (_alertMessage != null)
                      AlertBanner(message: _alertMessage!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _amountController.text = '100';
                    },
                    child: const Text('₹ 100', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _amountController.text = '500';
                    },
                    child: const Text('₹ 500', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _amountController.text = '1000';
                    },
                    child: const Text('₹ 1000', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  double remainingBalance = _calculateRemainingBalance(); // Calculate remaining balance
                  _amountController.text = remainingBalance.toStringAsFixed(2); // Set the text to the remaining balance
                },
                child: const Text('Maximum', style: TextStyle(color: Colors.white)),
              ),
      
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: walletBalance != null && walletBalance! >= 10000
                    ? null
                    : () {
                  double amount = double.tryParse(_amountController.text) ?? 0.0;
                  double totalBalance = (walletBalance ?? 0.0) + amount;
                  double remainingBalance = 10000 - (walletBalance ?? 0.0);
      
                  if (amount <= 0 || totalBalance > 10000) {
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
                                  Icon(Icons.error_outline, color: Colors.red, size: 25),
                                  SizedBox(width: 10),
                                  Text(
                                    "Error",
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              CustomGradientDivider(), // Custom gradient divider
                            ],
                          ),
                          content: Text(
                            _amountController.text.isEmpty
                                ? 'Your field is empty !! Kindly enter an valid amount.' // Message for empty input
                                : 'The total balance after adding this amount exceeds the maximum limit of ₹10,000. You can only add up to ₹${remainingBalance.toStringAsFixed(2)}.',
                            style: const TextStyle(color: Colors.white70), // Adjusted text color for contrast
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: const Text("OK", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    handlePayment(amount); // Proceed with payment
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: walletBalance != null && walletBalance! >= 10000
                      ? Colors.transparent
                      : const Color(0xFF1C8B39), // Dark green when enabled
                  minimumSize: const Size(double.infinity, 50), // Full width button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.green.withOpacity(0.2); // Light green gradient when disabled
                      }
                      return walletBalance != null && walletBalance! >= 10000
                          ? Colors.grey // Grey when the button is disabled
                          : const Color(0xFF1C8B39); // Dark green color when enabled
                    },
                  ),
                ),
                child: Text(
                  walletBalance != null && walletBalance! >= 10000
                      ? 'Limit Reached'
                      : 'Add ₹${_amountController.text}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: walletBalance != null && walletBalance! >= 10000
                        ? Colors.grey // Text color when disabled
                        : Colors.white, // Text color when enabled
                  ),
                ),
              ),
      
      
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }


}

class PaymentSuccessModal extends StatelessWidget {
  final Map<String, dynamic> paymentResult;

  const PaymentSuccessModal({super.key, required this.paymentResult});

  @override
  Widget build(BuildContext context) {
    // Check if the data is available
    bool isDataLoaded = paymentResult.isNotEmpty; // You might need to adjust this based on your actual condition

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
                'Payment Success',
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

          // Shimmer effect for the content
          if (!isDataLoaded) ...[
            _buildShimmer(),
          ] else ...[
            Center(
              child: Text(
                '₹${(paymentResult['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 8),
                Text(
                  'Completed',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Payment should now be in ${paymentResult['user'] ?? ''}'s wallet ",
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              Icons.account_circle,
              paymentResult['user'] ?? '',
              DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(paymentResult['date_time'] ?? DateTime.now().toString())),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              Icons.receipt_long,
              'Transaction ID',
              '${paymentResult['transactionId'] ?? ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade700,
          highlightColor: Colors.grey.shade500,
          child: Container(
            height: 48,
            width: double.infinity,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800, // Background color for the ListTile
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade600,
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
    );
  }

}

class PaymentFailureModal extends StatelessWidget {
  final Map<String, dynamic> paymentError;

  const PaymentFailureModal({Key? key, required this.paymentError}) : super(key: key);

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
                'Payment Failure',
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
          Center(
            child: Text(
              '₹${(paymentError['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text(
                'Failed',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Transaction failed unexpectedly',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.account_circle, color: Colors.white, size: 40),
              ),
              title: Text(
                paymentError['user'] ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(paymentError['date_time'] ?? DateTime.now().toString())),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 40),
              ),
              title: const Text(
                'Transaction ID',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                '${paymentError['transactionId'] ?? ' - '}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpModal extends StatelessWidget {
  const HelpModal({Key? key}) : super(key: key);

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
                'Wallet Help',
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
          const Text(
            'How to use the Wallet',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Add Money: Use the "Add Money" section to recharge your wallet. Enter the amount and click "Add ₹".\n'
            '2. Balance: View your current wallet balance and its level (Low, Medium, Full).\n'
            '3. Transaction History: Check your recent transactions and their status (Credited, Debited).\n'
            '4. Payment Methods: Use Razorpay for secure and quick transactions.\n'
            '5. Max Limit: The wallet has a maximum limit of ₹10,000.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Text(
            'Need More Help?',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'For further assistance, contact our support team at support@outdidtech.com.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}


class LimitRangeTextInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  LimitRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;
    // Remove any commas
    newText = newText.replaceAll(',', '');

    // Check if the input is a valid double
    double? newValueAsDouble = double.tryParse(newText);

    if (newValueAsDouble == null) {
      // Return oldValue if the new value is not a valid double
      return oldValue;
    }

    // Check if the new value is within the specified range
    if (newValueAsDouble < min || newValueAsDouble > max) {
      return oldValue;
    }

    // Return the new value if it's within the range
    return newValue.copyWith(text: newText);
  }
}


class CustomTextInputFormatter extends TextInputFormatter {
  final double remainingBalance;
  final void Function(String?) onValidationError;

  CustomTextInputFormatter(this.remainingBalance, this.onValidationError);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text;

    // Allow empty input
    if (newText.isEmpty) {
      onValidationError(null);
      return newValue;
    }

    // Allow only valid input with up to two decimal places
    final RegExp regex = RegExp(r'^\d*\.?\d{0,2}$');
    if (!regex.hasMatch(newText)) {
      return oldValue; // Revert to old value if the input is invalid
    }

    // Parse the new value as double
    double? newValueDouble = double.tryParse(newText);

    // If new value exceeds the remaining balance, show error and revert to old value
    if (newValueDouble != null && newValueDouble > remainingBalance) {
      onValidationError("Enter a value up to ₹${remainingBalance.toStringAsFixed(2)}.Total Limit is \n₹10,000.");
      return oldValue;
    } else {
      // Clear error if valid
      onValidationError(null);
    }

    return newValue; // Return the new value if all validations pass
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

class ErrorDetails extends StatelessWidget {
  final String? errorData;
  final String username;
  final int? userId;
  final String email;
  final Map<String, dynamic>? selectedLocation; // Accept the selected location

  const ErrorDetails(
      {Key? key,
      required this.errorData,
      required this.username,
      this.userId,
      required this.email,
      this.selectedLocation})
      : super(key: key);

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
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Error Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  // Use Navigator.push to add the new page without disrupting other content
                  Navigator.pop(context);
                  // Close the QR code scanner page and return to the Home Page
                },
              ),
            ],
          ),
          const SizedBox(
              height: 10), // Add spacing between the header and the green line
          CustomGradientDivider(),
          const SizedBox(
              height: 20), // Add spacing between the green line and the icon
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 70,
          ),
          const SizedBox(height: 20),
          Text(
            errorData ?? 'An unknown error occurred.',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
