import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_drawer.dart';

class BillSplitPage extends StatefulWidget {
  static const String routeName = '/bill';
  @override
  _BillSplitPageState createState() => _BillSplitPageState();
}

class _BillSplitPageState extends State<BillSplitPage> {
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _numberOfPeopleController = TextEditingController();
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _amountControllers = [];
  String _resultMessage = "";

  void _generateFields() {
    final int? numberOfPeople = int.tryParse(_numberOfPeopleController.text);
    if (numberOfPeople != null && numberOfPeople > 0) {
      setState(() {
        _nameControllers = List.generate(numberOfPeople, (_) => TextEditingController());
        _amountControllers = List.generate(numberOfPeople, (_) => TextEditingController());
        _resultMessage = "";
      });
    }
  }

  void _calculateSplit() {
    final double? totalAmount = double.tryParse(_totalAmountController.text);
    if (totalAmount == null || _amountControllers.any((c) => double.tryParse(c.text) == null)) {
      setState(() {
        _resultMessage = "Invalid input";
      });
      return;
    }

    int numPeople = _nameControllers.length;
    double perPerson = totalAmount / numPeople;

    List<String> names = [];
    List<double> amountsPaid = [];
    for (int i = 0; i < numPeople; i++) {
      final name = _nameControllers[i].text.isEmpty ? 'Person ${i + 1}' : _nameControllers[i].text;
      final amount = double.tryParse(_amountControllers[i].text) ?? 0;
      names.add(name);
      amountsPaid.add(amount);
    }

    String summary = "";
    for (int i = 0; i < numPeople; i++) {
      summary += "${names[i]} paid ₹${amountsPaid[i].toStringAsFixed(2)}, ";
    }
    summary = summary.trim();
    if (summary.endsWith(',')) summary = summary.substring(0, summary.length - 1);
    summary += ".\nTotal: ₹${totalAmount.toStringAsFixed(2)}. Everyone owes ₹${perPerson.toStringAsFixed(2)}.\n\n";

    // Add detailed balance info
    List<double> balances = List.generate(numPeople, (i) => amountsPaid[i] - perPerson);
    for (int i = 0; i < numPeople; i++) {
      double balance = balances[i];
      if (balance > 0) {
        summary += "${names[i]} should receive ₹${balance.toStringAsFixed(2)}.\n";
      } else if (balance < 0) {
        summary += "${names[i]} owes ₹${(-balance).toStringAsFixed(2)}.\n";
      } else {
        summary += "${names[i]} is settled.\n";
      }
    }

    summary += "\n";

    List<String> transactions = [];
    List<int> creditors = [], debtors = [];
    for (int i = 0; i < numPeople; i++) {
      if (balances[i] > 0) {
        creditors.add(i);
      } else if (balances[i] < 0) {
        debtors.add(i);
      }
    }

    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      int debtor = debtors[i];
      int creditor = creditors[j];

      double amountOwed = -balances[debtor];
      double amountToReceive = balances[creditor];
      double transfer = amountOwed < amountToReceive ? amountOwed : amountToReceive;

      transactions.add("${names[debtor]} owes ₹${transfer.toStringAsFixed(2)} to ${names[creditor]}");

      balances[debtor] += transfer;
      balances[creditor] -= transfer;

      if (balances[debtor].abs() < 0.01) i++;
      if (balances[creditor].abs() < 0.01) j++;
    }

    setState(() {
      _resultMessage = "$summary" + transactions.join("\n");
    });
  }

  void _copyToClipboard() {
    if (_resultMessage.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _resultMessage));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied to clipboard!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Bill Split"),
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(
              child: Column(
                children: [
                  _buildTextField(_totalAmountController, "Total Amount", TextInputType.number),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(_numberOfPeopleController, "Number of People", TextInputType.number),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _generateFields,
                        style: _buttonStyle(),
                        child: const Text("Generate"),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_nameControllers.isNotEmpty) ...[
              _buildInputCard(
                child: Column(
                  children: List.generate(_nameControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildTextField(_nameControllers[index], "Person ${index + 1} Name", TextInputType.text)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_amountControllers[index], "Amount Paid", TextInputType.number)),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _calculateSplit,
                  style: _buttonStyle(),
                  child: const Text("Split"),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_resultMessage.isNotEmpty)
              _buildResultCard(_resultMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType inputType) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: inputType,
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildResultCard(String result) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text("Copy Result"),
                style: _buttonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE39C6F),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }
}
