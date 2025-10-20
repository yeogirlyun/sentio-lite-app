# Sentio Lite iOS App - Technical Development Specification

## Overview

Sentio Lite is a free iOS application that provides AI-powered trading signals for 12 leveraged ETFs. The app offers real-time signal updates, portfolio tracking, and detailed analytics for educational purposes.

---

## Tech Stack

### Frontend
- **Platform:** iOS 15.0+
- **Language:** Swift 5.0+
- **Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)

### Backend/API
- **API:** RESTful JSON API
- **Authentication:** None (public read-only)
- **Real-time Updates:** WebSocket or Server-Sent Events
- **Hosting:** AWS Lambda + API Gateway (serverless)

### Data Storage
- **Local:** Core Data or Realm
- **Cloud Sync:** CloudKit (optional, for cross-device)
- **Cache:** In-memory + persistent cache

### Third-Party Libraries
- **Charts:** Swift Charts (iOS 16+) or Charts framework
- **Networking:** URLSession (native) or Alamofire
- **JSON:** Codable (native)
- **WebSocket:** Starscream (if needed)

---

## Architecture

```
┌─────────────────────────────────────────┐
│           iOS App (SwiftUI)             │
├─────────────────────────────────────────┤
│  Views                                   │
│  ├─ DashboardView                       │
│  ├─ PositionsView                       │
│  ├─ SymbolDetailView                    │
│  ├─ HistoryView                         │
│  └─ SettingsView                        │
├─────────────────────────────────────────┤
│  ViewModels                              │
│  ├─ DashboardViewModel                  │
│  ├─ PortfolioViewModel                  │
│  ├─ SignalViewModel                     │
│  └─ TradeHistoryViewModel               │
├─────────────────────────────────────────┤
│  Services                                │
│  ├─ APIService                          │
│  ├─ WebSocketService                    │
│  ├─ PortfolioService                    │
│  └─ NotificationService                 │
├─────────────────────────────────────────┤
│  Models                                  │
│  ├─ Signal                              │
│  ├─ Position                            │
│  ├─ Trade                               │
│  └─ Portfolio                           │
├─────────────────────────────────────────┤
│  Data Layer                              │
│  ├─ Core Data / Realm                   │
│  ├─ UserDefaults                        │
│  └─ Cache Manager                       │
└─────────────────────────────────────────┘
           ↓ HTTP/WebSocket
┌─────────────────────────────────────────┐
│        Backend API (Serverless)         │
├─────────────────────────────────────────┤
│  Endpoints                               │
│  ├─ GET /api/v1/signals                 │
│  ├─ GET /api/v1/symbols/{symbol}        │
│  ├─ GET /api/v1/portfolio               │
│  └─ WebSocket /ws/signals               │
├─────────────────────────────────────────┤
│  Sentio Lite Engine (Proprietary)      │
│  ├─ AI Prediction Engine                │
│  ├─ Signal Generator                    │
│  ├─ Portfolio Tracker                   │
│  └─ Trade Executor (Virtual)            │
└─────────────────────────────────────────┘
```

---

## Data Models

### Signal
```swift
struct Signal: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let timestamp: Date
    let price: Double
    let change: Double
    let changePercent: Double

    // Signal Information
    let signalType: SignalType  // .buy, .sell, .hold
    let confidence: Double       // 0.0 - 1.0
    let targetReturn: Double
    let stopLoss: Double
    let profitTarget: Double

    // Technical Indicators
    let aiSignal: Double
    let rsi: Double
    let volumeRatio: Double

    // AI Recommendation
    let recommendation: String
    let reasoning: String
}

enum SignalType: String, Codable {
    case buy = "BUY"
    case sell = "SELL"
    case hold = "HOLD"
}
```

### Position
```swift
struct Position: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let entryPrice: Double
    let currentPrice: Double
    let shares: Int
    let entryTime: Date

    var pnl: Double {
        return (currentPrice - entryPrice) * Double(shares)
    }

    var pnlPercent: Double {
        return ((currentPrice - entryPrice) / entryPrice) * 100
    }
}
```

### Trade
```swift
struct Trade: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let entryPrice: Double
    let exitPrice: Double
    let shares: Int
    let entryTime: Date
    let exitTime: Date
    let pnl: Double
    let pnlPercent: Double
    let signalType: SignalType
}
```

### Portfolio
```swift
struct Portfolio: Codable {
    let initialCapital: Double = 100000.0
    var currentValue: Double
    var cashBalance: Double
    var positions: [Position]
    var trades: [Trade]

    var totalPnL: Double {
        return currentValue - initialCapital
    }

    var totalPnLPercent: Double {
        return ((currentValue - initialCapital) / initialCapital) * 100
    }

    var dayPnL: Double {
        // Calculate from today's trades
    }
}
```

---

## API Endpoints

### Base URL
```
https://api.sentiolite.com/v1
```

### 1. Get All Signals
```
GET /signals
```

**Response:**
```json
{
  "timestamp": "2025-10-20T10:30:00Z",
  "signals": [
    {
      "symbol": "TQQQ",
      "price": 102.45,
      "change": 2.34,
      "changePercent": 2.34,
      "signalType": "BUY",
      "confidence": 0.87,
      "targetReturn": 3.96,
      "stopLoss": -1.12,
      "profitTarget": 106.51,
      "aiSignal": 2.45,
      "rsi": 34.2,
      "volumeRatio": 1.8,
      "recommendation": "Strong Buy Signal - High confidence based on proprietary AI indicators and momentum.",
      "reasoning": "Entry recommended at current levels with 3.96% profit target and 1.12% stop loss."
    }
  ]
}
```

### 2. Get Symbol Detail
```
GET /symbols/{symbol}
```

**Response:**
```json
{
  "symbol": "TQQQ",
  "name": "Nasdaq 3x Bull",
  "price": 102.45,
  "signal": { /* Signal object */ },
  "historicalData": [
    {
      "timestamp": "2025-10-20T09:30:00Z",
      "open": 101.20,
      "high": 102.80,
      "low": 101.00,
      "close": 102.45,
      "volume": 2400000
    }
  ]
}
```

### 3. Get Portfolio Status
```
GET /portfolio
```

**Response:**
```json
{
  "initialCapital": 100000.0,
  "currentValue": 101248.50,
  "cashBalance": 91108.50,
  "totalPnL": 1248.50,
  "totalPnLPercent": 1.25,
  "dayPnL": 348.50,
  "dayPnLPercent": 0.35,
  "positions": [ /* Position objects */ ],
  "recentTrades": [ /* Trade objects */ ]
}
```

### 4. WebSocket - Real-time Signals
```
WS /ws/signals
```

**Message Format:**
```json
{
  "type": "signal_update",
  "data": {
    "symbol": "TQQQ",
    "price": 102.50,
    "signal": { /* Updated Signal object */ }
  }
}
```

---

## Screen Specifications

### 1. Dashboard Screen

**Components:**
- Header with app title and subtitle
- Portfolio summary card
  - Current value (large, bold)
  - Day's change (with arrow, colored)
  - Total return
- Live signals list
  - Signal cards (scrollable)
  - Each showing: symbol, price, signal badge, confidence, metrics

**Actions:**
- Tap signal card → Navigate to Symbol Detail
- Pull to refresh → Reload signals
- Auto-refresh every 60 seconds

### 2. Positions Screen

**Components:**
- Header
- Total P&L card
- Active positions list
  - Position cards showing: symbol, shares, entry price, current price, P&L

**Actions:**
- Tap position → Navigate to Symbol Detail
- Pull to refresh

### 3. Symbol Detail Screen

**Components:**
- Header with back button, symbol, name
- AI recommendation card
- Timeframe selector (1D, 5D, 1M, 3M)
- Interactive price chart
- Technical indicators grid
- Position parameters grid
- Execute trade button (demo)

**Actions:**
- Back button → Return to Dashboard
- Timeframe buttons → Update chart
- Execute trade → Show confirmation dialog

### 4. History Screen

**Components:**
- Header
- Performance summary card (win rate, total trades)
- Trade log list
  - Trade cards showing: symbol, date, entry/exit, P&L

**Actions:**
- Tap trade → Show trade detail modal
- Export button → Generate CSV and share

### 5. Settings Screen

**Components:**
- Header
- Legal disclaimer card (prominent)
- About section with app info
- Links to Privacy Policy, Terms, Risk Disclosure

**Actions:**
- Tap links → Open web views
- Version info tap → Show debug info (hidden feature)

---

## User Flow

### First Launch
1. Show splash screen with logo
2. Display disclaimer dialog (must accept to continue)
3. Navigate to Dashboard
4. Auto-fetch initial data

### Normal Usage
1. App opens → Dashboard
2. View signals → Tap for details
3. Check positions → Monitor P&L
4. Review history → Learn from trades

### Background Refresh
1. App enters background → Stop WebSocket
2. App enters foreground → Reconnect, refresh data
3. Silent push notification → Update badge (future)

---

## Technical Requirements

### Performance
- Launch time: < 2 seconds
- Signal refresh: < 1 second
- Chart rendering: 60 FPS
- Memory usage: < 100 MB

### Offline Support
- Cache last fetched signals
- Show "Offline" banner when disconnected
- Queue actions for when online returns

### Accessibility
- VoiceOver support for all screens
- Dynamic Type support
- Minimum contrast ratio 4.5:1
- Haptic feedback for actions

### Error Handling
- Network errors → Retry with exponential backoff
- API errors → Show user-friendly message
- Crash → Log to crash reporting service

---

## Security & Privacy

### Data Protection
- No user accounts = no passwords to protect
- All data stays on device
- No tracking or analytics
- No third-party SDKs (ads, tracking)

### API Security
- HTTPS only
- Rate limiting (100 requests/minute per IP)
- No authentication required (public API)
- CORS enabled for web version

### Legal Compliance
- Disclaimer shown on first launch (required)
- Terms of Service acceptance
- Risk disclosure acknowledgment
- App Store age rating 17+

---

## Testing Strategy

### Unit Tests
- ViewModels (business logic)
- Services (API calls, data parsing)
- Models (calculations, validations)
- Target: 80% code coverage

### UI Tests
- Navigation flows
- User interactions
- Data display accuracy
- Error states

### Integration Tests
- API endpoint integration
- WebSocket connectivity
- Data persistence
- Background refresh

### Manual Testing
- Real device testing (iPhone 12+)
- Different network conditions
- Low battery scenarios
- Memory warnings

---

## Deployment

### App Store Requirements
- Xcode 14+
- iOS 15.0+ deployment target
- App icon (all sizes)
- Launch screen storyboard
- App Store screenshots (6 required)
- Privacy Policy URL
- Support URL

### Release Process
1. Version bump (semantic versioning)
2. Run all tests
3. Archive build
4. Upload to App Store Connect
5. Submit for review
6. Monitor crash reports

### Versioning
- **v1.0.0** - Initial release (MVP)
- **v1.1.0** - Push notifications
- **v1.2.0** - Customizable alerts
- **v2.0.0** - Major feature updates

---

## Development Timeline

### Phase 1: MVP (4-6 weeks)
- Week 1-2: Project setup, data models, API integration
- Week 3-4: UI implementation (all screens)
- Week 5: Testing, bug fixes, polish
- Week 6: App Store submission

### Phase 2: Enhancements (2-3 weeks)
- Push notifications
- Improved charting
- Performance optimization

### Phase 3: Advanced Features (3-4 weeks)
- More symbols
- Social features
- iPad version

---

## Dependencies

### Required
```ruby
# Podfile or Swift Package Manager

# Charts
github "danielgindi/Charts"

# WebSocket (if needed)
github "daltoniam/Starscream"

# Optional: Networking
github "Alamofire/Alamofire"
```

### Optional
- SwiftLint (code quality)
- SwiftFormat (code formatting)
- Crashlytics (crash reporting)

---

## File Structure

```
SentioLite/
├── App/
│   ├── SentioLiteApp.swift
│   ├── ContentView.swift
│   └── Info.plist
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── SignalCardView.swift
│   │   └── PortfolioSummaryView.swift
│   ├── Positions/
│   │   ├── PositionsView.swift
│   │   └── PositionCardView.swift
│   ├── Detail/
│   │   ├── SymbolDetailView.swift
│   │   └── ChartView.swift
│   ├── History/
│   │   ├── HistoryView.swift
│   │   └── TradeCardView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── DisclaimerView.swift
├── ViewModels/
│   ├── DashboardViewModel.swift
│   ├── PortfolioViewModel.swift
│   ├── SignalViewModel.swift
│   └── TradeHistoryViewModel.swift
├── Models/
│   ├── Signal.swift
│   ├── Position.swift
│   ├── Trade.swift
│   └── Portfolio.swift
├── Services/
│   ├── APIService.swift
│   ├── WebSocketService.swift
│   ├── PortfolioService.swift
│   └── NotificationService.swift
├── Utilities/
│   ├── Extensions/
│   ├── Constants.swift
│   └── Formatters.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Colors.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    ├── UITests/
    └── IntegrationTests/
```

---

## Key Metrics to Track

### User Engagement
- Daily Active Users (DAU)
- Session duration
- Screens per session
- Signal views
- Position tracking usage

### Technical Metrics
- API response time
- App crash rate
- Network error rate
- Battery usage
- Memory footprint

### Business Metrics
- App Store downloads
- User ratings
- Review sentiment
- Feature usage

---

## Support & Maintenance

### Bug Reporting
- In-app "Report Bug" feature
- Email: support@sentiolite.com
- GitHub Issues (if open source)

### Updates
- Bi-weekly bug fix releases
- Monthly feature releases
- Quarterly major updates

### Monitoring
- Crash reporting (Crashlytics)
- Performance monitoring
- API uptime monitoring
- User feedback collection

---

## Legal & Compliance

### Required Documents
1. **Terms of Service**
2. **Privacy Policy**
3. **Risk Disclosure Statement**
4. **Cookie Policy** (if web version)

### Disclaimers (In-App)
- First launch disclaimer (modal)
- Settings screen disclaimer (visible)
- Every signal screen (footer)
- Trade execution (confirmation)

---

## Questions for Stakeholders

1. Should we support dark mode? (Recommended: Yes)
2. Should we support iPad? (Future: Yes, v2.0)
3. Should we support landscape orientation? (Recommended: iPhone portrait only initially)
4. Should we support multiple languages? (Future: Yes, v1.5)
5. Backend hosting preference? (AWS, Google Cloud, self-hosted?)
6. Do we need push notifications in v1.0? (Recommended: v1.1)
7. Should we open source the iOS app? (Recommended: Keep proprietary, open source engine)

---

© 2025 Sentio Lite Development Team
