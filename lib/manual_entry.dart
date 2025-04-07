import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'app_drawer.dart';

class ManualEntryPage extends StatefulWidget {
  const ManualEntryPage({Key? key}) : super(key: key);

  @override
  _ManualEntryPageState createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  String? _selectedCategory = 'Food';
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'General',
    'Education',
    'Medical',
    'Entertainment',
    'Bills & Utilities',
    'Groceries',
    'Rent',
    'Salary',
    'Investment',
    'Travel',
    'Subscriptions',
    'Gifts & Donations',
    'Taxes',
    'Insurance',
    'Fitness',
    'Pets',
    'Loan Repayment',
  ];

  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Function to save the expense
  Future<void> _saveExpense() async {
    try {
      // Validate input
      if (_amountController.text.isEmpty ||
          double.tryParse(_amountController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Fetch the username
      String username = await _getUsername(user.email);
      username = username.isNotEmpty
          ? username
          : (user.displayName ?? user.email ?? 'Unknown');

      // Format date and time
      String formattedDate =
          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
      String formattedTime =
          "${_selectedDate.hour}:${_selectedDate.minute}:${_selectedDate.second}";

      // Expense data to save
      Map<String, dynamic> expenseData = {
        'username': username,
        'email': user.email,
        'date': formattedDate,
        'time': formattedTime,
        'category': _selectedCategory,
        'amount': double.parse(_amountController.text),
        'userID': user.uid,
      };

      // Check if the expense already exists
      bool expenseExists = await _checkExpenseExists(expenseData);
      if (expenseExists) {
        // Show confirmation dialog
        bool addToDatabase = await _showConfirmationDialog();
        if (addToDatabase) {
          // Save the expense and update the total
          await _saveExpenseData(expenseData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense Added to Database and Total Updated!')),
          );
        }
      } else {
        // Save expense normally if it doesn't exist
        await _saveExpenseData(expenseData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense Saved Successfully!')),
        );
      }

      // Clear the input fields
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: $e')),
      );
    }
  }

  // Function to check if the expense already exists in the database
  Future<bool> _checkExpenseExists(Map<String, dynamic> expenseData) async {
    String userId = expenseData['userID'];
    String category = expenseData['category'];
    double amount = expenseData['amount'];
    String formattedDate = expenseData['date'];

    try {
      QuerySnapshot existingExpenses = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userID', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('date', isEqualTo: formattedDate)
          .where('amount', isEqualTo: amount)
          .get();

      return existingExpenses.docs.isNotEmpty;
    } catch (e) {
      print("Error checking if expense exists: $e");
      return false;
    }
  }

  // Show dialog to confirm if the user wants to add the expense to the database
  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Expense Already Exists'),
          content: const Text('Do you want to add this expense to the database and update the total?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Function to get username from Firestore
  Future<String> _getUsername(String? email) async {
    if (email == null) return '';

    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first['username'] ?? '';
      }
    } catch (e) {
      print("Error fetching username by email: $e");
    }
    return '';
  }

  // Function to save expense data in Firestore
  Future<void> _saveExpenseData(Map<String, dynamic> expenseData) async {
    String userId = expenseData['userID'];
    String category = expenseData['category'];

    // Save to global "expenses" collection
    await FirebaseFirestore.instance.collection('expenses').add(expenseData);

    // Save to user-specific category subcollection
    DocumentReference categoryRef =
    FirebaseFirestore.instance.collection(userId).doc(category);
    DocumentSnapshot categorySnapshot = await categoryRef.get();

    double currentTotal = categorySnapshot.exists
        ? (categorySnapshot.data() as Map<String, dynamic>)['total'] ?? 0.0
        : 0.0;

    await categoryRef.set({
      'total': currentTotal + expenseData['amount'],
      'expenses': FieldValue.arrayUnion([expenseData]),
    }, SetOptions(merge: true));

    // Update the global total across all categories
    DocumentReference globalTotalRef =
    FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot globalTotalSnapshot = await globalTotalRef.get();

    double globalTotal = globalTotalSnapshot.exists
        ? (globalTotalSnapshot.data() as Map<String, dynamic>)['total'] ?? 0.0
        : 0.0;

    await globalTotalRef.set({
      'total': globalTotal + expenseData['amount'],
    }, SetOptions(merge: true));
  }

  // Function to select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Manual Entry"),
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter Expense Details",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Amount",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Select Category",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              DropdownButton<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                isExpanded: true,
              ),
              const SizedBox(height: 30),
              const Text(
                "Select Date",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.black),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Center(
                child: SizedBox(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE39C6F),
                    ),
                    onPressed: _saveExpense,
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
