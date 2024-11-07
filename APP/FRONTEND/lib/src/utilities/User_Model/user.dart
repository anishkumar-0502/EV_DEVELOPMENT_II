import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  String? username;
  int? userId;
  String? email;

  UserData({this.username, this.userId, this.email});

  void updateUserData(String username, int userId , String email) {
    this.username = username;
    this.userId = userId;
    this.email = email;
    notifyListeners();
  }

  void clearUser() {
    username = null;
    userId = null;
    email = null;
    notifyListeners();
  }
}
