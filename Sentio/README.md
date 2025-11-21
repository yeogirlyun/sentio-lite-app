# Sentio Lite - iOS App

A SwiftUI-based iOS application for monitoring AI-powered trading signals and portfolio positions across 12 leveraged ETFs. Built with a modern MVVM architecture, Sentio Lite provides real-time updates, detailed analytics, and educational trading insights.

## 🎯 Overview

Sentio Lite is a free, educational trading signals app that:
- Displays real-time trading signals powered by AI algorithms
- Tracks active positions and portfolio performance
- Shows historical trade data and profit/loss analytics
- Provides detailed metrics and technical indicators
- Supports monitoring of 12 leveraged ETFs

**Version:** 1.0
**Platform:** iOS 15.0+
**Language:** Swift 5.0+

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Data Models](#data-models)
- [Views & Screens](#views--screens)
- [Development Guidelines](#development-guidelines)
- [Contributing](#contributing)

## ✨ Features

### Core Features
- **Signals Dashboard** - Real-time AI-powered trading signals (Strong Buy, Buy, Hold, Sell, Strong Sell)
- **Positions Tracking** - Monitor active positions with entry price, quantity, and profit/loss
- **History & Analytics** - View past trades and performance metrics
- **Technical Metrics** - RSI, Bollinger Bands, Volume Ratio, Moving Average deviations
- **Real-time Updates** - Live signal and position updates

### UI Components
- **Tab Navigation** - Easy switching between Signals, Positions, History, and About
- **Header View** - Consistent app branding and section titles
- **Signal Widgets** - Visual signal display with confidence levels
- **Position Widgets** - Quick position overview with profit indicators
- **Shimmer Loading** - Smooth loading state animations

## 🛠 Tech Stack

### Framework & Language
- **iOS**: iOS 15.0 or later
- **Framework**: SwiftUI
- **Language**: Swift 5.0+
- **Architecture Pattern**: MVVM (Model-View-ViewModel)

### Design & UI
- **Colors**:
  - Alice Blue (primary)
  - Accent Color (action/highlights)
  - Profit Color (gains - green)
  - Loss Color (losses - red)
- **Icons**: SF Symbols for consistent iOS design
- **Layout**: SwiftUI with VStack/HStack compositions

### Data & Storage
- **Networking**: URLSession (native)
- **JSON Parsing**: Codable protocol
- **Local Storage**: UserDefaults (for app preferences)
- **Model Persistence**: Codable structs for serialization

### Tools
- **IDE**: Xcode
- **Build System**: Swift Package Manager compatible
- **Package Format**: .xcodeproj

## 🏗 Architecture

### MVVM Pattern

```
┌─────────────────────────────────────────┐
│              Views (UI Layer)           │
├─────────────────────────────────────────┤
│  - SignalsView          - PositionsView │
│  - ProfitsView          - AboutView     │
│  - OrderView            - HeaderView    │
└─────────────────────────────────────────┘
              ↓ @ObservedObject
┌─────────────────────────────────────────┐
│        ViewModels (Logic Layer)         │
├─────────────────────────────────────────┤
│  - SignalsViewModel     - PositionsViewModel  │
│  - ProfitViewModel      - TradeLogic    │
└─────────────────────────────────────────┘
              ↓ Uses
┌─────────────────────────────────────────┐
│        Models (Data Layer)              │
├─────────────────────────────────────────┤
│  - Signal       - Position   - Symbol   │
│  - Metric       - ProfitLog  - ProfitSummary │
└─────────────────────────────────────────┘
```

### Data Flow

1. **User Interaction** → View triggers ViewModel method
2. **ViewModel Processing** → Fetches/processes data from Models
3. **Model Updates** → Decodes API response or updates state
4. **View Refresh** → ObservedObject binding triggers UI update
5. **Display** → SwiftUI renders updated view hierarchy

## 📁 Project Structure

```
Sentio/
├── Sentio/                          # Main app target
│   ├── SentioApp.swift              # App entry point (@main)
│   ├── ContentView.swift            # Root tab navigation
│   ├── AboutView.swift              # About tab content
│   ├── HistoryView.swift            # History tab content
│   │
│   ├── Signals/                     # Trading signals feature
│   │   ├── SignalsView.swift        # Signals list display
│   │   ├── SignalsViewModel.swift   # Signals logic & state
│   │   └── SignalWidget.swift       # Individual signal card
│   │
│   ├── Positions/                   # Portfolio positions feature
│   │   ├── PositionsView.swift      # Positions list display
│   │   ├── PositionsViewModel.swift # Positions logic & state
│   │   └── PositionWidget.swift     # Individual position card
│   │
│   ├── Profits/                     # Trade history & analytics
│   │   ├── ProfitsView.swift        # Main profits/history view
│   │   ├── ProfitDetailsView.swift  # Trade detail view
│   │   ├── OrderView.swift          # Order/trade display
│   │   └── ViewModel.swift          # Profits logic & state
│   │
│   ├── Shared/                      # Shared models & components
│   │   ├── HeaderView.swift         # Section header component
│   │   ├── PageInfo.swift           # Page metadata
│   │   ├── Signal.swift             # Signal model & SignalType enum
│   │   ├── Metric.swift             # Technical metric struct (in Signal.swift)
│   │   ├── Symbol.swift             # Trading symbol/ETF model
│   │   ├── Position.swift           # Position model
│   │   ├── ProfitLog.swift          # Trade history record
│   │   ├── ProfitSummary.swift      # Portfolio summary
│   │   └── Shimmer.swift            # Loading animation
│   │
│   ├── Assets.xcassets/             # Images & colors
│   │   ├── AppIcon.appiconset/      # App icon (multiple sizes)
│   │   ├── AccentColor.colorset/    # Accent color
│   │   ├── AliceBlue.colorset/      # Primary blue
│   │   ├── ProfitColor.colorset/    # Green (gains)
│   │   ├── LossColor.colorset/      # Red (losses)
│   │   └── Contents.json
│   │
│   ├── LaunchScreen.storyboard      # Splash screen
│   ├── Info.plist                   # App configuration
│   └── logo.png                     # App logo
│
└── Sentio.xcodeproj/                # Xcode project
    ├── project.pbxproj              # Project configuration
    └── project.xcworkspace/         # Workspace configuration
```

## 🚀 Getting Started

### Prerequisites
- macOS 12.0 or later
- Xcode 14.0 or later
- Swift 5.0 or later
- iOS 15.0+ device or simulator

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sentio-lite-app
   ```

2. **Open the project in Xcode**
   ```bash
   cd Sentio
   open Sentio.xcodeproj
   ```

3. **Build the app**
   - Select your target device/simulator
   - Press `Cmd + B` to build
   - Press `Cmd + R` to run

4. **Configure API endpoints** (if needed)
   - Update API base URLs in ViewModels
   - Configure WebSocket connections for real-time updates

### Build Settings
- **Minimum Deployment**: iOS 15.0
- **Swift Version**: 5.0+
- **Bundle Identifier**: Configure in Xcode
- **Team ID**: Required for device deployment

## 📊 Data Models

### Signal
Represents an AI-generated trading signal with confidence and technical metrics.

```swift
struct Signal: Codable, Identifiable {
    let id: UUID
    let symbol: String
    let price: Double
    let confidence: Double        // 0.0 - 1.0
    let type: SignalType         // strong_sell, sell, hold, buy, strong_buy
    let metrics: [Metric]        // Technical analysis metrics
    let createdAt: Date
}

enum SignalType: String, Codable {
    case strongSell = "strong_sell"
    case sell = "sell"
    case hold = "hold"
    case buy = "buy"
    case strongBuy = "strong_buy"
}
```

### Position
Represents an open trading position with entry/exit levels.

```swift
struct Position: Identifiable, Codable {
    let id: String
    let symbol: Symbol
    let signal: Signal?
    let quantity: Double
    let price: Double           // Entry price
    let stopLoss: Double?
    let takeProfit: Double?
    let annotation: String?
    let createdAt: Date
    let profit: Double          // Current P&L
    let duration: UInt          // Time held in seconds
}
```

### Symbol
Represents a traded ETF/symbol.

```swift
struct Symbol: Identifiable, Codable, Hashable {
    let id: String              // Ticker symbol (e.g., "QQQ")
    let name: String            // Full name
    let price: Double           // Current price
    let change: Double          // Price change
    let changePercent: Double   // Percentage change
}
```

### Metric
Technical indicator used in signal analysis.

```swift
struct Metric: Codable, Hashable {
    let name: String           // e.g., "RSI (14)", "BB Proximity"
    let value: Double          // Metric value
}
```

### ProfitLog & ProfitSummary
Trade history and portfolio performance summaries.

```swift
struct ProfitLog: Identifiable, Codable {
    let id: String
    let symbol: String
    let quantity: Double
    let entryPrice: Double
    let exitPrice: Double
    let profit: Double
    let profitPercent: Double
    let duration: UInt
    let closedAt: Date
}

struct ProfitSummary: Codable {
    let totalProfit: Double
    let winRate: Double
    let totalTrades: Int
    let averageWin: Double
    let averageLoss: Double
}
```

## 🎨 Views & Screens

### Tab Structure
The app uses a tab-based navigation with 4 main sections:

#### 1. **Signals Tab** (`SignalsView`)
- Lists all active trading signals
- Shows signal type (buy/sell/hold) with color coding
- Displays confidence level
- Technical metrics breakdown
- Real-time updates for new signals

#### 2. **Positions Tab** (`PositionsView`)
- Current open positions
- Entry price, quantity, current P&L
- Stop loss and take profit levels
- Position duration
- Quick position overview cards

#### 3. **History Tab** (`ProfitsView`)
- Past closed trades
- Trade performance analytics
- Profit/loss summary
- Win rate statistics
- Detailed trade information via `ProfitDetailsView`

#### 4. **About Tab** (`AboutView`)
- App information
- Version details
- Credits and legal information

### Shared Components

**HeaderView**
- Section header with title and description
- Consistent branding across tabs
- Customizable styling

**SignalWidget**
- Visual representation of a single signal
- Shows symbol, signal type, confidence, metrics
- Tap-able for detail navigation

**PositionWidget**
- Shows open position overview
- Displays P&L with color coding (green/red)
- Current price and entry price
- Profit/loss percentage

**Shimmer**
- Loading state animation
- Used while fetching data
- Smooth placeholder effects

## 💻 Development Guidelines

### Code Style
- Follow Swift naming conventions (camelCase for variables/functions)
- Use meaningful variable names
- Document complex logic with comments
- Use Type-safe approaches (enums for state, structs for models)

### MVVM Best Practices
- **Views** should only contain UI logic
- **ViewModels** should handle business logic and state management
- **Models** should be simple data structures (Codable)
- Use `@ObservedObject`, `@StateObject`, and `@Published` appropriately

### State Management
- Use `@ObservedObject` for ViewModel references in Views
- Use `@Published` properties in ViewModels
- Use `@AppStorage` for persistent user preferences
- Keep state as local as possible

### API Integration
- Use `URLSession` for HTTP requests
- Implement proper error handling
- Support offline scenarios with cached data
- Use Codable for JSON serialization

### Example ViewModel Pattern
```swift
class SignalsViewModel: ObservableObject {
    @Published var signals: [Signal] = []
    @Published var isLoading = false
    @Published var error: Error?

    func fetchSignals() {
        isLoading = true
        // Fetch from API
        // Update @Published properties
        isLoading = false
    }
}
```

## 🔄 Data Flow Example

**User opens Signals tab:**
1. View appears → `SignalsView` init triggers
2. ViewModel fetches data → `SignalsViewModel.fetchSignals()`
3. API request → URLSession GET /api/signals
4. JSON decoded → `[Signal]` array

## 🚧 Future Enhancements

### Planned Features & TODOs

#### Signals Screen Redesign & Refactor
- [ ] Redesign the signals display with improved visual hierarchy
- [ ] Enhance signal cards with better styling and animations
- [ ] Add filtering options (by signal type, confidence, symbol)
- [ ] Add detailed signal info
- [ ] Add Symbol Screen with detailed symbol info (such as candle chart, metrics, order history, etc)
- [ ] Implement sorting capabilities (by confidence, recency, symbol)
- [ ] Add search functionality for specific symbols
- [ ] Improve metric visualization with icons and color coding
- [ ] Add swipe actions for quick signal interactions
- [ ] Optimize performance for large signal lists

#### Real-Time P&L Chart on Positions Screen
- [ ] Integrate charting library (Swift Charts or similar)
- [ ] Display live portfolio P&L over time
- [ ] Add time range selector (1H, 4H, 1D, 1W, 1M)
- [ ] Implement real-time price updates for chart data
- [ ] Add chart tooltips showing detailed P&L values
- [ ] Cache historical data for offline viewing
- [ ] Add performance statistics overlay on chart

### Future Roadmap
- [ ] Push notifications for trading signals
- [ ] Watchlist management
- [ ] Customizable alerts and thresholds
- [ ] Advanced analytics dashboard
- [ ] Export trade history (CSV, PDF)
- [ ] Multi-device sync with CloudKit
- [ ] Dark mode enhancements
- [ ] Accessibility improvements (VoiceOver support)
- [ ] iPad optimized layout
- [ ] Widget support for iOS home screen

## 📄 License

Sentio Lite is provided for educational purposes. See LICENSE file for details.

## 📞 Support

For issues, bugs, or feature requests, please open an issue in the repository.

---

**Last Updated:** November 2025
**Maintained by:** BeeJay
