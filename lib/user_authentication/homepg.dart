import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../app_drawer.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home_page';
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isWeekView = true;
  double totalAmount = 0.0;
  Map<String, double> categoryTotals = {};
  Map<String, List<Map<String, dynamic>>> categoryDetails = {};
  Set<String> expandedCategories = {};

  // Variables to hold daily and monthly expense data
  List<double> amounts = List<double>.generate(12, (index) => 0.0); // Default to monthly view
  List<double> goals = List<double>.generate(12, (index) => 0.0);  // Store expense goals

  double weeklyGoal = 0.0;  // Weekly goal amount

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    AwesomeNotifications().initialize(
      'resource://drawable/res_app_icon',
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic Notifications',
          channelDescription: 'Channel for basic notifications',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
    );

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _showDeleteDialog(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Expense"),
          content: const Text("Are you sure you want to delete this expense?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('expenses')
                      .doc(expenseId)
                      .delete();
                  Navigator.of(context).pop();
                  _fetchExpenses(); // Update expenses after deletion
                } catch (e) {
                  print("Error deleting expense: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchExpenses() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      final goalSnapshot = await FirebaseFirestore.instance
          .collection('expenses_goal')
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      double total = 0.0;
      Map<String, double> totalsByCategory = {};
      Map<String, List<Map<String, dynamic>>> detailsByCategory = {};
      List<double> weeklyAmounts = List<double>.filled(7, 0.0);
      List<double> monthlyAmounts = List<double>.filled(12, 0.0);
      List<double> monthlyGoals = List<double>.filled(12, 0.0);
      double fetchedWeeklyGoal = 0.0;

      // ✅ Debug: Print goal documents
      debugPrint("✅ Fetching Goals from Firestore...");
      for (final doc in goalSnapshot.docs) {
        debugPrint("📝 Goal Doc: ${doc.data()}");
        final goalAmount = (doc['limit'] ?? 0).toDouble();
        final month = (doc['month'] ?? 0) as int;
        final isWeeklyGoal = doc['isWeeklyGoal'] ?? false;

        if (isWeeklyGoal) {
          fetchedWeeklyGoal = goalAmount;
        }

        if (month >= 1 && month <= 12) {
          monthlyGoals[month - 1] = goalAmount;
        }
      }

      weeklyGoal = fetchedWeeklyGoal;
      debugPrint("✅ Updated Weekly Goal: $weeklyGoal");
      debugPrint("✅ Updated Monthly Goals: $monthlyGoals");

      for (final doc in expenseSnapshot.docs) {
        final amount = (doc['amount'] ?? 0).toDouble();
        final category = (doc['category'] ?? 'General') as String;
        final dateStr = doc['date'] as String?;
        final id = doc.id;

        total += amount;
        totalsByCategory[category] = (totalsByCategory[category] ?? 0) + amount;
        detailsByCategory.putIfAbsent(category, () => []).add({
          'id': id,
          'amount': amount,
          'date': dateStr ?? 'Unknown',
        });

        if (dateStr != null) {
          try {
            DateTime expenseDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            if (isWeekView) {
              int dayOfWeek = expenseDate.weekday % 7;
              weeklyAmounts[dayOfWeek] += amount;
            } else {
              int month = expenseDate.month - 1;
              monthlyAmounts[month] += amount;
            }
          } catch (e) {
            debugPrint("⚠️ Error parsing date: $dateStr");
          }
        }
      }

      setState(() {
        totalAmount = total;
        categoryTotals = totalsByCategory;
        categoryDetails = detailsByCategory;
        amounts = isWeekView ? weeklyAmounts : monthlyAmounts;
        goals = isWeekView ? List<double>.filled(7, weeklyGoal / 7) : monthlyGoals;
      });

      _showNotification("Expenses Loaded", "Your expenses have been successfully loaded.");
    } catch (e) {
      debugPrint("❌ Error fetching expenses: $e");
      _showNotification("Error", "Failed to load expenses. Please try again.");
    }
  }



  String _formatDate(dynamic date) {
    if (date is String) {
      return date;
    }
    return 'Unknown';
  }

  void _showNotification(String title, String message) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: message,
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> expense) {
    final TextEditingController amountController =
    TextEditingController(text: expense['amount'].toString());
    final TextEditingController categoryController =
    TextEditingController(text: expense['category']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                try {
                  final updatedAmount = double.tryParse(amountController.text) ?? 0.0;
                  final updatedCategory = categoryController.text;

                  await FirebaseFirestore.instance
                      .collection('expenses')
                      .doc(expense['id'])
                      .update({
                    'amount': updatedAmount,
                    'category': updatedCategory,
                  });

                  Navigator.of(context).pop();
                  _fetchExpenses(); // Refresh the data after editing
                } catch (e) {
                  print("Error updating expense: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(String category) {
    final isExpanded = expandedCategories.contains(category);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(
            _getIconForCategory(category),
            color: Colors.white,
          ),
          backgroundColor: const Color(0xFFE39C6F),
        ),
        title: Text(category),
        subtitle: Text(
          "₹${categoryTotals[category]?.toStringAsFixed(2) ?? '0.00'}",
        ),
        children: (categoryDetails[category] ?? []).map((expense) {
          return ListTile(
            leading: Text(
              expense['date'],
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹${expense['amount']?.toStringAsFixed(2) ?? '0.00'}",
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: () => _showEditDialog(context, expense),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, expense['id']),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Education':
        return Icons.school;
      case 'Medical':
        return Icons.medical_services;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Rent':
        return Icons.home;
      case 'Salary':
        return Icons.attach_money;
      case 'Investment':
        return Icons.trending_up;
      case 'Travel':
        return Icons.flight;
      case 'Subscriptions':
        return Icons.subscriptions;
      case 'Gifts & Donations':
        return Icons.card_giftcard;
      case 'Taxes':
        return Icons.account_balance;
      case 'Insurance':
        return Icons.security;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Pets':
        return Icons.pets;
      case 'Loan Repayment':
        return Icons.money_off;
      default:
        return Icons.category;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: const Color(0xFFE39C6F),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildToggleButton("Week", isWeekView),
                _buildToggleButton("Month", !isWeekView),
              ],
            ),
            const SizedBox(height: 20),
            _buildGraph(),
            const SizedBox(height: 20),
            Text(
              "Total Amount: ₹${totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: categoryTotals.keys
                    .map((category) => _buildCategoryItem(category))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive) {
    return TextButton(
      onPressed: () {
        setState(() {
          isWeekView = label == "Week";
          amounts = List<double>.filled(isWeekView ? 7 : 12, 0.0);
          goals = List<double>.filled(isWeekView ? 7 : 12, 0.0);
          _fetchExpenses(); // ✅ Ensure correct data is fetched
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFE39C6F) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFFE39C6F),
        ),
      ),
    );
  }



  Widget _buildGraph() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: isWeekView ? _buildWeekBarGraph() : _buildMonthBarGraph(),
    );
  }

  Widget _buildMonthBarGraph() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: amounts.asMap().entries.map((entry) {
          return _makeBarData(entry.key, entry.value, goals[entry.key]);
        }).toList(),
        titlesData: _getTitles(months),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.5,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            for (int i = 0; i < goals.length; i++)
              if (goals[i] > 0) // Only add goal lines if they exist
                HorizontalLine(
                  y: goals[i],
                  color: Colors.blue,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                ),
          ],
        ),
      ),
    );
  }





  Widget _buildWeekBarGraph() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    double dailyGoal = weeklyGoal / 7;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: amounts.asMap().entries.map((entry) {
          return _makeBarData(entry.key, entry.value, dailyGoal);
        }).toList(),
        titlesData: _getTitles(days),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 0.5,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (weeklyGoal > 0) // Show weekly goal line only if set
              HorizontalLine(
                y: dailyGoal,
                color: Colors.blue,
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
          ],
        ),
      ),
    );
  }










  BarChartGroupData _makeBarData(int x, double y, double goal) {
    Color barColor = (goal > 0 && y > goal) ? Colors.red : Colors.green;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 15,
          color: barColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }








  FlTitlesData _getTitles(List<String> labels) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            final intValue = value.toInt();
            return (intValue >= 0 && intValue < labels.length)
                ? Text(labels[intValue], style: TextStyle(fontSize: 10))
                : SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              "₹${value.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 10), // Reduced font size here
            ),
          ),
        ),
      ),
    );
  }
}

