# S06-BOUNDARIES.md
## simple_mq - System Boundaries

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Scope Boundaries

### IN SCOPE

| Capability | Description |
|------------|-------------|
| In-memory queues | FIFO and priority queue implementation |
| Pub/Sub topics | Fan-out broadcast messaging |
| Message abstraction | Headers, priority, timestamps |
| Queue registry | Named queue/topic lookup |
| Wildcard matching | Pattern-based topic subscription |
| Message history | Configurable retention for topics |
| Redis integration | Distributed queue via simple_cache |

### OUT OF SCOPE

| Capability | Reason |
|------------|--------|
| Dead letter queue | Not implemented (future enhancement) |
| Message TTL | No automatic expiration |
| Acknowledgement mode | No explicit ack/nack |
| Consumer groups | No competing consumers for topics |
| Request/reply | No correlation ID handling |
| Delayed messages | No scheduled delivery |
| Message persistence | Use Redis for durability |
| Clustering | Single-process for in-memory queues |

## 2. Integration Boundaries

### INTERNAL DEPENDENCIES

```
simple_mq
    |
    +-- simple_cache (SIMPLE_REDIS for Redis queues)
    |
    +-- simple_uuid (Message ID generation)
    |
    +-- simple_datetime (Timestamp handling)
    |
    +-- simple_json (Message serialization)
```

### EXTERNAL INTERFACES

| Interface | Protocol | Notes |
|-----------|----------|-------|
| Redis | LPUSH/RPOP/BLPOP | Via simple_cache |
| JSON | RFC 8259 | Message serialization |

## 3. Error Boundaries

### Precondition Violations (Caller Errors)

| Error | Feature | Recovery |
|-------|---------|----------|
| Empty queue name | new_queue | Fix caller code |
| Empty topic name | new_topic | Fix caller code |
| Full queue | enqueue | Wait or check is_full |
| Already subscribed | subscribe | Check is_subscribed |
| Queue not registered | send/receive | Register first |

### Runtime Errors

| Error | Source | Recovery |
|-------|--------|----------|
| Redis connection failure | SIMPLE_MQ_REDIS_QUEUE | Check Redis availability |
| Out of memory | Large queues | Use bounded capacity |

## 4. Data Boundaries

### Message Size

| Attribute | Limit | Notes |
|-----------|-------|-------|
| Payload | STRING_8 capacity | Memory limited |
| Headers | HASH_TABLE capacity | Practical limit ~1000 |
| Message ID | UUID v4 | 36 characters |

### Queue Size

| Type | Limit | Notes |
|------|-------|-------|
| Unbounded | System memory | No explicit limit |
| Bounded | max_size | Configurable at creation |

### Topic History

| Attribute | Limit | Notes |
|-----------|-------|-------|
| History size | Configurable | Oldest removed at capacity |
| Subscriber count | HASH_TABLE capacity | Practical limit ~10,000 |

## 5. Behavioral Boundaries

### Delivery Guarantees

| Mode | Guarantee | Implementation |
|------|-----------|----------------|
| In-memory queue | At-most-once | No persistence |
| In-memory topic | Fire-and-forget | No offline delivery |
| Redis queue | At-least-once | Persistence via Redis |

### Ordering Guarantees

| Mode | Guarantee |
|------|-----------|
| FIFO queue | Strict FIFO |
| Priority queue | Priority then timestamp |
| Topic publish | No ordering guarantee between subscribers |

## 6. Extension Points

### Custom Subscribers

Implement SIMPLE_MQ_SUBSCRIBER:
```eiffel
class MY_SUBSCRIBER inherit SIMPLE_MQ_SUBSCRIBER
feature
    subscriber_id: STRING do Result := "my-subscriber" end
    on_message (msg: SIMPLE_MQ_MESSAGE) do ... end
end
```

### Custom Queue Backends

Create new queue implementation following SIMPLE_MQ_QUEUE interface pattern.

## 7. Version Boundaries

| Component | Version | Notes |
|-----------|---------|-------|
| EiffelStudio | 25.02+ | Required |
| Void Safety | All | Full void safety |
| SCOOP | Thread mode | Concurrency support |
