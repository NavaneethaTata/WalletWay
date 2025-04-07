from flask import Flask, jsonify, request
from flask_cors import CORS  # Import CORS to handle cross-origin issues
import yfinance as yf

app = Flask(__name__)
CORS(app)  # Enable CORS for the Flask app

# Function to fetch stock data
def get_stock_data(symbol):
    try:
        stock = yf.Ticker(symbol)
        info = stock.info
        pe_ratio = info.get('trailingPE')  # PE Ratio (Trailing 12 months)
        sector = info.get('sector', 'Unknown')
        market_cap = info.get('marketCap', 'Unknown')
        name = info.get('shortName', symbol)
        
        # Return stock data with essential details
        return {
            "Name": name,
            "Sector": sector,
            "Market Cap": market_cap,
            "PE Ratio": pe_ratio,
        }
    except Exception as e:
        return {"error": f"Failed to retrieve data for {symbol}: {str(e)}"}

@app.route('/stocks/recommendation', methods=['GET'])
def stock_recommendation():
    try:
        # Retrieve query parameters
        min_pe = float(request.args.get('min_pe', 0))
        max_pe = float(request.args.get('max_pe', float('inf')))
        risk_level = request.args.get('risk_level', '').lower()
        
        # Example list of stock symbols
        symbols = ["AAPL", "MSFT", "GOOG", "AMZN", "TSLA"]  # Add more stock symbols as needed

        recommendations = []
        
        # Fetch stock data and filter based on P/E ratio
        for symbol in symbols:
            stock_data = get_stock_data(symbol)
            if "error" in stock_data:  # Skip if there is an error retrieving data
                continue
            
            pe_ratio = stock_data.get("PE Ratio")

            if pe_ratio and min_pe <= pe_ratio <= max_pe:
                reason = ""
                # Categorize based on the risk level and P/E ratio
                if risk_level == "low" and pe_ratio < 20:
                    reason = "Value stock with low risk."
                elif risk_level == "medium" and 20 <= pe_ratio <= 40:
                    reason = "Balanced growth with moderate risk."
                elif risk_level == "high" and pe_ratio > 40:
                    reason = "Growth stock with higher risk."

                stock_data["Reason"] = reason
                recommendations.append(stock_data)

        # Return recommendations if any, otherwise a message
        if recommendations:
            return jsonify(recommendations)
        else:
            return jsonify({"message": "No stocks match your criteria."})

    except Exception as e:
        return jsonify({"error": f"An error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=45000)  # Listen on all interfaces for easier testing
