import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserImageProvider with ChangeNotifier {
  File? _userImage;

  File? get userImage => _userImage;

  Future<void> setImage(File image) async {
    _userImage = image;
    await _saveImagePath(image.path);
    notifyListeners();
  }

  Future<void> loadImage() async {
    String? imagePath = await _getImagePath();
    if (imagePath != null) {
      _userImage = File(imagePath);
    }
    notifyListeners();
  }

  Future<void> _saveImagePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_image_path', path);
  }

  Future<String?> _getImagePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_image_path');
  }
}
