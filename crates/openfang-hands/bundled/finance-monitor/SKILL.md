# Finance Monitor Hand

Autonomous market analysis agent that runs 1 hour after US market open.

## What It Does

1. **Runs TV Screener** — Fetches dynamic watchlist from TradingView (e.g., `us_strong_daily`)
2. **Collects Data** — Gets 2 years of historical data for each symbol
3. **Technical Analysis** — Calculates RSI, MACD, ADX, SMA trends
4. **Price Forecasting** — Uses Chronos-2 foundation model for 5-day predictions
5. **Generates Charts** — Creates TA charts and forecast visualizations
6. **Recommends Best Symbol** — Weighted scoring: 70% technical + 30% forecast
7. **Produces Report** — HTML with embedded charts (or Markdown)

## Schedule

| Event | Time (ET) | Time (UTC) | Time (CET) |
|-------|-----------|------------|------------|
| Market Open | 9:30 AM | 14:30 | 15:30 |
| **Hand Trigger** | **10:30 AM** | **15:30** | **16:30** |
| Market Close | 4:00 PM | 21:00 | 22:00 |

## Skills Used

| Skill | Tools Used |
|-------|------------|
| tv-screener | `screener_run` |
| finance-data | `stock_get_quote`, `stock_get_history`, `stock_get_fundamentals`, `stock_get_news` |
| finance-analysis | `ta_analyze`, `ta_get_signals` |
| finance-charts | `chart_create_ta` |
| finance-forecast | `forecast_fast` |

## Scoring System

### Technical Score (70% weight)
- RSI signals (oversold/overbought)
- MACD crossovers
- ADX trend strength
- SMA 50/200 position

### Forecast Score (30% weight)
- Predicted upside/downside %
- Confidence level

### Signal Thresholds
| Score | Signal |
|-------|--------|
| 70-100 | STRONG BUY |
| 50-69 | BUY |
| 30-49 | HOLD |
| 10-29 | SELL |
| 0-9 | STRONG SELL |

## Output Files

```
data/
├── charts/
│   ├── AAPL_ta_2024-03-15.png
│   ├── AAPL_forecast_2024-03-15.png
│   └── ...
├── reports/
│   └── finance_report_2024-03-15.html
└── screener_output_2024-03-15.json
```

## Configuration

| Setting | Default | Options |
|---------|---------|---------|
| screener_id | us_strong_daily | us_best_winners, us_quality_momentum, us_short_technical |
| screener_limit | 10 | 5, 10, 20 |
| report_format | html | html, markdown, json |
| signal_threshold | medium | low (30+), medium (50+), high (70+) |
| enable_charts | true | true/false |
| telegram_alerts | false | true/false |

## Requirements

- tv-screener skill installed
- finance-data skill installed
- finance-analysis skill installed
- finance-charts skill installed
- finance-forecast skill installed
- (Optional) telegram skill for alerts
