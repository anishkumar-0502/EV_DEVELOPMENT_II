import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import '../Log_In/login.dart';
import '../../../utilities/Alert/alert_banner.dart'; // Import the alert banner
import 'package:connectivity_plus/connectivity_plus.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  bool _isUsernameInteracted = false;
  bool _isEmailInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;
  String? _alertMessage;
  bool _isLoading = false;
  String? successMsg;
  late Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isDialogOpen = false;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateAndUpdate);
    _emailController.addListener(_validateAndUpdate);
    _phoneController.addListener(_validateAndUpdate);
    _passwordController.addListener(_validateAndUpdate);
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    var result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
      _dismissConnectionDialog();
    } else if (result == ConnectivityResult.none) {
      if (!_isDialogOpen) {
        _showNoConnectionDialog(result);
      }
    }
  }

  void _showNoConnectionDialog(ConnectivityResult result) {
    String message = result == ConnectivityResult.none
        ? 'No Internet Connection. Please check your connection.'
        : 'Mobile data is off. Please turn it on or connect to Wi-Fi.';

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
      Navigator.of(context, rootNavigator: true).pop();
      _isDialogOpen = false;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _validateAndUpdate() {
    final emailValue = _emailController.text;
    if (emailValue.contains('.com')) {
      final index = emailValue.indexOf('.com');
      if (index + 4 < emailValue.length) {
        _emailController.text = emailValue.substring(0, index + 4);
        _emailController.selection = TextSelection.fromPosition(
            TextPosition(offset: _emailController.text.length));
      }
    }

    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }


  bool _validateUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return usernameRegex.hasMatch(value);
  }

  void _handleRegister() async {
    if (isSearching) return;
    final String username = _usernameController.text;
    final String email = _emailController.text;
    final String phone = _phoneController.text;
    final String password = _passwordController.text;

     setState(() {
      isSearching = true;
    });


    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:4444/profile/RegisterNewUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email_id': email,
          'phone_no': phone,
          'password': password,
        }),
      );

       await Future.delayed(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _showAlertBannerSuccess("User successfully registered");
        await Future.delayed(const Duration(seconds: 3));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          isSearching = false;
        });
        final data = json.decode(response.body);
        _showAlertBanner(data['message']);
      }
    } catch (e) {
      setState(() {
          isSearching = false;
        });
      print('register $e');
      _showAlertBanner('Internal server error');
    }
  }

  void _showAlertBanner(String message) {
    setState(() {
      _alertMessage = message;
       isSearching = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _alertMessage = null;
      });
    });
  }

  void _showAlertBannerSuccess(String message) async {
    setState(() {
      successMsg = message;
       isSearching = false;
    });
   
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        successMsg = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: isSearching, 
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Column(
          children: [
            if (_alertMessage != null) AlertBanner(message: _alertMessage!),
            if (successMsg != null) SuccessBanner(message: successMsg!),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Create your Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Fill in the details below to get started.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildUsernameField(),
                      const SizedBox(height: 20),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      _buildPhoneField(),
                      const SizedBox(height: 20),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: Text(
                            'Already a user? Sign In ?',
                            style: TextStyle(fontSize: 15, color: Colors.green[700]),
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
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(200, 58, 58, 60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        hintText: 'Username',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF1ED760),
      validator: (value) {
        if (!_isUsernameInteracted) return null;
        if (value == null || value.isEmpty) return 'Enter your username';
        if (!_validateUsername(value)) return 'Username must be alphabets & numbers only';
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isUsernameInteracted = true;
        });
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
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
      cursorColor: const Color(0xFF1ED760),
      keyboardType: TextInputType.emailAddress,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9@.]')), // Allows only lowercase letters, numbers, @, and .
      ],
      validator: (value) {
        if (!_isEmailInteracted) return null;
        if (value == null || value.isEmpty) {
          return 'Please enter email';
        }
        if (!_validateEmail(value)) {
          return 'Enter a valid Gmail address ending with .com';
        }
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isEmailInteracted = true;
        });
      },
    );
  }


  Widget _buildPhoneField() {
    return IntlPhoneField(
      controller: _phoneController,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromARGB(200, 58, 58, 60),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        hintText: 'Phone Number',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF1ED760),
      initialCountryCode: 'IN',
      validator: (value) {
        if (value == null || value.number.isEmpty) return 'Enter your phone number';
        return null;
      },
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly, // Allows only numbers
      ],
      onChanged: (value) => _validateAndUpdate(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
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
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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
      cursorColor: const Color(0xFF1ED760),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
      validator: (value) {
        if (!_isPasswordInteracted) return null;
        if (value == null || value.isEmpty) return 'Enter your password';
        if (value.length != 4) return 'Password must be exactly 4 digits long';
        return null;
      },
      onChanged: (value) => _validateAndUpdate(),
      onTap: () {
        setState(() {
          _isPasswordInteracted = true;
        });
      },
    );
  }


  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isButtonEnabled ? _handleRegister : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isButtonEnabled ? const Color(0xFF1C8B39) : Colors.transparent, // Dark green when enabled
        minimumSize: const Size(double.infinity, 50), // Set the width to be full width
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: _isButtonEnabled ? Colors.transparent : Colors.transparent, // No border color when disabled
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
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
        'Continue',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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