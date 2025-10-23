### Signal ###

```json
{
    "id": "e5745507-514c-420c-8094-7b231d7bc312",
    "symbol": "QQQ",
    "price": 591.06,
    "confidence": 0.71,
    "type": "strong_buy", // enum("strong_sell", "sell", "hold", "buy", "strong_buy")
    "metrics": [
        {
            "RSI (14)": 34.2,
            "BB Proximity": 0.95,
            "Volume Ratio": 1.8,
            "σ from MA(20)": -2.3
        }
    ],
    "created_at": 1761185726
}
```

### Order ###

```json
{
    "id": "f71d22d3-5b0d-4814-9c59-dd4c2d927c46",
    "signal_id": "e5745507-514c-420c-8094-7b231d7bc312",
    "symbol": "QQQ",
    "quantity": 21,
    "price": 591.95,
    "side": "buy", // enum("buy", "sell")
    "position_intent": "buy_to_open", // enum("buy_to_open", "buy_to_close", "sell_to_open", "sell_to_close")
    "annotation": "order reasoning",
    "target": 596.01,
    "created_at": 1761185765,
    "updated_at": 1761185765
}
```
