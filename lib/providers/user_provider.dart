import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  // Set the user when logged in
  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  // Clear user when logged out
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
