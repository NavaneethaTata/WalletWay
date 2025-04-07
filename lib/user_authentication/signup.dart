import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:walletway/user_authentication/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:crypto/crypto.dart'; // Import crypto package for hashing
import 'dart:convert'; // Import for utf8.encode
import 'package:awesome_notifications/awesome_notifications.dart'; // Import Awesome Notifications
import 'homepg.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  static const String routeName = '/signup';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Password visibility toggle

  @override
  void initState() {
    super.initState();

    // Initialize Awesome Notifications and check permission on sign-up page
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image with Overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('web/bgw.jpg'), // Ensure correct path
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            // Sign-up Form (Centered on screen)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE39C6F),
                        fontFamily: 'Cookie',
                      ),
                    ),
                    SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      decoration: _buildInputDecoration("Username"),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration("Email"),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _buildPasswordInputDecoration("Password"),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE39C6F),
                        ),
                        child: Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                    // Navigate to LoginPage on tapping "Already have an account?"
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        "Already have an account? Log In",
                        style: TextStyle(color: Color(0xFFE39C6F), fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Regular Input Field Styling
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Password Input Field with Visibility Toggle
  InputDecoration _buildPasswordInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
    );
  }

  // Updated sign-up function with email validation
  void _signUp() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String username = _usernameController.text.trim();

    // Validate email format
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email address.")),
      );
      return;
    }

    try {
      // Create user in Firebase Authentication
      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        // Hash the password before saving it
        String hashedPassword = _hashPassword(password);

        // Save the user data (including userID) to Firestore
        await _saveUserDataToDatabase(user.uid, username, email, hashedPassword);

        // Send sign-up notification
        _showSignUpNotification();

        // Navigate to HomePage after sign-up and data storage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-up failed. Please try again.")),
        );
      }
    } catch (e) {
      print("Error during sign-up: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign-up failed. Please try again.")),
      );
    }
  }

  // Function to validate email format
  bool _isValidEmail(String email) {
    String pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  // Function to hash the password using SHA256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Get the SHA256 hash
    return digest.toString(); // Return the hashed password as a string
  }

  // Function to save user data to Firestore with a unique userID
  Future<void> _saveUserDataToDatabase(
      String userId, String username, String email, String hashedPassword) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'password': hashedPassword, // Store the hashed password
        'uid': userId,  // Add the userID
      });
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Function to display sign-up success notification
  void _showSignUpNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: 'Sign Up Successful',
        body: 'Welcome to WalletWay! You have successfully signed up.',
      ),
    );
  }
}
