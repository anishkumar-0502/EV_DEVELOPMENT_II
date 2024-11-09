import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Log_In/login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailInteracted = false;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    // Add listener to the email controller
    _emailController.addListener(() {
      setState(() {}); // Trigger a rebuild to update button state
    });
  }

  void _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSearching = true;
      });


      final String email = _emailController.text;

      try {
        final response = await http.post(
          Uri.parse('http://122.166.210.142:9098/profile/initiateForgetPassword'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'email_id': email}),
        );
        final data = json.decode(response.body);
        print(data);
        if (response.statusCode == 200) {
          await Future.delayed(const Duration(seconds: 3));
          showOtpModal(email);
        } else {
          setState(() {
            isSearching = true;
          });
          await Future.delayed(const Duration(seconds: 3));
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
                          "Error",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomGradientDivider(), // Custom gradient divider
                  ],
                ),
                content: const Text(
                  'Failed to send OTP. Please check your credentials!',
                  style: TextStyle(color: Colors.white70),
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
      } catch (e) {
        setState(() {
          isSearching = false;
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
                'An error occurred: $e',
                style: const TextStyle(color: Colors.white70),
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
      } finally {
        setState(() {
          isSearching = false; // Always stop the loading indicator
        });
      }
    }
  }


  void showOtpModal(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black, // Set modal background color to black
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          color: Colors.black, // Ensure the inner container also has a black background
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: OTPInputWidget(
              email: email,
              onSubmit: (otp) {
                // Handle OTP submission here
                print('OTP entered: $otp');
                Navigator.pop(context); // Close the modal
              },
            ),
          ),
        );
      },
    );
  }


  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: isSearching,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    "Forgot your Password? \nLet’s Fix That!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your email to initiate the password recovery process.",
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
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: const Color(0xFF1ED760),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9@.]')),
                    ],
                    validator: (value) {
                      if (!_isEmailInteracted) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!_validateEmail(value)) {
                        return 'Enter a valid email address';
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
                  ElevatedButton(
                    onPressed: _validateEmail(_emailController.text) ? _sendResetLink : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _validateEmail(_emailController.text)
                          ? const Color(0xFF1C8B39)
                          : Colors.transparent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.green.withOpacity(0.2);
                          }
                          return const Color(0xFF1C8B40);
                        },
                      ),
                    ),
                    child: Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _validateEmail(_emailController.text)
                            ? Colors.white
                            : Colors.green[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




class OTPInputWidget extends StatefulWidget {
  final Function(String) onSubmit;
  final String email;

  const OTPInputWidget({Key? key, required this.email, required this.onSubmit})
      : super(key: key);

  @override
  _OTPInputWidgetState createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isInteracted = false;
  bool isSearching = false;
  bool _canResendOTP = true;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  bool _isFormValid() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _submitOTP() async {
    if (_formKey.currentState!.validate()) {
      String otp = _controllers.map((controller) => controller.text).join('');
      await _authenticateOTP(widget.email, otp);
    }
  }

  Future<void> _authenticateOTP(String email, String otp) async {
    print('heloooooo');
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/authenticateOTP'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email_id': email, 'otp': otp}),
      );
      print('hiiiii');
      final data = json.decode(response.body);
      print(data);
      if (response.statusCode == 200) {
        resetPassword(email);
      } else {
        _showErrorDialog('Failed to verify OTP. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void resetPassword(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          color: Colors.black,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: ResetPasswordWidget(
              email: email,
              onSubmit: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 35),
              SizedBox(width: 10),
              Text(
                "Error",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendResetLink() async {
    if (!_canResendOTP) return; // Don't send if still in countdown

    setState(() {
      isSearching = true;
      _canResendOTP = false;
      _startResendCountdown(); // Start countdown when resend OTP is triggered
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/initiateForgetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email_id': widget.email}),
      );

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 3));
      } else {
        await Future.delayed(const Duration(seconds: 3));
        _showErrorDialog('Failed to send OTP. Please check your credentials!');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _startResendCountdown() {
    _remainingSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _canResendOTP = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      showAlertLoading: isSearching,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        color: Colors.black,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              CustomGradientDivider(),
              const SizedBox(height: 20),
              
              Expanded(child: SingleChildScrollView(
                child: Column(children: [
                  _buildInstructions(),
                  const SizedBox(height: 20),
                  _buildOTPFields(),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                  _buildResendOTPLink(),
                ],),
              ))

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Enter OTP",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        const Text(
          "Just one step away!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Please enter the OTP sent to your registered \nemail id: ${widget.email}',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[800],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              counterText: '',
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            cursorColor: Colors.green,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
              setState(() {});
            },
            validator: (value) {
              if (!_isInteracted) return null;
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            },
            onTap: () {
              setState(() {
                _isInteracted = true;
              });
            },
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isFormValid() ? _submitOTP : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFormValid() ? const Color(0xFF1C8B39) : Colors
            .transparent,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ).copyWith(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.green.withOpacity(0.2);
            }
            return const Color(0xFF1C8B40);
          },
        ),
      ),
      child: Text(
        'Submit OTP',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _isFormValid() ? Colors.white : Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildResendOTPLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _canResendOTP ? _sendResetLink : null,
          child: Text(
            _canResendOTP
                ? 'Resend OTP'
                : 'Resend OTP [${_remainingSeconds}s]',
            style: TextStyle(
              color: _canResendOTP ? Colors.green : Colors.grey,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}



class ResetPasswordWidget extends StatefulWidget {
  final String email;
  final VoidCallback onSubmit;

  const ResetPasswordWidget({Key? key, required this.email, required this.onSubmit}) : super(key: key);

  @override
  _ResetPasswordWidgetState createState() => _ResetPasswordWidgetState();
}

class _ResetPasswordWidgetState extends State<ResetPasswordWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _newPasswordFocusNode = FocusNode(); // FocusNode for the new password field

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isFormValid = false;
  bool isSearching = true;

  void _close() {
    Navigator.of(context).pop(); // Close the modal
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);

    // Automatically focus on the new password field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_newPasswordFocusNode);
    });
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _newPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _newPasswordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> newPassword(String email, String newPassword) async {
    try {
      setState(() {
        isSearching = true; // Start loading
      });

      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/resetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email_id': email, 'NewPassword': newPassword}), // Send new password
      );

      final data = json.decode(response.body);
      print(data);

      if (response.statusCode == 200) {
        // Show success dialog and navigate after 3 seconds
        _showSuccessDialog();
        await Future.delayed(const Duration(seconds: 3)); // Show dialog for 3 seconds
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        ); // Navigate to the login page
      } else {
        // Handle error response
        _showErrorDialog('Failed to update password. Please try again.');
      }
    } catch (e) {
      // Handle exceptions
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() {
        isSearching = false; // Stop loading
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 25),
                  const SizedBox(width: 10),
                  const Text(
                    "Success",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(),
            ],
          ),
          content: const Text(
            "New password successfully updated.",
            style: TextStyle(color: Colors.white70),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
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
                    "Error",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomGradientDivider(),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Enter New Password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: _close,
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomGradientDivider(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Unlock a New You!!",style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),),
                        SizedBox(height: 10,),
                        Text(
                          'Reset Password for ${widget.email}',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        // New password field
                        TextFormField(
                          controller: _newPasswordController,
                          focusNode: _newPasswordFocusNode, // Attach FocusNode to the new password field
                          obscureText: !_isPasswordVisible,
                          keyboardType: TextInputType.number, // Allow only numbers
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Restrict to digits only
                          ],
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[900], // Green background for the text box
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green), // Default border color
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green, width: 2.0), // Green border when focused
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green), // Green border when enabled
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            counterText: '', // Remove character counter
                          ),
                          cursorColor: Colors.green, // Green cursor color
                          style: const TextStyle(color: Colors.white), // Text color remains white
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new password';
                            }
                            return null; // No need to check length as it's already restricted
                          },
                        ),

                        const SizedBox(height: 20),
                        // Confirm password field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          keyboardType: TextInputType.number, // Allow only numbers
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // Restrict to digits only
                          ],
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green), ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green, width: 2.0), // Green border when focused
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.green), // Green border when enabled
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            counterText: '', // Remove character counter
                          ),
                          cursorColor: Colors.green,
                          style: const TextStyle(color: Colors.white),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Submit button
                        ElevatedButton(
                          onPressed: _isFormValid
                              ? () {
                            if (_formKey.currentState!.validate()) {
                              newPassword(widget.email, _newPasswordController.text); // Call newPassword function
                            }
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                if (!states.contains(MaterialState.disabled)) {
                                  return Colors.blue; // Enabled background color
                                }
                                return Colors.grey[700]; // Disabled background color
                              },
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
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