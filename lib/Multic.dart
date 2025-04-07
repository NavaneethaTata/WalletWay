import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_drawer.dart'; // Import the AppDrawer

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});
  static const String routeName = '/currency_converter';

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  TextEditingController amountController = TextEditingController();
  String fromCurrency = "USD";
  String toCurrency = "INR";
  double exchangeRate = 0.0;
  String result = "";

  @override
  void initState() {
    super.initState();
    fetchExchangeRate(); // Fetch initial rate
  }

  Future<void> fetchExchangeRate() async {
    const String apiKey = "a636cdb11ba6d5a60fe314d8"; // Your API key
    final String url = "https://v6.exchangerate-api.com/v6/$apiKey/latest/$fromCurrency";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          exchangeRate = data['conversion_rates'][toCurrency] ?? 0.0;
        });
      } else {
        print("Failed to fetch rates: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching rates: $e");
    }
  }

  Future<void> convertCurrency() async {
    // Fetch the latest exchange rate before conversion
    await fetchExchangeRate();

    double amount = double.tryParse(amountController.text) ?? 0.0;
    double convertedAmount = amount * exchangeRate;

    setState(() {
      result =
      "The total amount of $amount $fromCurrency converts to ${convertedAmount.toStringAsFixed(2)} $toCurrency at an exchange rate of $exchangeRate.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Currency Converter"),
        backgroundColor: Color(0xFFE39C6F),
      ),
      drawer: AppDrawer(), // Add the AppDrawer here
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: fromCurrency,
                  items: ["USD", "INR", "EUR", "GBP", "JPY"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      fromCurrency = newValue!;
                    });
                  },
                ),
                Text("to"),
                DropdownButton<String>(
                  value: toCurrency,
                  items: ["USD", "INR", "EUR", "GBP", "JPY"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      toCurrency = newValue!;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Show a loading indicator while fetching the exchange rate
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE39C6F),
                      ),
                    );
                  },
                );

                await convertCurrency();

                // Remove the loading indicator
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE39C6F),
              ),
              child: Text("Convert",
                style: TextStyle(color: Colors.white), ),

            ),
            SizedBox(height: 20),
            Text(
              result,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}