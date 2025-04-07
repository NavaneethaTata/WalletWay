import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:walletway/forgot_password.dart';
import 'homepg.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('web/bgw.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "WalletWay",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE39C6F),
                  fontFamily: 'Cookie',
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(_usernameController, "Username/Email"),
              const SizedBox(height: 20),
              _buildTextField(_passwordController, "Password", obscureText: _obscureText, isPassword: true),
              const SizedBox(height: 30),
              _buildLoginButton(),
              const SizedBox(height: 10),
              _buildForgotPasswordButton(), // Moved below "Let's Go" button and centered
              const SizedBox(height: 20),
              _buildSignUpLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
          ).then((_) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
          });
        },
        child: const Text(
          "Forgot Password?",
          style: TextStyle(color: Color(0xFFE39C6F), fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE39C6F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Let's Go", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage())),
      child: const Text(
        "Don't have an account? Sign Up",
        style: TextStyle(color: Color(0xFFE39C6F), fontSize: 16, decoration: TextDecoration.underline),
      ),
    );
  }

  void _login() async {
    String usernameOrEmail = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both username/email and password");
      return;
    }

    try {
      bool isEmail = usernameOrEmail.contains('@');
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(isEmail ? 'email' : 'username', isEqualTo: usernameOrEmail)
          .get();

      if (userSnapshot.docs.isEmpty) {
        _showSnackBar("User not found. Please sign up.");
        return;
      }

      var userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
      String email = userData['email'];

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'user-disabled':
          errorMessage = "This user account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Try again later.";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
          break;
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar("An unexpected error occurred. Please try again.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
