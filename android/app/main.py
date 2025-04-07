import yfinance as yf
import pandas as pd
from fastapi import FastAPI, HTTPException

# Create FastAPI instance
app = FastAPI()

# Expanded list of tickers
tickers = [
    'RELIANCE.NS', 'TCS.NS', 'INFY.NS', 'HDFCBANK.NS', 'ITC.NS', 
    'HINDUNILVR.NS', 'ASIANPAINT.NS', 'BAJFINANCE.NS', 'KOTAKBANK.NS', 
    'LT.NS', 'SUNPHARMA.NS', 'AAPL', 'MSFT', 'GOOGL', 'META', 'TSLA', 
    'V', 'JNJ', 'PG', 'KO', 'MCD', 'PEP', 'WMT', 'COST', 'DIS', 
    'BABA', 'TM', 'SIEGY', 'RDS.A', 'NESN.SW', 'VOO', 'VTI', 'QQQ', 'SPY', 'IVV'
]

# Function to fetch stock fundamentals
def fetch_stock_fundamentals(tickers):
    stock_info = {}
    for ticker in tickers:
        stock = yf.Ticker(ticker)
        info = stock.info
        stock_info[ticker] = {
            'Name': info.get('shortName', 'N/A'),
            'Sector': info.get('sector', 'N/A'),
            'Market Cap': info.get('marketCap', 'N/A'),
            'P/E Ratio': pd.to_numeric(info.get('trailingPE', 'N/A'), errors='coerce'),
            'Dividend Yield': pd.to_numeric(info.get('dividendYield', 'N/A'), errors='coerce')
        }
    return pd.DataFrame.from_dict(stock_info, orient='index')

# Function to get stock recommendations
def get_recommendations(risk_level):
    try:
        stock_fundamentals = fetch_stock_fundamentals(tickers)
        
        # Filter based on risk level
        if risk_level == 'Low':
            selected_stocks = stock_fundamentals[
                (stock_fundamentals['P/E Ratio'] < 20) & (stock_fundamentals['Dividend Yield'] > 0.02)
            ]
            reason = "Low P/E Ratio and high dividend yield suggest stability and lower risk."
        elif risk_level == 'Medium':
            selected_stocks = stock_fundamentals[
                (stock_fundamentals['P/E Ratio'] >= 20) & (stock_fundamentals['P/E Ratio'] <= 40)
            ]
            reason = "Moderate P/E Ratio indicating balanced growth potential and moderate risk."
        elif risk_level == 'High':
            selected_stocks = stock_fundamentals[stock_fundamentals['P/E Ratio'] > 40]
            reason = "High P/E Ratio suggests growth potential but higher risk."
        else:
            raise ValueError("Invalid risk level")

        if selected_stocks.empty:
            return [{"Message": "No stocks match the criteria for the selected risk level"}]

        recommendations = selected_stocks[['Name', 'Sector', 'Market Cap', 'P/E Ratio']].to_dict(orient='records')
        for recommendation in recommendations:
            recommendation['Reason'] = reason
        
        return recommendations
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing data: {str(e)}")

# Educational resources
def get_educational_resources():
    return [
        {"title": "Investing for Beginners", "url": "https://www.investopedia.com/investing-for-beginners-4689848"},
        {"title": "Understanding Stock Market Risk", "url": "https://www.nerdwallet.com/article/investing/investing-risk"},
        {"title": "ETFs: What You Need to Know", "url": "https://www.fidelity.com/learning-center/investment-products/etf/what-are-etfs"},
        {"title": "How to Start Investing with Low Risk", "url": "https://www.bankrate.com/investing/best-low-risk-investments/"},
    ]

# Endpoint for root
@app.get("/")
def read_root():
    return {
        "message": (
            "Welcome to the Stock Recommendations API. "
            "Use /recommendations/{risk_level} to get stock advice and resources."
        )
    }

# Combined endpoint for recommendations and resources
@app.get("/recommendations/{risk_level}")
def recommend_stocks(risk_level: str):
    try:
        recommendations = get_recommendations(risk_level.capitalize())
        resources = get_educational_resources()
        return {
            "recommendations": recommendations,
            "resources": resources
        }
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid risk level. Choose 'Low', 'Medium', or 'High'.")
