// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../utilities/User_Model/user.dart';
import '../../home.dart';
import '../Sign_Up/register.dart';
import '../../../utilities/Alert/alert_banner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Forgot_password/forgot_password.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late Connectivity _connectivity;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isDialogOpen = false; // Track if the dialog is open


  final _formKey = GlobalKey<FormState>();

  bool _isEmailInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;
  bool isSearching = false;


  String? storedUser;
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_emailListener);
    _passwordController.addListener(_updateButtonState);
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
    _retrieveUserData();
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
    _emailController.removeListener(_emailListener);
    _passwordController.removeListener(_updateButtonState);
    _emailController.dispose();
    _passwordController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _retrieveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedUser = prefs.getString('user');
    });
  }

  void _emailListener() {
    String text = _emailController.text;
    int index = text.indexOf('.com');

    if (index != -1 && text.length > index + 4) {
      // If the length exceeds '.com', truncate any characters after '.com'
      _emailController.text = text.substring(0, index + 4);
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );
    }
    _updateButtonState();
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }

  bool _isFormValid() {
    final form = _formKey.currentState;
    return form?.validate() ?? false;
  }
  Future<void> _login() async {
    if (isSearching) return;
    String email = _emailController.text;
    String password = _passwordController.text;

    setState(() {
      isSearching = true;
    });

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/CheckLoginCredentials'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email_id': email, 'password': password}),
      );

      // Delay to keep the loading indicator visible
      await Future.delayed(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String username = responseData['data']['username'];
        int userId = responseData['data']['user_id'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', username);
        await prefs.setInt('userId', userId);
        await prefs.setString('email', email);

        Provider.of<UserData>(context, listen: false)
            .updateUserData(username, userId, email);


        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              username: username,
              userId: userId,
              email: email,
            ),
          ),
        );
      } else {
        setState(() {
          isSearching = false;
        });
        final data = json.decode(response.body);
        _showErrorDialog(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      _showErrorDialog('Internal server error');
    }
  }

  void _showErrorDialog(String message) {
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
                    "Login Error",
                    style: TextStyle(color: Colors.white, fontSize: 18),
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
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }


  void _updateButtonState() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: isSearching, // Pass the isLoading state
      child: storedUser != null
          ? HomePage(
        username: storedUser!,
        email: '',
      )
          : Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 50), // Margin at the top
                  const Text(
                    'Welcome Back! Sign In to dive in?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your email and password to continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(200, 58, 58, 60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: const Color(0xFF1ED760),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9@.]')), // Allows only lowercase letters, numbers, @, and .
                    ],

                    validator: (value) {
                      if (!_isEmailInteracted) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!_validateEmail(value)) {
                        return 'Enter a valid email address ending with .com';
                      }
                      return null;
                    },
                    onTap: () {
                      setState(() {
                        _isEmailInteracted = true;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(200, 58, 58, 60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    cursorColor: const Color(0xFF1ED760),
                    validator: (value) {
                      if (!_isPasswordInteracted) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length != 4) {
                        return 'Password must be exactly 4 digits';
                      }
                      return null;
                    },
                    onTap: () {
                      setState(() {
                        _isPasswordInteracted = true;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isFormValid() ? _login : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid()
                          ? const Color(0xFF1C8B39)
                          : Colors.transparent, // Dark green when enabled
                      minimumSize: const Size(double.infinity, 50), // Full width button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.green.withOpacity(0.2); // Light green gradient
                          }
                          return const Color(0xFF1C8B40); // Dark green color
                        },
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isFormValid()
                            ? Colors.white
                            : Colors.green[700], // Text color
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "New User? Sign Up",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Extra margin at the bottom
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _alertMessage != null
            ? AlertBanner(
          message: _alertMessage!,
        )
            : null,
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