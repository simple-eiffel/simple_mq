# S01-PROJECT-INVENTORY.md
## simple_mq - Message Queue Library

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Source:** Implementation analysis + research/SIMPLE_MQ_RESEARCH.md

---

### 1. PROJECT IDENTITY

| Field | Value |
|-------|-------|
| Name | simple_mq |
| UUID | A1063162-20B4-495E-868B-2EB3D4CF2EAF |
| Description | Simple Message Queue - Redis Streams, pub/sub, async messaging patterns for Eiffel |
| Version | 1.0.0 |
| License | MIT License |
| Author | Larry Rix |

### 2. PURPOSE

Provides message queue functionality for Eiffel applications:
- In-memory queues for single-process use
- Redis-backed queues for distributed/persistent use
- Pub/Sub topics for broadcast messaging
- Priority queue support
- Message history for topics

### 3. DEPENDENCIES

| Library | Location | Purpose |
|---------|----------|---------|
| base | $ISE_LIBRARY/library/base/base.ecf | Core Eiffel types |
| simple_datetime | $SIMPLE_EIFFEL/simple_datetime/simple_datetime.ecf | Timestamp handling |
| simple_json | $SIMPLE_EIFFEL/simple_json/simple_json.ecf | Message serialization |
| simple_uuid | $SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf | Unique message IDs |
| simple_cache | $SIMPLE_EIFFEL/simple_cache/simple_cache.ecf | Redis integration |

### 4. FILE INVENTORY

| File | Class | Role |
|------|-------|------|
| src/simple_mq.e | SIMPLE_MQ | Main facade |
| src/simple_mq_message.e | SIMPLE_MQ_MESSAGE | Message container |
| src/simple_mq_queue.e | SIMPLE_MQ_QUEUE | In-memory FIFO queue |
| src/simple_mq_topic.e | SIMPLE_MQ_TOPIC | Pub/Sub topic |
| src/simple_mq_subscriber.e | SIMPLE_MQ_SUBSCRIBER | Subscriber interface |
| src/simple_mq_redis_queue.e | SIMPLE_MQ_REDIS_QUEUE | Redis-backed queue |
| src/simple_mq_quick.e | SIMPLE_MQ_QUICK | Quick operations facade |
| src/simple_mq_quick_subscriber.e | SIMPLE_MQ_QUICK_SUBSCRIBER | Quick subscriber helper |

### 5. BUILD TARGETS

| Target | Root Class | Purpose |
|--------|------------|---------|
| simple_mq | (library) | Main library target |
| simple_mq_tests | TEST_APP | Test suite |

### 6. CAPABILITIES

- Concurrency: SCOOP support (uses thread)
- Void Safety: Full (all)
- Assertions: Full (precondition, postcondition, check, invariant, loop, supplier_precondition)

### 7. RELATED RESEARCH

- research/SIMPLE_MQ_RESEARCH.md - 7-step research document covering AMQP, MQTT, STOMP standards
