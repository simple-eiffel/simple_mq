# S02-CLASS-CATALOG.md
## simple_mq - Class Catalog

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

### CLASS: SIMPLE_MQ

**Role:** Main facade - factory for queues, topics, and messages

**Creation Procedures:**
- `make` - Initialize message queue facade

**Key Features:**
- Message Factory: `new_message`, `new_message_with_id`
- Queue Factory: `new_queue`, `new_queue_with_capacity`, `new_priority_queue`
- Topic Factory: `new_topic`, `new_topic_with_history`
- Redis Factory: `new_redis_queue`, `new_redis_queue_blocking`
- Registry: `register_queue`, `queue`, `register_topic`, `topic`, `topics_matching`
- Quick Operations: `send`, `publish`, `receive`

**Collaborators:** SIMPLE_MQ_QUEUE, SIMPLE_MQ_TOPIC, SIMPLE_MQ_MESSAGE, SIMPLE_MQ_REDIS_QUEUE

---

### CLASS: SIMPLE_MQ_MESSAGE

**Role:** Message container for queue operations

**Creation Procedures:**
- `make(payload)` - Create with auto-generated UUID
- `make_with_id(id, payload)` - Create with specific ID

**Key Features:**
- Access: `id`, `payload`, `headers`, `timestamp`, `priority`
- Header Access: `header`, `has_header`
- Modification: `set_payload`, `set_header`, `remove_header`, `set_priority`, `set_timestamp`
- Serialization: `to_json`
- Comparison: `is_higher_priority_than`, `is_older_than`

**Invariants:**
- `id_not_empty: not id.is_empty`
- `headers_attached: headers /= Void`

---

### CLASS: SIMPLE_MQ_QUEUE

**Role:** In-memory message queue with FIFO or priority ordering

**Creation Procedures:**
- `make(name)` - Unbounded FIFO queue
- `make_with_capacity(name, max_size)` - Bounded queue
- `make_priority(name)` - Priority queue

**Key Features:**
- Access: `name`, `max_size`, `is_priority_queue`, `count`
- Status: `is_empty`, `has_messages`, `is_full`
- Query: `peek`, `peek_all`, `find_by_id`, `has_message`
- Enqueue: `enqueue`, `enqueue_with_priority`
- Dequeue: `dequeue`, `dequeue_batch`
- Remove: `remove_by_id`, `clear`
- Statistics: `total_enqueued`, `total_dequeued`, `pending_count`

**Invariants:**
- `name_not_empty: not name.is_empty`
- `count_non_negative: count >= 0`
- `max_size_non_negative: max_size >= 0`

---

### CLASS: SIMPLE_MQ_TOPIC

**Role:** Pub/Sub topic for broadcast messaging

**Creation Procedures:**
- `make(name)` - Topic without history
- `make_with_history(name, history_size)` - Topic with message retention

**Key Features:**
- Access: `name`, `subscriber_count`, `history_size`
- Status: `has_subscribers`, `is_subscribed`
- Subscription: `subscribe`, `unsubscribe`, `unsubscribe_all`
- Publishing: `publish`, `publish_payload`
- History: `get_history`, `get_history_since`, `clear_history`
- Statistics: `total_published`, `total_delivered`
- Matching: `matches_pattern` (wildcards: * and #)

**Invariants:**
- `name_not_empty: not name.is_empty`
- `history_size_non_negative: history_size >= 0`

---

### CLASS: SIMPLE_MQ_SUBSCRIBER (Deferred)

**Role:** Subscriber interface for topic subscriptions

**Deferred Features:**
- `subscriber_id: STRING` - Unique identifier
- `on_message(message: SIMPLE_MQ_MESSAGE)` - Message handler

---

### CLASS: SIMPLE_MQ_REDIS_QUEUE

**Role:** Redis-backed distributed queue

**Creation Procedures:**
- `make(name, redis)` - Create with Redis connection
- `make_with_timeout(name, redis, timeout)` - Create with blocking timeout

**Key Features:**
- Access: `name`, `blocking_timeout`
- Queue Operations: `enqueue`, `dequeue`, `count`, `is_empty`

---

### CLASS: SIMPLE_MQ_QUICK

**Role:** Quick operations facade for common use cases

**Key Features:**
- Quick queue operations
- Quick pub/sub operations

---

### CLASS: SIMPLE_MQ_QUICK_SUBSCRIBER

**Role:** Helper class for quick subscription setup

**Inherits:** SIMPLE_MQ_SUBSCRIBER
