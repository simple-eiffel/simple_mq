# S04-FEATURE-SPECS.md
## simple_mq - Feature Specifications

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## Feature Categories

### 1. Message Creation

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| new_message | SIMPLE_MQ | (payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE | Create message with auto-generated UUID |
| new_message_with_id | SIMPLE_MQ | (id, payload: READABLE_STRING_8): SIMPLE_MQ_MESSAGE | Create message with specific ID |
| make | SIMPLE_MQ_MESSAGE | (payload: READABLE_STRING_8) | Constructor with payload |
| make_with_id | SIMPLE_MQ_MESSAGE | (id, payload: READABLE_STRING_8) | Constructor with ID |

### 2. Queue Creation

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| new_queue | SIMPLE_MQ | (name: READABLE_STRING_8): SIMPLE_MQ_QUEUE | Create unbounded FIFO queue |
| new_queue_with_capacity | SIMPLE_MQ | (name: READABLE_STRING_8; max_size: INTEGER): SIMPLE_MQ_QUEUE | Create bounded queue |
| new_priority_queue | SIMPLE_MQ | (name: READABLE_STRING_8): SIMPLE_MQ_QUEUE | Create priority queue |
| new_redis_queue | SIMPLE_MQ | (name: READABLE_STRING_8; redis: SIMPLE_REDIS): SIMPLE_MQ_REDIS_QUEUE | Create Redis-backed queue |
| new_redis_queue_blocking | SIMPLE_MQ | (name, redis, timeout): SIMPLE_MQ_REDIS_QUEUE | Create blocking Redis queue |

### 3. Topic Creation

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| new_topic | SIMPLE_MQ | (name: READABLE_STRING_8): SIMPLE_MQ_TOPIC | Create pub/sub topic |
| new_topic_with_history | SIMPLE_MQ | (name: READABLE_STRING_8; history_size: INTEGER): SIMPLE_MQ_TOPIC | Create topic with history |

### 4. Queue Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| enqueue | SIMPLE_MQ_QUEUE | (message: SIMPLE_MQ_MESSAGE) | Add message to queue |
| enqueue_with_priority | SIMPLE_MQ_QUEUE | (message: SIMPLE_MQ_MESSAGE; priority: INTEGER) | Add with priority |
| dequeue | SIMPLE_MQ_QUEUE | : detachable SIMPLE_MQ_MESSAGE | Remove and return front message |
| dequeue_batch | SIMPLE_MQ_QUEUE | (count: INTEGER): ARRAYED_LIST [SIMPLE_MQ_MESSAGE] | Remove multiple messages |
| peek | SIMPLE_MQ_QUEUE | : detachable SIMPLE_MQ_MESSAGE | View front without removing |
| peek_all | SIMPLE_MQ_QUEUE | : ARRAYED_LIST [SIMPLE_MQ_MESSAGE] | View all messages |
| find_by_id | SIMPLE_MQ_QUEUE | (id: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE | Find by ID |
| remove_by_id | SIMPLE_MQ_QUEUE | (id: READABLE_STRING_8): BOOLEAN | Remove specific message |
| clear | SIMPLE_MQ_QUEUE | | Remove all messages |

### 5. Topic Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| subscribe | SIMPLE_MQ_TOPIC | (subscriber: SIMPLE_MQ_SUBSCRIBER) | Add subscriber |
| unsubscribe | SIMPLE_MQ_TOPIC | (subscriber: SIMPLE_MQ_SUBSCRIBER) | Remove subscriber |
| unsubscribe_all | SIMPLE_MQ_TOPIC | | Remove all subscribers |
| publish | SIMPLE_MQ_TOPIC | (message: SIMPLE_MQ_MESSAGE) | Broadcast to all subscribers |
| publish_payload | SIMPLE_MQ_TOPIC | (payload: READABLE_STRING_8) | Quick publish |
| get_history | SIMPLE_MQ_TOPIC | : ARRAYED_LIST [SIMPLE_MQ_MESSAGE] | Get message history |
| get_history_since | SIMPLE_MQ_TOPIC | (timestamp: INTEGER_64): ARRAYED_LIST | Get recent history |
| matches_pattern | SIMPLE_MQ_TOPIC | (pattern: READABLE_STRING_8): BOOLEAN | Wildcard matching |

### 6. Message Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| set_payload | SIMPLE_MQ_MESSAGE | (payload: READABLE_STRING_8) | Update payload |
| set_header | SIMPLE_MQ_MESSAGE | (key, value: READABLE_STRING_8) | Set metadata header |
| remove_header | SIMPLE_MQ_MESSAGE | (key: READABLE_STRING_8) | Remove header |
| set_priority | SIMPLE_MQ_MESSAGE | (priority: INTEGER) | Set message priority |
| set_timestamp | SIMPLE_MQ_MESSAGE | (timestamp: INTEGER_64) | Set timestamp |
| header | SIMPLE_MQ_MESSAGE | (key: READABLE_STRING_8): detachable STRING_8 | Get header value |
| has_header | SIMPLE_MQ_MESSAGE | (key: READABLE_STRING_8): BOOLEAN | Check header exists |
| to_json | SIMPLE_MQ_MESSAGE | : STRING_8 | Serialize to JSON |

### 7. Registry Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| register_queue | SIMPLE_MQ | (queue: SIMPLE_MQ_QUEUE) | Register for lookup |
| queue | SIMPLE_MQ | (name: READABLE_STRING_8): detachable SIMPLE_MQ_QUEUE | Get by name |
| register_topic | SIMPLE_MQ | (topic: SIMPLE_MQ_TOPIC) | Register for lookup |
| topic | SIMPLE_MQ | (name: READABLE_STRING_8): detachable SIMPLE_MQ_TOPIC | Get by name |
| topics_matching | SIMPLE_MQ | (pattern: READABLE_STRING_8): ARRAYED_LIST | Find by pattern |

### 8. Quick Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| send | SIMPLE_MQ | (queue_name, payload: READABLE_STRING_8) | Quick send to queue |
| publish | SIMPLE_MQ | (topic_name, payload: READABLE_STRING_8) | Quick publish to topic |
| receive | SIMPLE_MQ | (queue_name: READABLE_STRING_8): detachable SIMPLE_MQ_MESSAGE | Quick receive |

### 9. Status Queries

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| is_empty | SIMPLE_MQ_QUEUE | : BOOLEAN | Queue empty? |
| has_messages | SIMPLE_MQ_QUEUE | : BOOLEAN | Queue has messages? |
| is_full | SIMPLE_MQ_QUEUE | : BOOLEAN | Queue at capacity? |
| count | SIMPLE_MQ_QUEUE | : INTEGER | Message count |
| is_priority_queue | SIMPLE_MQ_QUEUE | : BOOLEAN | Priority mode? |
| has_subscribers | SIMPLE_MQ_TOPIC | : BOOLEAN | Topic has subscribers? |
| is_subscribed | SIMPLE_MQ_TOPIC | (subscriber): BOOLEAN | Subscriber registered? |
| subscriber_count | SIMPLE_MQ_TOPIC | : INTEGER | Subscriber count |

### 10. Statistics

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| total_enqueued | SIMPLE_MQ_QUEUE | : INTEGER_64 | Total ever enqueued |
| total_dequeued | SIMPLE_MQ_QUEUE | : INTEGER_64 | Total ever dequeued |
| total_published | SIMPLE_MQ_TOPIC | : INTEGER_64 | Total published |
| total_delivered | SIMPLE_MQ_TOPIC | : INTEGER_64 | Total deliveries |
| registered_queue_count | SIMPLE_MQ | : INTEGER | Registered queues |
| registered_topic_count | SIMPLE_MQ | : INTEGER | Registered topics |
