import 'package:flutter/material.dart';
import 'package:walletway/sms_based_entry.dart';
import 'app_drawer.dart';
import 'manual_entry.dart'; // Import the reusable AppDrawer widget

class ExpenseEntryPage extends StatelessWidget {
  const ExpenseEntryPage({super.key});
  static const String routeName = '/expense_entry';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Expense Entry"),
        centerTitle: true,
      ),
      drawer: AppDrawer(), // Add the navigation drawer
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0), // Adjusted padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Move content up by aligning to the top
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons horizontally
          children: [
            // Header Text
            const Text(
              "Choose Entry Method",
              textAlign: TextAlign.center, // Center-align the text
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40), // Increased spacing below the header
            // Manual Entry Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE39C6F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Navigate to the Manual Entry Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManualEntryPage(),
                  ),
                );
              },
              child: const Text(
                "Manual Entry",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 20), // Spacing between the buttons
            // SMS-Based Entry Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE39C6F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Navigate to the SMS-Based Entry Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SmsEntryPage(),
                  ),
                );
              },
              child: const Text(
                "SMS-Based Entry",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
