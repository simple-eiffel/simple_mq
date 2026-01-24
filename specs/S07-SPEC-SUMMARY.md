# S07-SPEC-SUMMARY.md
## simple_mq - Specification Summary

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## Executive Summary

**simple_mq** is a message queue library for Eiffel providing:
- In-memory queues (FIFO and priority)
- Pub/Sub topics with wildcard matching
- Redis-backed distributed queues
- Full Design by Contract

## Quick Reference

### Create Message Queue
```eiffel
mq := create {SIMPLE_MQ}.make

-- Create queue
queue := mq.new_queue ("tasks")

-- Send message
msg := mq.new_message ("Hello, World!")
queue.enqueue (msg)

-- Receive message
if attached queue.dequeue as received then
    print (received.payload)
end
```

### Priority Queue
```eiffel
pq := mq.new_priority_queue ("jobs")
pq.enqueue_with_priority (urgent_msg, 10)  -- High priority
pq.enqueue_with_priority (normal_msg, 1)   -- Low priority
-- dequeue returns highest priority first
```

### Pub/Sub Topic
```eiffel
topic := mq.new_topic_with_history ("events.user", 100)
topic.subscribe (my_handler)
topic.publish (msg)  -- Delivered to all subscribers
```

### Wildcard Matching
```eiffel
-- * matches single level
topic.matches_pattern ("events.user.*")   -- matches events.user.created

-- # matches multiple levels
topic.matches_pattern ("events.#")        -- matches events.user.created.success
```

### Redis Queue (Distributed)
```eiffel
redis_queue := mq.new_redis_queue ("jobs", my_redis)
redis_queue.enqueue (msg)
-- Messages persist in Redis
```

## Class Summary

| Class | Purpose | Key Features |
|-------|---------|--------------|
| SIMPLE_MQ | Facade | Factory, registry, quick ops |
| SIMPLE_MQ_MESSAGE | Message | Payload, headers, priority |
| SIMPLE_MQ_QUEUE | Queue | FIFO, priority, bounded |
| SIMPLE_MQ_TOPIC | Pub/Sub | Subscribe, publish, history |
| SIMPLE_MQ_SUBSCRIBER | Interface | Deferred subscriber |
| SIMPLE_MQ_REDIS_QUEUE | Distributed | Redis-backed queue |

## Contract Highlights

| Contract | Feature | Rule |
|----------|---------|------|
| Precondition | enqueue | not is_full |
| Precondition | subscribe | not is_subscribed |
| Postcondition | enqueue | count = old count + 1 |
| Postcondition | dequeue | count = old count - 1 |
| Invariant | SIMPLE_MQ_MESSAGE | id_not_empty |
| Invariant | SIMPLE_MQ_QUEUE | count_non_negative |

## Key Design Decisions

1. **Simple API**: Send/receive in 2 lines of code
2. **Flexible Storage**: In-memory or Redis-backed
3. **Contract Safety**: Full DBC prevents invalid operations
4. **Complete Messaging**: Queue + Topic + Priority in one library
5. **SCOOP Ready**: Thread-safe for concurrent use

## Known Limitations

- No dead letter queue (failed messages not handled)
- No message TTL (manual expiration required)
- No acknowledgement mode (at-most-once for in-memory)
- No consumer groups for topics
- No delayed/scheduled messages

## Related Documents

- S01-PROJECT-INVENTORY.md - Project structure
- S02-CLASS-CATALOG.md - Class details
- S03-CONTRACTS.md - Full contract specifications
- S04-FEATURE-SPECS.md - Feature catalog
- S05-CONSTRAINTS.md - Design constraints
- S06-BOUNDARIES.md - Scope and limits
- S08-VALIDATION-REPORT.md - Test coverage
