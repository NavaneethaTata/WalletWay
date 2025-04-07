import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; // For utf8.encode

import 'package:walletway/user_authentication/login_page.dart';
import 'app_drawer.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  static const String routeName = '/profile';

  const ProfilePage({super.key, required this.username});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _currentUsername; // Holds the current username
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  // Fetch username from Firestore
  Future<void> _fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _currentUsername = userDoc['username'] ?? 'Guest';
      });
    }
  }

  // Update username in Firestore
  Future<void> _updateUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'username': _nameController.text});

        setState(() {
          _currentUsername = _nameController.text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $error')),
        );
      }
    }
  }

  // Check current password and update it
  Future<void> _checkCurrentPasswordAndUpdatePassword() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // If password is correct, show dialog for new password
      _showNewPasswordDialog();
    } catch (error) {
      // Current password doesn't match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current password does not match')),
      );
    }
  }

  // Encrypt password using SHA-256
  String _encryptPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Update new password in Firestore
  Future<void> _updatePassword(String newPassword) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      // Update Firebase Auth password
      await user.updatePassword(newPassword);

      // Encrypt new password and update Firestore
      String encryptedPassword = _encryptPassword(newPassword);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'password': encryptedPassword});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Profile"),
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFFE39C6F),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _currentUsername ?? 'Loading...',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFFE39C6F)),
                title: const Text("Change Name",
                    style: TextStyle(color: Colors.black)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16),
                onTap: () {
                  _showChangeNameDialog(context);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.lock, color: Color(0xFFE39C6F)),
                title: const Text("Change Password",
                    style: TextStyle(color: Colors.black)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16),
                onTap: () {
                  _showCurrentPasswordDialog(context);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Color(0xFFE39C6F)),
                title: const Text("Logout",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white70, size: 16),
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog to change name
  void _showChangeNameDialog(BuildContext context) {
    _nameController.text = _currentUsername ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Change Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Enter new username"),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE39C6F)),
                  onPressed: () {
                    _updateUsername();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

// Dialog to verify current password
  void _showCurrentPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Verify Current Password"),
          content: TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Enter current password"),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE39C6F)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkCurrentPasswordAndUpdatePassword();
                  },
                  child: const Text("Next", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

// Dialog to set a new password
  void _showNewPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Set New Password"),
          content: TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Enter new password (min. 6 characters)"),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE39C6F)),
                  onPressed: () {
                    _updatePassword(_newPasswordController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

// Logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("No"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE39C6F)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logout(context);
                  },
                  child: const Text("Yes", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut().then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error logging out: $error"),
      ));
    });
  }
}
