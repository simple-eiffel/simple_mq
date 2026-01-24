# S05-CONSTRAINTS.md
## simple_mq - Design Constraints

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Naming Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Queue Name | SIMPLE_MQ_QUEUE | Must be non-empty string |
| Topic Name | SIMPLE_MQ_TOPIC | Must be non-empty string, supports dot notation |
| Message ID | SIMPLE_MQ_MESSAGE | Must be non-empty string, auto-generated UUID if not provided |
| Header Key | SIMPLE_MQ_MESSAGE | Must be non-empty string |
| Subscriber ID | SIMPLE_MQ_SUBSCRIBER | Must be unique within topic |

## 2. Capacity Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Queue Max Size | SIMPLE_MQ_QUEUE | 0 = unlimited, positive = bounded |
| History Size | SIMPLE_MQ_TOPIC | 0 = no history, positive = retain N messages |
| Batch Size | dequeue_batch | Must be positive integer |
| Blocking Timeout | SIMPLE_MQ_REDIS_QUEUE | Must be positive integer (seconds) |

## 3. State Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Cannot Enqueue When Full | SIMPLE_MQ_QUEUE | Precondition: not is_full |
| Cannot Subscribe Twice | SIMPLE_MQ_TOPIC | Precondition: not is_subscribed |
| Message Timestamp | SIMPLE_MQ_MESSAGE | Must be positive (Unix milliseconds) |
| Priority | SIMPLE_MQ_MESSAGE | Any integer, higher = more important |

## 4. Ordering Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| FIFO Queue | SIMPLE_MQ_QUEUE (default) | First in, first out |
| Priority Queue | SIMPLE_MQ_QUEUE (priority mode) | Highest priority first, ties by timestamp |
| Topic Fan-out | SIMPLE_MQ_TOPIC | All subscribers receive all messages |
| History Order | SIMPLE_MQ_TOPIC | Oldest first in get_history |

## 5. Pattern Matching Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Single-level Wildcard | matches_pattern | `*` matches exactly one segment |
| Multi-level Wildcard | matches_pattern | `#` matches zero or more segments |
| Topic Segment Separator | Topic names | Dot (`.`) separates levels |

**Examples:**
- `events.user.*` matches `events.user.created` but not `events.user.created.success`
- `events.#` matches `events.user.created.success`
- `events.*.created` matches `events.user.created`

## 6. Thread Safety Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| SCOOP Compatibility | All classes | Designed for SCOOP concurrency model |
| No Shared Mutable State | Subscribers | Each subscriber is independent |
| Redis Operations | SIMPLE_MQ_REDIS_QUEUE | Thread-safe via Redis atomic operations |

## 7. Serialization Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| JSON Escaping | to_json | Properly escapes quotes, backslashes, newlines |
| UTF-8 | Payload/Headers | STRING_8 used (ASCII/UTF-8 compatible) |
| Header Keys | SIMPLE_MQ_MESSAGE | Case-sensitive string keys |

## 8. Lifecycle Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Registration Required | send/receive/publish | Queue/Topic must be registered first |
| Subscriber Lifecycle | SIMPLE_MQ_TOPIC | Unsubscribe to stop receiving messages |
| History Cleanup | SIMPLE_MQ_TOPIC | Oldest removed when at capacity |

## 9. Redis Integration Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| Redis Connection | SIMPLE_MQ_REDIS_QUEUE | Requires valid SIMPLE_REDIS instance |
| Key Naming | SIMPLE_MQ_REDIS_QUEUE | Uses queue name as Redis key |
| Blocking Mode | SIMPLE_MQ_REDIS_QUEUE | Optional blocking dequeue with timeout |

## 10. Performance Constraints

| Constraint | Scope | Rule |
|------------|-------|------|
| In-Memory Only | SIMPLE_MQ_QUEUE | No persistence (use Redis for durability) |
| History Bounded | SIMPLE_MQ_TOPIC | Prevents unbounded memory growth |
| Statistics Overflow | total_enqueued/dequeued | INTEGER_64 for large counts |
