import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../app_drawer.dart';

class AnalysisPage extends StatefulWidget {
  static const String routeName = '/Analysis-Page';

  const AnalysisPage({Key? key}) : super(key: key);

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  Map<String, double> categoryTotals = {};
  bool isLoading = true;
  String selectedCategory = "";
  bool isLabelVisible = false;
  Color selectedCategoryColor = Colors.transparent;
  Offset selectedCategoryPosition = const Offset(100, 100);
  int currentGraphIndex = 0;

  final List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.brown,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.grey,
  ];


  final List<String> graphTitles = ["Pie Chart", "Bar Chart", "Stacked Bar Chart","Line Chart"];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userID', isEqualTo: currentUser.uid)
          .get();

      final Map<String, double> totalsByCategory = {};

      for (final doc in snapshot.docs) {
        final amount = (doc['amount'] ?? 0).toDouble();
        final category = (doc['category'] ?? 'General') as String;

        totalsByCategory[category] =
            (totalsByCategory[category] ?? 0) + amount;
      }

      setState(() {
        categoryTotals = totalsByCategory;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching expenses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Analysis"),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryTotals.isEmpty
          ? const Center(
        child: Text(
          "No expenses found",
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Navigation Arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: currentGraphIndex > 0
                      ? () {
                    setState(() {
                      currentGraphIndex--;
                    });
                  }
                      : null,
                ),
                Text(
                  graphTitles[currentGraphIndex],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentGraphIndex < graphTitles.length - 1
                      ? () {
                    setState(() {
                      currentGraphIndex++;
                    });
                  }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Graphs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _buildCurrentGraph(),
              ),
            ),
            const SizedBox(height: 20),
            // Category Breakdown
            const Text(
              "Category Breakdown",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: categoryTotals.entries.map((entry) {
                  final index =
                  categoryTotals.keys.toList().indexOf(entry.key);
                  final color =
                  chartColors[index % chartColors.length];
                  final percentage = ((entry.value /
                      categoryTotals.values.reduce(
                              (a, b) => a + b)) *
                      100)
                      .toStringAsFixed(1);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color,
                        child: Icon(
                          _getIconForCategory(entry.key),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(entry.key),
                      subtitle: Text("$percentage% of total expenses"),
                      trailing: Text(
                        "₹${entry.value.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFFE39C6F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLineChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50, // Increase space to move graph right
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(left: 8), // Slight right shift
                child: Text(
                  "₹${value.toInt()}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Remove right labels
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  DateFormat('dd/MM').format(
                    DateTime.now().subtract(Duration(days: 6 - value.toInt())),
                  ),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.black, width: 2), // Keep left border
            bottom: BorderSide(color: Colors.black, width: 2), // Keep bottom border
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: generateLineChartSpots(), // Data points
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }



  List<FlSpot> generateLineChartSpots() {
    final today = DateTime.now();
    final Map<String, double> dailyExpenses = {};

    // Initialize last 7 days with 0 expense
    for (int i = 0; i < 7; i++) {
      final date = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i)));
      dailyExpenses[date] = 0;
    }

    // Fetch data from Firestore correctly
    for (final entry in categoryTotals.entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: categoryTotals.keys.toList().indexOf(entry.key))));
      if (dailyExpenses.containsKey(dateKey)) {
        dailyExpenses[dateKey] = (dailyExpenses[dateKey] ?? 0) + entry.value;
      }
    }

    // Convert to FlSpot (index as x-axis, total expense as y-axis)
    List<FlSpot> spots = [];
    int index = 0;
    dailyExpenses.entries.toList().reversed.forEach((entry) {
      spots.add(FlSpot(index.toDouble(), entry.value));
      index++;
    });

    return spots;
  }


  Widget _buildCurrentGraph() {
    return Stack(
      children: [
        if (currentGraphIndex == 0) // Pie Chart
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: _generatePieChartSections(),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                    final index = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    final category = categoryTotals.keys.toList()[index];
                    final color = chartColors[index % chartColors.length];

                    setState(() {
                      selectedCategory = category;
                      selectedCategoryColor = color;
                      selectedCategoryPosition = _adjustLabelPosition(event.localPosition);
                      isLabelVisible = true;
                    });

                    _hideLabelAfterDelay();
                  }
                },
              ),
            ),
          )

        else if (currentGraphIndex == 1) // Bar Chart
          BarChart(
            BarChartData(
              barGroups: _generateBarChartGroups(),
              barTouchData: BarTouchData(
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
                    final index = barTouchResponse!.spot!.touchedBarGroupIndex;
                    final category = categoryTotals.keys.toList()[index];
                    final color = chartColors[index % chartColors.length];

                    setState(() {
                      selectedCategory = category;
                      selectedCategoryColor = color;
                      selectedCategoryPosition = _adjustLabelPosition(event.localPosition);
                      isLabelVisible = true;
                    });

                    _hideLabelAfterDelay();
                  }
                },
              ),
            ),
          )

        else if (currentGraphIndex == 2) // Stacked Bar Chart
            BarChart(
              BarChartData(
                barGroups: _generateStackedBarChartGroups(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        "₹${value.toInt()}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final categories = categoryTotals.keys.toList();
                        return Text(
                          categories[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
              ),
            )

          else if (currentGraphIndex == 3) // Line Chart (New)
              LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            DateFormat('dd/MM').format(
                              DateTime.now().subtract(Duration(days: 6 - value.toInt())),
                            ),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 22,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: generateLineChartSpots(), // Data points
                      isCurved: true, // Smooth curve
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true), // Show dots on points
                    ),
                  ],
                ),
              ),

        // Animated Floating Label
        Positioned(
          left: selectedCategoryPosition.dx,
          top: selectedCategoryPosition.dy,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isLabelVisible ? 1.0 : 0.0,
            child: isLabelVisible
                ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedCategoryColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: selectedCategoryColor.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                "$selectedCategory\n₹${categoryTotals[selectedCategory]!.toStringAsFixed(2)}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                : const SizedBox(),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _generateStackedBarChartGroups() {
    final List<BarChartGroupData> barGroups = [];
    int index = 0;

    for (final entry in categoryTotals.entries) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value, // Total amount spent in this category
              color: chartColors[index % chartColors.length], // Assign color
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      index++;
    }

    return barGroups;
  }


  Offset _adjustLabelPosition(Offset position) {
    double dx = position.dx - 30; // Offset to avoid overlapping the touch
    double dy = position.dy - 40; // Move slightly above the tap

    // Prevent label from going off-screen
    dx = dx.clamp(10, MediaQuery.of(context).size.width - 100);
    dy = dy.clamp(10, MediaQuery.of(context).size.height - 50);

    return Offset(dx, dy);
  }


  void _hideLabelAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLabelVisible = false;
        });
      }
    });
  }




  List<PieChartSectionData> _generatePieChartSections() {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (final entry in categoryTotals.entries) {
      sections.add(PieChartSectionData(
        color: chartColors[colorIndex % chartColors.length],
        value: entry.value,
        title:
        '${((entry.value / categoryTotals.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
      colorIndex++;
    }

    return sections;
  }

  List<BarChartGroupData> _generateBarChartGroups() {
    return categoryTotals.entries
        .map(
          (entry) => BarChartGroupData(
        x: categoryTotals.keys.toList().indexOf(entry.key),
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: chartColors[
            categoryTotals.keys.toList().indexOf(entry.key) %
                chartColors.length],
          ),
        ],
      ),
    )
        .toList();
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
}
