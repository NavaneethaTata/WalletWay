import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

import 'app_drawer.dart';

class CalculatorScreen extends StatefulWidget {
  static const String routeName = '/calculator';
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = ""; // Stores user input
  String _output = "0"; // Stores evaluated result
  bool _isOpeningBracket = true; // Track parentheses usage

  void _onPressed(String value) {
    setState(() {
      if (value == "AC") {
        _input = "";
        _output = "0";
      } else if (value == "=") {
        _output = _evaluateExpression(_input);
      } else if (value == "⌫") {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == "()") {
        _input += _isOpeningBracket ? "(" : ")";
        _isOpeningBracket = !_isOpeningBracket;
      } else {
        _input += value;
      }
    });
  }

  // Function to evaluate mathematical expressions
  String _evaluateExpression(String input) {
    try {
      Parser parser = Parser();
      Expression exp = parser.parse(
          input.replaceAll('×', '*').replaceAll('÷', '/'));
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      return eval.toString();
    } catch (e) {
      return "Error";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> buttons = [
      "AC", "()", "%", "÷",
      "7", "8", "9", "×",
      "4", "5", "6", "-",
      "1", "2", "3", "+",
      "0", ".", "⌫", "="
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculator"),
        backgroundColor: const Color(0xFFE39C6F),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Display area
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _input,
                    style: const TextStyle(fontSize: 32, color: Colors.black54),
                  ),
                  Text(
                    _output,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Buttons Grid
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
              ),
              itemCount: buttons.length,
              itemBuilder: (context, index) {
                return ElevatedButton(
                  onPressed: () => _onPressed(buttons[index]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: Text(buttons[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
