import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class Footer extends StatefulWidget {
  final Function(int) onTabChanged;

  const Footer({required this.onTabChanged, super.key});

  @override
  FooterState createState() => FooterState();
}

class FooterState extends State<Footer> with SingleTickerProviderStateMixin {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _currentIndex = 0;
  late AnimationController _animationController;
  final List<int> _navigationStack = [0];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward(); // Start the animation immediately
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Adjust this value to move the footer higher
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        child: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _currentIndex,
          // height: 42.8,
          height: 50.8,
          items: List<Widget>.generate(4, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [_getColor(index), Colors.black],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: Icon(
                    _getIconData(index),
                    size: 45,
                    color: Colors.white, // Keep the icon color white for ShaderMask to apply gradient
                  ),
                );
              },
            );
          }),
          color: Colors.black,
          buttonBackgroundColor:const Color(0xFF1E1E1E),
          backgroundColor: Colors.black,
          // color: const Color.fromARGB(0, 11, 97, 14),
          // buttonBackgroundColor: Colors.black,
          // backgroundColor: const Color.fromARGB(30, 76, 175, 79),
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 500),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _animationController.forward(from: 0.0);
              if (_navigationStack.isEmpty || _navigationStack.last != index) {
                _navigationStack.add(index);
              }
            });
            widget.onTabChanged(index);
          },
        ),
      ),
    );
  }

  IconData _getIconData(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.wallet_outlined;
      case 2:
        return Icons.history;
      case 3:
        return Icons.account_circle;
      default:
        return Icons.home;
    }
  }

  Color _getColor(int index) {
    return _currentIndex == index
        ? ColorTween(
            begin: Colors.black,
            end: const Color.fromARGB(255, 104, 251, 109),
          ).evaluate(_animationController)!
        : const Color.fromARGB(255, 79, 192, 83);
  }

  bool handleBackPress() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
        _currentIndex = _navigationStack.last;
        _bottomNavigationKey.currentState?.setPage(_currentIndex);
      });
      widget.onTabChanged(_currentIndex);
      return false;
    }
    return true;
  }
}
