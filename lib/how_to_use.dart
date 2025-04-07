import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:walletway/user_authentication/homepg.dart';
import 'package:walletway/AnalysisPage.dart';
import 'package:walletway/EntryPage.dart';
import 'package:walletway/profile.dart';
import 'package:walletway/Multic.dart';
import 'package:walletway/billsplit.dart';
import 'package:walletway/settings.dart';
import 'package:walletway/stock.dart' as stock;
import 'package:walletway/expense_entry.dart';

class HowToUsePage extends StatelessWidget {
  static const String routeName = '/how-to-use';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use WalletWay'),
        backgroundColor: const Color(0xFFE39C6F),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Welcome to WalletWay! Here's a simple guide to help you make the most of the app and manage your finances effortlessly.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "1. Track Your Spending",
              description: "Easily track your expenses by enabling SMS-based tracking or manually entering transactions. View your spending categorized into various sections like food, entertainment, and more.",
              onPressed: () {
                Navigator.pushNamed(context, ExpenseEntryPage.routeName);
              },
              buttonText: "Go to Expense Tracking",
              icon: Icons.track_changes,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "2. Create and Manage Budgets",
              description: "Set Total or Category-Wise budgets based on your goals. Monitor your progress and adjust your spending to stay within your budget.",
              onPressed: () {
                Navigator.pushNamed(context, AnalysisPage.routeName);
              },
              buttonText: "Go to Budget Planning",
              icon: Icons.pie_chart,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "3. Set and Track Savings Goals",
              description: "Create savings goals and track your progress over time. Set targets and get notified to stay on track with your financial plans.",
              onPressed: () {
                Navigator.pushNamed(context, ExpenseGoalsPage.routeName);
              },
              buttonText: "Go to Savings Goals",
              icon: Icons.savings,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "4. Split Bills Easily",
              description: "Easily divide shared expenses with family or friends. Our bill-splitting feature ensures everyone contributes fairly.",
              onPressed: () {
                Navigator.pushNamed(context, BillSplitPage.routeName);
              },
              buttonText: "Go to Bill Splitting",
              icon: Icons.money_off,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "5. Get Stock Market Recommendation",
              description: "Stay ahead in investments with personalized stock market recommendation powered by machine learning. Make informed decisions to grow your savings.",
              onPressed: () {
                Navigator.pushNamed(context, stock.StockRecommendationPage.routeName);
              },
              buttonText: "Go to Stock Market Predictions",
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "6. Convert Currencies with Ease",
              description: "Traveling or managing finances in foreign currencies? Use the multi-currency converter to handle conversions effortlessly.",
              onPressed: () {
                Navigator.pushNamed(context, CurrencyConverterPage.routeName);
              },
              buttonText: "Go to Currency Converter",
              icon: Icons.currency_exchange,
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: "7. Get Financial Insights",
              description: "Track your spending patterns, see visual reports, and get personalized recommendations to make better financial decisions.",
              onPressed: () {
                Navigator.pushReplacementNamed(context, HomePage.routeName);
              },
              buttonText: "Return to Home",
              icon: Icons.dashboard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required VoidCallback onPressed,
    required String buttonText,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFE39C6F)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 14.0),
        ),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            width: 250,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE39C6F)),
              child: Text(buttonText, style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
