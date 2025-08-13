# strategy_advanced.py (نسخة صارمة)
import pandas as pd
import requests

def fetch_ohlcv(symbol, limit=50):
    try:
        coin = symbol.split("-")[0].lower()
        url = f"https://api.coingecko.com/api/v3/coins/{coin}/market_chart?vs_currency=usd&days={limit}&interval=daily"
        resp = requests.get(url, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        df = pd.DataFrame(data['prices'], columns=['timestamp','close'])
        df['high'] = [x[1] for x in data['prices']]
        df['low'] = [x[1] for x in data['prices']]
        df['volume'] = [v[1] for v in data['total_volumes']]
        df['close'] = df['close']
        return df
    except Exception as e:
        print(f"خطأ في جلب OHLCV لـ {symbol}: {e}")
        return pd.DataFrame()

def moving_average(series, period=20):
    return series.rolling(period).mean()

def support_resistance(df):
    recent_high = df['high'][-50:].max()
    recent_low = df['low'][-50:].min()
    return recent_low, recent_high

def fibonacci_levels(df):
    high = df['high'][-50:].max()
    low = df['low'][-50:].min()
    return {
        "50%": high - 0.5*(high-low),
        "61.8%": high - 0.618*(high-low)
    }

def check_signal(symbol):
    df = fetch_ohlcv(symbol)
    if df.empty or len(df) < 20:
        return False

    close = df['close']
    ma20 = moving_average(close, 20).iloc[-1]
    ma50 = moving_average(close, 50).iloc[-1]
    current_price = close.iloc[-1]

    # شرط صارم لاتجاه السوق: MA20 أعلى MA50 بفارق > 0.5%
    if ma20 < ma50 * 1.005:
        return False

    support, resistance = support_resistance(df)
    fib_levels = fibonacci_levels(df)

    # الدخول فقط إذا السعر قريب جدًا من الدعم أو الفيبوناتشي 50%-61.8%
    entry_zone = max(support, fib_levels['50%'], fib_levels['61.8%'])
    if current_price <= entry_zone * 1.01 and current_price < resistance:
        return True
    return False

def trade_targets(entry_price):
    return {
        "take_profit_1": entry_price * 1.04,  # 4%
        "take_profit_2": entry_price * 1.10,  # 10%
        "stop_loss": entry_price * 0.95       # 5%
    }
