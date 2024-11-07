import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../Auth/Log_In/login.dart';
import 'package:ev_app/src/utilities/User_Model/user.dart';
import 'Help/help.dart'; // Import your HelpPage
import 'Edit_User/edituser.dart'; // Import your EditUserModal
import '../../utilities/User_Model/ImageProvider.dart'; // Import the UserImageProvider
import 'Terms_&_Condition/tc.dart'; // Import your TermsPage
import 'Privacy_&_Policy/pp.dart'; // Import your PrivacyPolicyPage
import 'Account/Account.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final int? userId;
  final String? email;

  const ProfilePage({super.key, required this.username, this.userId,this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? email;
  int? phoneNo;
  String? password;
  int _selectedTileIndex = -1; // Index of the selected tile
  final String _version = '1.0.7'; // Default value, in case fetching fails

  @override
  void initState() {
    super.initState();
    // fetchUserDetails();
    email = widget.email;
    final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
    userImageProvider.loadImage(); // Load user image when the profile page is initialized

  }


  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Provider.of<UserData>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  void _showEditUserModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          child:  EditUserModal(
            username: widget.username,
            email: email ?? '',

            userId: widget.userId,

          ),
        );
      },
    ).then((result) {
      //   // Check if result is 'refresh' to trigger data fetch
      if (result == 'refresh') {
        // fetchUserDetails();
        final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
        userImageProvider.loadImage(); // Reload user image when the modal is closed
      }
    });
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: const HelpPage(), // Ensure this is the correct widget name
          ),
        );
      },
    );
  }

  void _showAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.97, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: AccountPage(username: widget.username,userId: widget.userId,email:widget.email), // Ensure this is the correct widget name
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userImageProvider = Provider.of<UserImageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              ClipPath(
                clipper: CustomClipPath(),
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade800.withOpacity(0), Colors.black],
                      begin: Alignment.topRight,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userImageProvider.userImage != null
                            ? FileImage(userImageProvider.userImage!)
                            : const AssetImage('assets/Image/avatar.png') as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.username,
                        style: const TextStyle(fontSize: 23, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email ?? '',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20,width: 20,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 200, // Increase the width of the container
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 0,

                              ),
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.lightGreenAccent.withOpacity(0.3), // Light green color with some transparency
                                  Colors.lightGreen.withOpacity(0.6)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _showEditUserModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent, // Keep the button background transparent
                                foregroundColor: Colors.white, // Text and icon color white
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Adjust padding for a larger button
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(180, 50), // Ensure the button has the desired size
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 16, color: Colors.white), // White icon color
                                  SizedBox(width: 8),
                                  Text('Edit profile', style: TextStyle(color: Colors.white, fontSize: 14)), // White text color
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Container(

                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 0;
                              });
                              _showAccountModal();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: const ListTile(
                                title: Text('Account', style: TextStyle(color: Colors.white)),
                                leading: Icon(Icons.account_circle, color: Colors.white),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 1;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  TermsPage(), // Ensure this is the correct widget name
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 1
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: const ListTile(
                                title: Text('Terms and Conditions', style: TextStyle(color: Colors.white)),
                                leading: Icon(Icons.description, color: Colors.white),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 2;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  PrivacyPolicyPage(), // Ensure this is the correct widget name
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 2
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: const ListTile(
                                title: Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                                leading: Icon(Icons.policy, color: Colors.white),
                                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10,height: 30,),
                          SizedBox(
                            width: 300,
                            child:CustomGradientDivider (),
                          ),
                          const SizedBox(height: 5,),
                          GestureDetector(
                            onTap: () {
                              _logout(); // Correctly invoking the _logout function
                            },
                            child: Container(
                              // You can uncomment and use the decoration if needed
                              // decoration: BoxDecoration(
                              //   border: Border.all(
                              //     width: 2,
                              //   ),
                              //   borderRadius: BorderRadius.circular(20),
                              //   gradient: LinearGradient(
                              //     colors: [
                              //       Colors.redAccent.withOpacity(0.3), // Light red color with some transparency
                              //       Colors.red.withOpacity(0.6),
                              //     ],
                              //     begin: Alignment.topLeft,
                              //     end: Alignment.bottomRight,
                              //   ),
                              // ),
                              child: ListTile(
                                title: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 20), // Add some space between the icon and the text
                                    Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: _logout,
                                hoverColor: Colors.red.withOpacity(0.1), // Light change when hovered or tapped
                                splashColor: Colors.redAccent.withOpacity(0.2), // Splash effect on tap
                              ),
                            ),
                          ),
                          const SizedBox(height: 100,),
                          Container(
                            margin:const EdgeInsets.only(bottom: 50,top: 50) ,

                            child: Column(
                              children: [
                                  Text(
                                  'Version: alpha $_version ',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                    children: [
                                      TextSpan(text: 'Copyright © 2024 '),
                                      TextSpan(
                                        text: 'EV Power',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                      TextSpan(text: '. All rights reserved.'),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          )


                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned (
            top: 61,
            right: 12,
            child: GestureDetector(
              onTap: _showHelpModal ,
              child: const Icon(Icons.help_outline, color: Colors.white, ),
            ),
          ),


        ],
      ),
    );
  }
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
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