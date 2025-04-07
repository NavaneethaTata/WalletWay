import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walletway/user_authentication/login_page.dart';
import 'package:walletway/user_authentication/homepg.dart' as authHome; // Updated prefix for homepg.dart
import 'package:walletway/profile.dart'; // Updated to no alias
import 'package:walletway/AnalysisPage.dart';
import 'package:walletway/EntryPage.dart';
import 'package:walletway/Multic.dart';
import 'package:walletway/billsplit.dart';
import 'package:walletway/settings.dart';
import 'package:walletway/stock.dart';
import 'package:walletway/expense_entry.dart';
import 'package:walletway/calci.dart'; // Importing Calculator Page

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Simplified and smaller header
          Container(
            height: 100,
            color: const Color(0xFFE39C6F), // Orange background color
            padding: const EdgeInsets.only(left: 16, top: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              'WalletWay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main Drawer Items
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Home',
            route: const authHome.HomePage(), // Using the HomePage from homepg.dart
          ),
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Analysis',
            route: const AnalysisPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.flag,
            title: 'Goal',
            route: const ExpenseGoalsPage(title: 'Expense Goals'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.monetization_on,
            title: 'Expense Entry',
            route: const ExpenseEntryPage(),
          ),
          _buildProfileItem(context), // Your profile item with Firestore username fetching
          _buildDrawerItem(
            context,
            icon: Icons.currency_exchange,
            title: 'Currency Converter',
            route: const CurrencyConverterPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Bill Splitter',
            route: BillSplitPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            route: const SettingsPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart,
            title: 'Stock',
            route: StockRecommendationPage(),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calculate,
            title: 'Calculator',
            route: CalculatorScreen(),
          ),

          // Logout Item (Conditional)
          if (user != null)
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              route: null, // No page redirection for logout
              onTap: () => _showLogoutConfirmationDialog(context),
            ),
        ],
      ),
    );
  }

  // Reusable Drawer Item Builder
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Widget? route,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap ?? () {
        if (route != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => route),
          );
        }
      },
    );
  }

  // Profile Item with Firestore username fetching
  Widget _buildProfileItem(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return ListTile(
      leading: const Icon(Icons.person),
      title: const Text('Profile'),
      onTap: () async {
        if (user != null) {
          // Fetch the username from Firestore (assuming it's stored under "users" collection)
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)  // Using the user ID to fetch their data
              .get();

          String username = userDoc['username'] ?? 'Guest';  // Assuming the field name is 'username'

          // Navigate to ProfilePage with the fetched username
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                username: username,
              ),
            ),
          );
        }
      },
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}