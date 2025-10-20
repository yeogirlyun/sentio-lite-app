# Sentio Lite App - Backend Architecture Options

## Requirements

**Core Needs:**
- Real-time data delivery (1-minute updates, synchronized with live trading)
- Display actual trade decisions as they happen (live transparency)
- Support up to 1M concurrent users
- **Zero interference** with production trading backend
- Reuse production data/technology for efficiency
- Owner can monitor real system through the app

---

## Option 1: Read Replica + WebSocket Fan-out Architecture

### Overview
Production trading system continues unchanged. App reads from dedicated replicas and uses WebSocket servers for real-time delivery.

### Architecture

```
[Live Trading System (C++)]
        ↓ (writes)
[Primary PostgreSQL/TimescaleDB] ─── async replication (lag: <100ms) ───→ [Read Replica Cluster]
        ↓                                                                           ↓
[Redis Pub/Sub]                                                         [API Gateway (Node.js/Go)]
        ↓                                                                           ↓
[WebSocket Server Cluster] ←──────────────────────────────────────────────────────┘
        ↓ (fan-out to clients)
[1M iOS Clients]
```

### Components

**1. Production Side (Unchanged)**
- `sentio_lite` C++ trading system writes to primary database
- Publishes trade events to Redis Pub/Sub channel `trades:live`
- No modifications needed - operates independently

**2. Data Layer**
- **Primary DB**: PostgreSQL with TimescaleDB extension (time-series optimization)
- **Read Replicas**: 3-5 async replicas (AWS RDS Read Replicas or similar)
- **Redis Cluster**: For pub/sub and real-time event streaming
- **Replication lag**: <100ms (typically 10-50ms)

**3. Application Tier**
- **API Gateway** (Node.js with Express or Go with Gin)
  - REST endpoints for historical data
  - `/api/v1/trades/history?date=2025-10-17`
  - `/api/v1/performance/daily`
  - `/api/v1/signals/current`
- **WebSocket Servers** (Node.js with Socket.IO or Go with Gorilla WebSocket)
  - Horizontal scaling with Redis adapter
  - Load balancer distributes connections
  - Each server handles 10K-50K connections

**4. Real-Time Flow**
```
Trading System → Redis Pub/Sub → WebSocket Server → iOS Client
                  (trade event)   (fan-out)        (update UI)
```

### Scaling Strategy

**For 1M Users:**
- 20-40 WebSocket servers (25K connections each)
- 5 read replicas (200K queries/sec total)
- AWS ALB/NLB for load balancing
- Auto-scaling based on connection count

### Pros
✅ **Complete isolation** - read replicas can't impact trading
✅ Proven architecture - used by financial services
✅ Easy to monitor and debug
✅ Owner sees exact same data as users
✅ Low latency (100-200ms end-to-end)

### Cons
❌ Requires managing WebSocket server fleet
❌ Database replication lag (though minimal)
❌ Moderate operational complexity

### Estimated Cost (AWS)
- Read replicas (5x db.r6g.2xlarge): $2,500/mo
- WebSocket servers (40x t3.large): $2,400/mo
- Redis cluster (r6g.xlarge): $300/mo
- Load balancers: $200/mo
- **Total: ~$5,400/month**

---

## Option 2: Event Streaming Architecture (Kafka/Kinesis)

### Overview
Trading system publishes events to distributed log. Multiple consumers read without impacting production. Inherently scalable and decoupled.

### Architecture

```
[Live Trading System (C++)]
        ↓ (publishes events)
[Kafka/Kinesis Stream] ───────┬────→ [Consumer 1: Database Writer]
  (topics: trades, signals)   │
                               ├────→ [Consumer 2: WebSocket Gateway]
                               │              ↓
                               └────→ [Consumer 3: Analytics/Aggregation]
                                              ↓
                                      [WebSocket Clients]
                                        (1M iOS users)
```

### Components

**1. Event Stream (Kafka or AWS Kinesis)**
- **Topics:**
  - `sentio.trades.executed` - Trade confirmations
  - `sentio.signals.generated` - AI signal decisions
  - `sentio.positions.updated` - Position changes
  - `sentio.performance.minute` - Per-minute performance
- **Retention**: 7 days (for replay/debugging)
- **Partitions**: 50+ (for parallelism)

**2. Trading System Integration**
```cpp
// Minimal change to sentio_lite
void MultiSymbolTrader::executeTradeWithPublish(Trade trade) {
    // Existing trade execution
    executeTrade(trade);

    // Publish to Kafka (async, non-blocking)
    kafka_producer.publish("sentio.trades.executed", trade.toJSON());
}
```

**3. Consumer Services**

**A. Database Writer Consumer**
- Writes events to PostgreSQL/TimescaleDB
- Materializes views for historical queries
- Batches writes for efficiency

**B. WebSocket Gateway Consumer**
- Subscribes to real-time streams
- Maintains WebSocket connections
- Fans out events to connected clients
- Uses Redis for connection state

**C. Aggregation Consumer**
- Pre-computes daily/weekly/monthly stats
- Updates materialized views
- Reduces query load

**4. Client Connection Flow**
```
iOS App → WebSocket → Gateway → Kafka Consumer → Live Event Stream
iOS App → REST API → PostgreSQL ← Database Writer ← Kafka
```

### Scaling Strategy

**For 1M Users:**
- Kafka cluster: 5 brokers (handles 100K+ msgs/sec)
- WebSocket gateway: 30-50 instances (20K connections each)
- Database writers: 3-5 instances (parallel writes)
- Consumer groups for horizontal scaling

### Pros
✅ **Perfect isolation** - consumers can't affect producers
✅ Event replay capability (debugging, new features)
✅ Easy to add new consumers (analytics, monitoring)
✅ Extremely scalable (millions of events/sec)
✅ Built-in durability and ordering guarantees
✅ Owner can subscribe to same streams

### Cons
❌ More complex initial setup
❌ Need Kafka expertise (or managed service cost)
❌ Additional infrastructure to manage

### Estimated Cost (AWS)

**Option A: Self-Managed Kafka**
- Kafka cluster (5x r6g.xlarge): $1,500/mo
- WebSocket gateways (40x t3.large): $2,400/mo
- PostgreSQL (db.r6g.xlarge): $800/mo
- **Total: ~$4,700/month**

**Option B: AWS Kinesis**
- Kinesis streams (50 shards): $2,500/mo
- Lambda consumers: $500/mo
- WebSocket (API Gateway): $1,000/mo
- DynamoDB: $400/mo
- **Total: ~$4,400/month**

---

## Option 3: Serverless with Edge Caching

### Overview
Minimize infrastructure management. Use managed services for scaling. CDN edge caching for global distribution and reduced load.

### Architecture

```
[Live Trading System (C++)]
        ↓ (writes)
[DynamoDB / Aurora Serverless] ←──── replication ───→ [DynamoDB Global Tables]
        ↓                                                      ↓
[EventBridge / SNS]                                    [CloudFront CDN]
        ↓                                                      ↓
[Lambda Functions] ──────────────────────────────────→ [Edge Locations]
        ↓                                                      ↓
[AWS AppSync / Pusher]                                 [iOS Clients Worldwide]
   (GraphQL + WebSocket)
```

### Components

**1. Data Storage**
- **DynamoDB**: Primary store for trades, signals, performance
  - Single-digit millisecond latency
  - Auto-scaling to millions of requests
  - Global tables for multi-region replication
- **Aurora Serverless v2**: For complex queries (analytics)
  - Scales from 0.5 to 128 ACUs automatically

**2. Real-Time Updates**
- **AWS AppSync** (Managed GraphQL + WebSocket)
  - Automatic scaling to millions of connections
  - Built-in subscriptions for real-time
  - $0.08 per million messages
- **Alternative: Pusher Channels**
  - Dedicated real-time messaging
  - Up to 1M concurrent connections
  - $499/mo for 1M connections

**3. Trading System Integration**
```cpp
// Write to DynamoDB via AWS SDK
void MultiSymbolTrader::recordTrade(Trade trade) {
    // Local execution (unchanged)
    executeTrade(trade);

    // Async write to DynamoDB (non-blocking)
    dynamodb_client.putItemAsync("sentio_trades", trade.toItem());

    // Trigger real-time notification
    eventbridge.publishEvent("trade.executed", trade.id);
}
```

**4. Edge Caching Strategy**
```
Request: Get daily performance for Oct 17
    ↓
CloudFront Edge (cached 10 seconds)
    ↓ (cache miss)
Lambda@Edge (compute aggregation)
    ↓
DynamoDB (fetch trades)
    ↓
Return + cache at edge for 10s
```

**5. Client Flow**
```
iOS App → AppSync GraphQL → DynamoDB → Live Data
iOS App → AppSync Subscription → Lambda → Real-time Push
iOS App → CloudFront → Edge Cache → Aggregated Data (10s stale max)
```

### Scaling Strategy

**For 1M Users:**
- AppSync: Auto-scales (no limit)
- Lambda: 1000 concurrent executions (auto-scales)
- DynamoDB: On-demand pricing (auto-scales)
- CloudFront: Global edge network (auto-scales)

**Cost Model: Pay-per-use**
- No servers to provision
- Scales to zero when idle
- Scales to millions automatically

### Pros
✅ **Zero infrastructure management**
✅ Automatic scaling (0 to millions)
✅ Global edge distribution (low latency worldwide)
✅ No servers to maintain
✅ Pay only for what you use
✅ Built-in high availability

### Cons
❌ Vendor lock-in (AWS/managed services)
❌ Cold start latency for Lambda (100-500ms)
❌ Less control over infrastructure
❌ Harder to debug at scale

### Estimated Cost (AWS)

**Active Usage (1M users, 100K trades/day):**
- AppSync (1M connections, 100M messages): $8,000/mo
- Lambda (10M invocations/day): $400/mo
- DynamoDB (on-demand): $1,500/mo
- CloudFront: $500/mo
- **Total: ~$10,400/month**

**Alternative with Pusher:**
- Pusher (1M connections): $499/mo
- Lambda: $400/mo
- DynamoDB: $1,500/mo
- CloudFront: $500/mo
- **Total: ~$2,900/month** (much cheaper!)

---

## Comparison Matrix

| Criteria | Option 1: Read Replica | Option 2: Kafka Streaming | Option 3: Serverless |
|----------|----------------------|--------------------------|---------------------|
| **Isolation from Trading** | ✅ Excellent (read replicas) | ✅✅ Perfect (pub/sub) | ✅ Excellent (separate service) |
| **Real-time Latency** | 100-200ms | 50-100ms | 150-300ms |
| **Scalability** | Good (1M) | Excellent (10M+) | Excellent (unlimited) |
| **Operational Complexity** | Medium | High | Low |
| **Infrastructure Cost** | $5,400/mo | $4,400/mo | $2,900/mo (Pusher) |
| **Reliability** | High (99.9%) | Very High (99.95%) | Very High (99.99%) |
| **Event Replay** | ❌ No | ✅ Yes (7 days) | Limited |
| **Owner Monitoring** | ✅ Same data | ✅✅ Same stream | ✅ Same data |
| **Development Speed** | Fast | Medium | Fast |
| **Vendor Lock-in** | Minimal | Minimal | High (AWS) |

---

## Recommended Approach

### **Phase 1 (MVP - First 3 months): Option 3 with Pusher**

**Why:**
- Fastest time to market
- Lowest initial cost ($2,900/mo)
- No infrastructure to manage
- Validate product-market fit

**Implementation:**
```
Trading System → DynamoDB → Pusher → iOS App
                    ↓
              Lambda aggregations → CloudFront cache
```

### **Phase 2 (Scale - After product validation): Migrate to Option 2**

**Why:**
- More control and lower long-term cost
- Better performance at scale
- Event replay for features/debugging
- Can handle 10M+ users if needed

**Migration Path:**
1. Add Kafka producer to trading system (alongside DynamoDB writes)
2. Run both systems in parallel
3. Migrate clients incrementally
4. Deprecate Pusher once fully migrated

---

## Implementation Priority

### Week 1-2: Core Infrastructure
- [ ] Set up DynamoDB tables
- [ ] Integrate trading system with DynamoDB (async writes)
- [ ] Set up Pusher account and channels
- [ ] Create Lambda functions for aggregations

### Week 3-4: Real-Time Delivery
- [ ] Implement DynamoDB Streams → Lambda → Pusher pipeline
- [ ] Test latency (target: <200ms end-to-end)
- [ ] Set up CloudFront distribution
- [ ] Implement edge caching for historical data

### Week 5-6: iOS Integration
- [ ] iOS app connects to Pusher
- [ ] Subscribe to real-time channels
- [ ] Implement reconnection logic
- [ ] Add offline caching

### Week 7-8: Testing & Monitoring
- [ ] Load test with 10K, 100K, 1M connections
- [ ] Set up CloudWatch dashboards
- [ ] Implement error tracking (Sentry)
- [ ] Create admin dashboard for owner monitoring

---

## Data Flow Example

**Real Trade Execution Flow:**

```
1. [09:31:45] Trading system executes TQQQ buy at $102.45
   ├─→ Local execution completes (20ms)
   └─→ DynamoDB write triggered (async)

2. [09:31:45.050] DynamoDB write completes
   └─→ DynamoDB Stream triggers Lambda

3. [09:31:45.100] Lambda processes event
   ├─→ Publishes to Pusher channel "trades"
   └─→ Updates aggregated stats in cache

4. [09:31:45.150] Pusher fans out to 1M connected clients
   └─→ All iOS apps receive update within 50ms

5. [09:31:45.200] iOS app updates UI
   └─→ User sees: "TQQQ BOUGHT at $102.45" with 200ms total latency
```

**User Experience:**
- User opens app → Sees current positions (from CloudFront cache, <50ms)
- AI makes trade decision → User's phone buzzes (push notification)
- Trade appears in app feed within 200ms
- Owner monitoring on their own app sees same update simultaneously

---

## Security Considerations

1. **API Authentication**: JWT tokens with 1-hour expiry
2. **Rate Limiting**: 100 requests/minute per user
3. **Data Encryption**: TLS 1.3 for all connections
4. **Read-Only Access**: App users can only read, never write
5. **Owner Access**: Separate admin API with write permissions (for monitoring/controls)

---

## Monitoring Dashboard (For Owner)

**Real-Time Metrics:**
- Current system performance vs app display (verify accuracy)
- Number of connected users
- Real-time trade execution feed
- Latency metrics (trading system → user phones)
- Error rates and system health

**Built with:**
- CloudWatch for infrastructure metrics
- Custom dashboard showing live trading + user analytics
- Alerts if app data diverges from trading system data

---

**Summary:** Start with Option 3 (Pusher + Serverless) for speed and low cost. Migrate to Option 2 (Kafka) when scaling beyond 1M users or need advanced features. This gives fastest time-to-market while maintaining path to scale.
