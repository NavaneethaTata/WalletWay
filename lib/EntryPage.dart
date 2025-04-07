import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'app_drawer.dart';

class ExpenseGoalsPage extends StatefulWidget {
  final String title;
  static const String routeName = '/goal';
  const ExpenseGoalsPage({Key? key, required this.title}) : super(key: key);

  @override
  _ExpenseGoalsPageState createState() => _ExpenseGoalsPageState();
}

class _ExpenseGoalsPageState extends State<ExpenseGoalsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _limitController = TextEditingController();
  List<Map<String, dynamic>> _expenseGoals = [];
  double _totalExpenses = 0.0; // Stores total expenses from Firebase

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _fetchTotalExpenses(); // Fetch total expenses
    _fetchExpenseGoals();
  }

  /// **Initialize Notifications**
  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      'resource://drawable/ww', // Your notification icon path
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Notification channel for basic alerts',
          importance: NotificationImportance.High,
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
        ),
      ],
    );

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  /// **Fetch Total Expenses from Firebase**
  Future<void> _fetchTotalExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _totalExpenses = (userDoc.data()?['total'] ?? 0).toDouble();
        });
        _checkExpensesAndNotify();
      }
    } catch (e) {
      print("Error fetching total expenses: $e");
    }
  }

  /// **Fetch Expense Goals**
  Future<void> _fetchExpenseGoals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expense_goals')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _expenseGoals = goalsSnapshot.docs
            .map((doc) => {"id": doc.id, ...doc.data()} as Map<String, dynamic>)
            .toList();
      });

      _checkExpensesAndNotify();
    } catch (e) {
      print("Error fetching goals: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching goals.")),
      );
    }
  }

  /// **Save Expense Goal**
  Future<void> _saveExpenseGoal() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String limitText = _limitController.text.trim();

    if (limitText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a limit.")),
      );
      return;
    }

    try {
      double limit = double.parse(limitText);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expense_goals')
          .add({
        "category": "Total Expenses",
        "limit": limit,
        "goalType": "Total",
        "createdAt": FieldValue.serverTimestamp(),
      });

      _limitController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal saved successfully!")),
      );

      _fetchExpenseGoals();
    } catch (e) {
      print("Error saving goal: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error saving goal.")),
      );
    }
  }

  /// **Check Expenses and Notify if Exceeded**
  Future<void> _checkExpensesAndNotify() async {
    if (_expenseGoals.isNotEmpty) {
      double expenseLimit = _expenseGoals.first["limit"];

      print("Checking notifications: Total = ₹$_totalExpenses, Limit = ₹$expenseLimit");

      if (_totalExpenses > expenseLimit) {
        _sendExpenseNotification(_totalExpenses, expenseLimit);
      }
    }
  }

  /// **Send Expense Notification**
  void _sendExpenseNotification(double totalExpenses, double limit) {
    print("Sending notification: Total = ₹$totalExpenses, Limit = ₹$limit");

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: 'Expense Limit Exceeded! 🚨',
        body: 'Your total expenses (₹$totalExpenses) have exceeded your goal limit (₹$limit).',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  /// **Delete Expense Goal**
  Future<void> _deleteGoal(String goalId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expense_goals')
          .doc(goalId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal deleted successfully!")),
      );

      _fetchExpenseGoals();
    } catch (e) {
      print("Error deleting goal: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting goal.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFFE39C6F),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Total Expense Goal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Monthly Limit (₹)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpenseGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE39C6F),
                ),
                child: const Text("Save Goal"),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Total Expenses: ₹$_totalExpenses",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _expenseGoals.length,
                itemBuilder: (context, index) {
                  final goal = _expenseGoals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: const Text(
                        "Goals",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Limit: ₹${goal["limit"]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGoal(goal["id"]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
