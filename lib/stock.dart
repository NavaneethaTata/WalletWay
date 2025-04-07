import 'package:flutter/material.dart';
import 'app_drawer.dart'; // AppDrawer added
typedef Stock = Map<String, dynamic>;

class StockRecommendationPage extends StatefulWidget {
  static const String routeName = '/stock';

  @override
  _StockRecommendationPageState createState() => _StockRecommendationPageState();
}

class _StockRecommendationPageState extends State<StockRecommendationPage> {
  final TextEditingController _minPeRatioController = TextEditingController();
  final TextEditingController _maxPeRatioController = TextEditingController();
  final TextEditingController _riskLevelController = TextEditingController();

  String recommendation = "";

  final List<Stock> _stockData = [
    {'Name': 'Apple', 'Ticker': 'AAPL', 'Sector': 'Technology', 'Market Cap': 2.8e12, 'P/E Ratio': 28.3},
    {'Name': 'Microsoft', 'Ticker': 'MSFT', 'Sector': 'Technology', 'Market Cap': 2.4e12, 'P/E Ratio': 33.5},
    {'Name': 'Tesla', 'Ticker': 'TSLA', 'Sector': 'Automotive', 'Market Cap': 800e9, 'P/E Ratio': 55.2},
    {'Name': 'Procter & Gamble', 'Ticker': 'PG', 'Sector': 'Consumer Goods', 'Market Cap': 350e9, 'P/E Ratio': 24.1},
    {'Name': 'NVIDIA', 'Ticker': 'NVDA', 'Sector': 'Technology', 'Market Cap': 1e12, 'P/E Ratio': 95.4},
    {'Name': 'Coca-Cola', 'Ticker': 'KO', 'Sector': 'Consumer Beverages', 'Market Cap': 250e9, 'P/E Ratio': 22.6},
    {'Name': 'Amazon', 'Ticker': 'AMZN', 'Sector': 'E-commerce', 'Market Cap': 1.3e12, 'P/E Ratio': 57.9},
    {'Name': 'Alphabet', 'Ticker': 'GOOGL', 'Sector': 'Technology', 'Market Cap': 1.5e12, 'P/E Ratio': 34.1},
    {'Name': 'Meta', 'Ticker': 'META', 'Sector': 'Technology', 'Market Cap': 700e9, 'P/E Ratio': 35.5},
    {'Name': 'Walmart', 'Ticker': 'WMT', 'Sector': 'Retail', 'Market Cap': 400e9, 'P/E Ratio': 23.0},
    {'Name': 'Reliance Industries', 'Ticker': 'RELIANCE', 'Sector': 'Energy', 'Market Cap': 15e12, 'P/E Ratio': 31.4},
    {'Name': 'Tata Consultancy Services', 'Ticker': 'TCS', 'Sector': 'Technology', 'Market Cap': 12e12, 'P/E Ratio': 33.5},
    {'Name': 'Infosys', 'Ticker': 'INFY', 'Sector': 'Technology', 'Market Cap': 6e12, 'P/E Ratio': 25.1},
    {'Name': 'HDFC Bank', 'Ticker': 'HDFCBANK', 'Sector': 'Banking', 'Market Cap': 9e12, 'P/E Ratio': 20.8},
    {'Name': 'ICICI Bank', 'Ticker': 'ICICIBANK', 'Sector': 'Banking', 'Market Cap': 6e12, 'P/E Ratio': 22.0},
    {'Name': 'Hindustan Unilever', 'Ticker': 'HINDUNILVR', 'Sector': 'Consumer Goods', 'Market Cap': 5e12, 'P/E Ratio': 55.6},
    {'Name': 'State Bank of India', 'Ticker': 'SBIN', 'Sector': 'Banking', 'Market Cap': 5.5e12, 'P/E Ratio': 12.5},
    {'Name': 'Asian Paints', 'Ticker': 'ASIANPAINT', 'Sector': 'Consumer Goods', 'Market Cap': 3e12, 'P/E Ratio': 65.3},
    {'Name': 'Bharti Airtel', 'Ticker': 'BHARTIARTL', 'Sector': 'Telecom', 'Market Cap': 4.5e12, 'P/E Ratio': 43.0},
    {'Name': 'Wipro', 'Ticker': 'WIPRO', 'Sector': 'Technology', 'Market Cap': 3e12, 'P/E Ratio': 20.7},
    {'Name': 'Coal India', 'Ticker': 'COALINDIA', 'Sector': 'Energy', 'Market Cap': 1.2e12, 'P/E Ratio': 6.5},
    {'Name': 'Oil & Natural Gas Corp.', 'Ticker': 'ONGC', 'Sector': 'Energy', 'Market Cap': 1.8e12, 'P/E Ratio': 4.7},
    {'Name': 'Power Grid', 'Ticker': 'POWERGRID', 'Sector': 'Utilities', 'Market Cap': 1.5e12, 'P/E Ratio': 8.2},
    {'Name': 'ITC', 'Ticker': 'ITC', 'Sector': 'Consumer Goods', 'Market Cap': 5.6e12, 'P/E Ratio': 23.5},
    {'Name': 'Zomato', 'Ticker': 'ZOMATO', 'Sector': 'E-commerce', 'Market Cap': 600e9, 'P/E Ratio': 105.7},
    {'Name': 'Nykaa', 'Ticker': 'NYKAA', 'Sector': 'Retail', 'Market Cap': 400e9, 'P/E Ratio': 112.8},
    {'Name': 'Adani Green Energy', 'Ticker': 'ADANIGREEN', 'Sector': 'Energy', 'Market Cap': 1.3e12, 'P/E Ratio': 165.0},
    {'Name': 'Adani Enterprises', 'Ticker': 'ADANIENT', 'Sector': 'Conglomerate', 'Market Cap': 1.8e12, 'P/E Ratio': 72.4},
    {'Name': 'Maruti Suzuki', 'Ticker': 'MARUTI', 'Sector': 'Automotive', 'Market Cap': 3e12, 'P/E Ratio': 35.8},
    {'Name': 'Bajaj Finance', 'Ticker': 'BAJFINANCE', 'Sector': 'Financials', 'Market Cap': 4.7e12, 'P/E Ratio': 40.3},
    {'Name': 'HCL Technologies', 'Ticker': 'HCLTECH', 'Sector': 'Technology', 'Market Cap': 3.2e12, 'P/E Ratio': 22.4},
    {'Name': 'Larsen & Toubro', 'Ticker': 'LT', 'Sector': 'Infrastructure', 'Market Cap': 4e12, 'P/E Ratio': 25.7},
    {'Name': 'Sun Pharma', 'Ticker': 'SUNPHARMA', 'Sector': 'Pharmaceuticals', 'Market Cap': 3.5e12, 'P/E Ratio': 29.3},
    {'Name': 'Tata Motors', 'Ticker': 'TATAMOTORS', 'Sector': 'Automotive', 'Market Cap': 2e12, 'P/E Ratio': 12.7},
    {'Name': 'Dr. Reddys Labs', 'Ticker': 'DRREDDY', 'Sector': 'Pharmaceuticals', 'Market Cap': 2.8e12, 'P/E Ratio': 31.2},
    {'Name': 'Hero MotoCorp', 'Ticker': 'HEROMOTOCO', 'Sector': 'Automotive', 'Market Cap': 1.2e12, 'P/E Ratio': 19.8},
  ];

  List<Stock> _filterStocks(double minPe, double maxPe, String riskLevel) {
    return _stockData.where((stock) {
      final peRatio = stock['P/E Ratio'] as double;
      final marketCap = stock['Market Cap'] as double;

      if (peRatio < minPe || peRatio > maxPe) return false;

      if (riskLevel == 'low' && marketCap < 1e12) return false;
      if (riskLevel == 'medium' && (marketCap < 1e10 || marketCap >= 1e12)) return false;
      if (riskLevel == 'high' && marketCap >= 1e10) return false;

      return true;
    }).toList();
  }

  void _getRecommendation() {
    final double? minPeRatio = double.tryParse(_minPeRatioController.text);
    final double? maxPeRatio = double.tryParse(_maxPeRatioController.text);
    final String riskLevel = _riskLevelController.text.toLowerCase();

    if (minPeRatio == null || maxPeRatio == null || riskLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid input. Please enter valid data.")),
      );
      return;
    }

    if (minPeRatio >= maxPeRatio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Min P/E ratio must be less than Max P/E ratio.")),
      );
      return;
    }

    final filteredStocks = _filterStocks(minPeRatio, maxPeRatio, riskLevel);

    setState(() {
      if (filteredStocks.isNotEmpty) {
        recommendation = "Recommended Stocks:\n\n";
        for (var stock in filteredStocks) {
          recommendation += "Stock: ${stock['Name']} (Ticker: ${stock['Ticker']})\n";
          recommendation += "Sector: ${stock['Sector']}\n";
          recommendation += "Market Cap: ${stock['Market Cap']}\nPE Ratio: ${stock['P/E Ratio']}\n\n";
        }
      } else {
        recommendation = "No stocks match your criteria.";
      }
    });
  }

  void _showPeRatioInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About P/E Ratio'),
          content: const Text(
            "The Price-to-Earnings (P/E) ratio is a measure of a company's valuation, calculated as:\n"
                "P/E Ratio = Market Price per Share / Earnings per Share (EPS).\n\n"
                "For example:\n"
                " - Low P/E ratio (<20): May indicate a value stock or less risky option.\n"
                " - Medium P/E ratio (20-40): Indicates moderate growth with balanced risk.\n"
                " - High P/E ratio (>40): Often reflects growth stocks with higher risk.\n",
            style: TextStyle(fontSize: 14),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Recommendations'),
        backgroundColor: const Color(0xFFE39C6F),
      ),
      drawer: const AppDrawer(), // <<== Included the App Drawer here
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _showPeRatioInfo,
                child: const Text('Get to Know About P/E Ratio'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minPeRatioController,
                decoration: const InputDecoration(
                  labelText: "Min P/E Ratio",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxPeRatioController,
                decoration: const InputDecoration(
                  labelText: "Max P/E Ratio",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _riskLevelController,
                decoration: const InputDecoration(
                  labelText: "Risk Level (Low/Medium/High)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getRecommendation,
                child: const Text('Get Recommendations'),
              ),
              const SizedBox(height: 24),
              if (recommendation.isNotEmpty)
                Text(
                  recommendation,
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
