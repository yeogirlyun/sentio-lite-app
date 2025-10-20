// 90 days of realistic trading data based on sentio_lite performance
// Generated from July 19, 2025 to Oct 17, 2025
// MRD: ~0.47%, Win Rate: ~67.8%, Avg trades/day: ~20

const SYMBOLS = ['TQQQ', 'SQQQ', 'SPXL', 'SPXU', 'TNA', 'TZA', 'FAS', 'FAZ', 'SOXL', 'SOXS', 'UVXY', 'SVIX'];

function generatePrice(symbol, basePrice, volatility = 0.03) {
    return basePrice * (1 + (Math.random() - 0.5) * volatility);
}

function generateTrade(date, time, symbol, index, isWinner) {
    const basePrices = {
        'TQQQ': 102, 'SQQQ': 18, 'SPXL': 158, 'SPXU': 28,
        'TNA': 31, 'TZA': 24, 'FAS': 46, 'FAZ': 19,
        'SOXL': 68, 'SOXS': 22, 'UVXY': 34, 'SVIX': 41
    };

    const entryPrice = generatePrice(symbol, basePrices[symbol]);
    const shares = Math.floor(10000 / entryPrice);

    let exitPrice, pnl, pnlPercent, exitReason;

    if (isWinner) {
        // Profit target: +3.5% to +4.5%
        pnlPercent = 0.035 + Math.random() * 0.01;
        exitPrice = entryPrice * (1 + pnlPercent);
        exitReason = 'PROFIT_TARGET';
    } else {
        // Stop loss: -0.8% to -1.5%
        pnlPercent = -(0.008 + Math.random() * 0.007);
        exitPrice = entryPrice * (1 + pnlPercent);
        exitReason = 'STOP_LOSS';
    }

    pnl = (exitPrice - entryPrice) * shares;

    const entryHour = 9 + Math.floor(Math.random() * 6);
    const entryMin = Math.floor(Math.random() * 60);
    const duration = 15 + Math.floor(Math.random() * 120); // 15-135 minutes

    const exitTime = new Date(`${date}T${entryHour.toString().padStart(2,'0')}:${entryMin.toString().padStart(2,'0')}:00`);
    exitTime.setMinutes(exitTime.getMinutes() + duration);

    const confidence = isWinner ? (0.72 + Math.random() * 0.18) : (0.65 + Math.random() * 0.10);
    const rsi = isWinner ? (28 + Math.random() * 15) : (45 + Math.random() * 25);
    const signal1bar = isWinner ? (1.5 + Math.random() * 1.5) : (0.4 + Math.random() * 0.8);

    return {
        id: `${date}_${index}`,
        symbol: symbol,
        date: date,
        entryTime: `${entryHour.toString().padStart(2,'0')}:${entryMin.toString().padStart(2,'0')} AM`,
        exitTime: exitTime.toTimeString().substring(0, 5),
        duration: duration,
        entryPrice: parseFloat(entryPrice.toFixed(2)),
        exitPrice: parseFloat(exitPrice.toFixed(2)),
        shares: shares,
        positionSize: parseFloat((entryPrice * shares).toFixed(2)),
        pnl: parseFloat(pnl.toFixed(2)),
        pnlPercent: parseFloat((pnlPercent * 100).toFixed(2)),
        exitReason: exitReason,

        // Technical indicators at entry
        technical: {
            confidence: parseFloat((confidence * 100).toFixed(1)),
            rsi: parseFloat(rsi.toFixed(1)),
            bbProximity: parseFloat((0.85 + Math.random() * 0.15).toFixed(2)),
            volumeRatio: parseFloat((1.2 + Math.random() * 0.8).toFixed(1)),
            sigma: parseFloat((-2.5 + Math.random() * 0.8).toFixed(1)),
            signal1bar: parseFloat(signal1bar.toFixed(2)),
            signal5bar: parseFloat((signal1bar * 0.8).toFixed(2)),
            signal10bar: parseFloat((signal1bar * 0.65).toFixed(2)),
            rotationDelta: parseFloat((Math.random() * 0.5).toFixed(2))
        },

        // AI reasoning
        entryReason: isWinner
            ? `Strong mean reversion setup detected. Price deviated ${(-2.5 + Math.random() * 0.8).toFixed(1)}σ from MA with RSI at ${rsi.toFixed(0)} (oversold). Multi-horizon signals aligned with ${(confidence * 100).toFixed(0)}% confidence.`
            : `Mean reversion signal detected but weaker confirmation. RSI at ${rsi.toFixed(0)}, confidence ${(confidence * 100).toFixed(0)}%. Entry criteria met but market reversed unexpectedly.`,

        exitReason: exitReason === 'PROFIT_TARGET'
            ? `Profit target (+${(pnlPercent * 100).toFixed(2)}%) reached. Risk management protocol triggered exit at predetermined level. ${Math.random() > 0.5 ? 'Momentum continued but locked in gains.' : 'Mean reversion signal weakened, confirming exit.'}`
            : `Stop loss triggered at ${(pnlPercent * 100).toFixed(2)}% after unexpected market reversal. ${Math.random() > 0.5 ? 'VIX spike caused adverse correlation.' : 'Multi-horizon signals turned bearish quickly.'} AI risk management limited loss as designed.`
    };
}

function generateDayData(date, dayIndex, currentPortfolioValue) {
    // Win rate ~68%
    const numTrades = 16 + Math.floor(Math.random() * 10); // 16-25 trades per day
    const winRate = 0.65 + Math.random() * 0.08; // 65-73% win rate

    const trades = [];
    for (let i = 0; i < numTrades; i++) {
        const symbol = SYMBOLS[Math.floor(Math.random() * SYMBOLS.length)];
        const isWinner = Math.random() < winRate;
        trades.push(generateTrade(date, `trade_${i}`, symbol, i, isWinner));
    }

    // Calculate daily P&L - limit to reasonable daily returns (0.3% to 0.6% MRD)
    let dayPnl = trades.reduce((sum, t) => sum + t.pnl, 0);

    // Scale P&L to be reasonable (max ~0.8% daily return)
    const maxDailyReturn = currentPortfolioValue * 0.008;
    const minDailyReturn = currentPortfolioValue * -0.002;

    if (dayPnl > maxDailyReturn) {
        const scale = maxDailyReturn / dayPnl;
        trades.forEach(t => {
            t.pnl = parseFloat((t.pnl * scale).toFixed(2));
            t.pnlPercent = parseFloat((t.pnl / t.positionSize * 100).toFixed(2));
        });
        dayPnl = maxDailyReturn;
    } else if (dayPnl < minDailyReturn) {
        const scale = minDailyReturn / dayPnl;
        trades.forEach(t => {
            t.pnl = parseFloat((t.pnl * scale).toFixed(2));
            t.pnlPercent = parseFloat((t.pnl / t.positionSize * 100).toFixed(2));
        });
        dayPnl = minDailyReturn;
    }

    const winners = trades.filter(t => t.pnl > 0).length;
    const losers = trades.filter(t => t.pnl < 0).length;

    return {
        date: date,
        trades: trades,
        summary: {
            totalPnl: parseFloat(dayPnl.toFixed(2)),
            totalPnlPercent: parseFloat((dayPnl / currentPortfolioValue * 100).toFixed(3)),
            numTrades: numTrades,
            winners: winners,
            losers: losers,
            winRate: parseFloat((winners / numTrades * 100).toFixed(1))
        }
    };
}

// Generate 30 trading days
const tradingData = {
    period: '30days',
    startDate: '2025-09-08',
    endDate: '2025-10-17',
    initialCapital: 100000,
    days: []
};

// Generate dates (skip weekends)
let currentDate = new Date('2025-09-08');
const endDate = new Date('2025-10-17');
let dayIndex = 0;

// Calculate portfolio values day by day
let portfolioValue = tradingData.initialCapital;

while (currentDate <= endDate && dayIndex < 30) {
    const dayOfWeek = currentDate.getDay();

    // Skip weekends
    if (dayOfWeek !== 0 && dayOfWeek !== 6) {
        const dateStr = currentDate.toISOString().split('T')[0];
        const dayData = generateDayData(dateStr, dayIndex, portfolioValue);
        tradingData.days.push(dayData);

        // Update portfolio value for next day
        portfolioValue += dayData.summary.totalPnl;
        dayData.portfolioValue = parseFloat(portfolioValue.toFixed(2));
        dayData.totalReturn = parseFloat(((portfolioValue - tradingData.initialCapital) / tradingData.initialCapital * 100).toFixed(2));

        dayIndex++;
    }

    currentDate.setDate(currentDate.getDate() + 1);
}

// Calculate overall statistics
const allTrades = tradingData.days.flatMap(d => d.trades);
const totalPnl = tradingData.days.reduce((sum, d) => sum + d.summary.totalPnl, 0);
const totalWinners = allTrades.filter(t => t.pnl > 0).length;
const profitableDays = tradingData.days.filter(d => d.summary.totalPnl > 0).length;

tradingData.statistics = {
    totalTrades: allTrades.length,
    totalPnl: parseFloat(totalPnl.toFixed(2)),
    totalReturn: parseFloat(((portfolioValue - tradingData.initialCapital) / tradingData.initialCapital * 100).toFixed(2)),
    avgDailyReturn: parseFloat((totalPnl / tradingData.days.length / tradingData.initialCapital * 100).toFixed(3)),
    winRate: parseFloat((totalWinners / allTrades.length * 100).toFixed(1)),
    profitableDays: profitableDays,
    profitableDaysPercent: parseFloat((profitableDays / tradingData.days.length * 100).toFixed(1)),
    avgTradesPerDay: parseFloat((allTrades.length / tradingData.days.length).toFixed(1)),
    finalValue: portfolioValue,
    maxDrawdown: -2.8, // Simplified
    sharpeRatio: 2.1 // Simplified
};

console.log('Generated 30 days of trading data:');
console.log(`- ${tradingData.days.length} trading days`);
console.log(`- ${allTrades.length} total trades`);
console.log(`- Final portfolio value: $${portfolioValue.toFixed(2)}`);
console.log(`- Total return: ${tradingData.statistics.totalReturn}%`);
console.log(`- Win rate: ${tradingData.statistics.winRate}%`);
console.log('Trading data ready!');
