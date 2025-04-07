import 'package:flutter/material.dart';
import 'package:walletway/user_authentication/signup.dart'; // Import your SignUpPage

class WelcomePage extends StatelessWidget {
  static const String routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to WalletWay'),
        backgroundColor: const Color(0xFFE39C6F),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Header Title
            const Text(
              "Welcome to WalletWay",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE39C6F),
              ),
            ),
            const SizedBox(height: 20),

            // Introduction Text
            const Text(
              "Your personal guide to smarter financial management. Our app is designed to simplify the way you handle money, offering tools to track expenses, create budgets, and make informed financial decisions with ease.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20),

            // Features Section
            const Text(
              "Features include:",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Bullet Points
            const Text(
              "• Plan budgets tailored to your goals\n"
                  "• Track spending effortlessly through SMS or manual inputs\n"
                  "• Gain insights through visual charts and graphs\n"
                  "• Manage shared costs with our bill-splitting feature\n"
                  "• Handle foreign currencies with multi-currency conversion\n"
                  "• Receive personalized investment recommendations",
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20),

            // Motivation Section
            const Text(
              "Whether you're saving for the future or tracking day-to-day expenses, WalletWay provides clear guidance to help you take control of your financial journey.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20),

            // Conclusion Text
            const Text(
              "Your financial freedom starts here—step into a better way to manage your money with WalletWay!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Get Started Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, SignUpPage.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE39C6F),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
